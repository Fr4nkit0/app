import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/history/domain/models/customer_record.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/data/database/record_status.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

abstract class HistoryRepository {
  /// Every record in the local sync queue, newest first.
  Stream<List<HistoryEntry>> watchHistory();

  /// Every visit, sale, payment and container movement of [customerId]
  /// stored on the device, newest first.
  Stream<List<CustomerRecord>> watchCustomerRecords(String customerId);
}

/// Builds the history from the sync queue: each queued change is one record
/// of the driver, and its status is the one the sync engine left on it.
class DriftHistoryRepository implements HistoryRepository {
  DriftHistoryRepository(this._db);

  final AppDatabase _db;

  static const _unknownCustomer = 'Cliente desconocido';

  @override
  Stream<List<HistoryEntry>> watchHistory() {
    final query = _db.select(_db.pendingChangeTable)
      ..orderBy([(t) => OrderingTerm.desc(t.pendingChangeId)]);
    return query.watch().asyncMap(_toEntries);
  }

  /// Reads the record tables themselves, not the sync queue, so records the
  /// bootstrap or a pull stored (with no pending change) are listed too.
  @override
  Stream<List<CustomerRecord>> watchCustomerRecords(String customerId) async* {
    yield await _customerRecords(customerId);
    await for (final _ in _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.visitTable,
        _db.saleTable,
        _db.saleItemTable,
        _db.paymentTable,
        _db.containerMovementTable,
      ]),
    )) {
      yield await _customerRecords(customerId);
    }
  }

  Future<List<CustomerRecord>> _customerRecords(String customerId) async {
    final records = [
      ...await _customerVisits(customerId),
      ...await _customerSales(customerId),
      ...await _customerPayments(customerId),
      ...await _customerMovements(customerId),
    ];
    return records..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<CustomerRecord>> _customerVisits(String customerId) async {
    final query = _db.select(_db.visitTable).join([
      leftOuterJoin(
        _db.visitOutcomeTable,
        _db.visitOutcomeTable.id.equalsExp(_db.visitTable.outcomeId),
      ),
    ])..where(_db.visitTable.customerId.equals(customerId));
    return query.map((row) {
      final visit = row.readTable(_db.visitTable);
      return CustomerRecord(
        id: visit.visitId,
        type: CustomerRecordType.visit,
        date: visit.arrived_at,
        outcomeName: row.readTableOrNull(_db.visitOutcomeTable)?.name,
        observations: _nonBlank(visit.observations),
      );
    }).get();
  }

  Future<List<CustomerRecord>> _customerSales(String customerId) async {
    final sales = await (_db.select(
      _db.saleTable,
    )..where((t) => t.customerId.equals(customerId))).get();
    final itemsQuery = _db.select(_db.saleItemTable).join([
      innerJoin(
        _db.productTable,
        _db.productTable.productId.equalsExp(_db.saleItemTable.productId),
      ),
    ])..where(_db.saleItemTable.saleId.isIn(sales.map((s) => s.saleId)));
    final itemsBySale = <String, List<CustomerRecordItem>>{};
    for (final row in await itemsQuery.get()) {
      final item = row.readTable(_db.saleItemTable);
      itemsBySale
          .putIfAbsent(item.saleId, () => [])
          .add(
            CustomerRecordItem(
              productName: row.readTable(_db.productTable).name,
              quantity: item.quantity,
            ),
          );
    }
    return [
      for (final sale in sales)
        CustomerRecord(
          id: sale.saleId,
          type: CustomerRecordType.sale,
          date: sale.saleDate,
          amount: sale.totalAmount,
          isCancelled: sale.status == RecordStatus.cancelled,
          saleMethod: PaymentMethod.values.firstWhere(
            (m) => m.name == sale.paymentMethod,
            orElse: () => PaymentMethod.cash,
          ),
          saleItems: itemsBySale[sale.saleId] ?? const [],
        ),
    ];
  }

  Future<List<CustomerRecord>> _customerPayments(String customerId) async {
    final payments = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.customerId.equals(customerId))).get();
    return [
      for (final payment in payments)
        CustomerRecord(
          id: payment.paymentId,
          type: CustomerRecordType.payment,
          date: payment.createdAt,
          amount: payment.amount,
          isCancelled: payment.status == RecordStatus.cancelled,
          paymentType: PaymentType.fromDb(payment.paymentMethod),
          observations: _nonBlank(payment.notes),
        ),
    ];
  }

  /// A reversal only undoes another movement, so it is not listed; the
  /// movement of a cancelled sale is listed as cancelled instead.
  Future<List<CustomerRecord>> _customerMovements(String customerId) async {
    final query =
        _db.select(_db.containerMovementTable).join([
          leftOuterJoin(
            _db.saleTable,
            _db.saleTable.saleId.equalsExp(_db.containerMovementTable.saleId),
          ),
        ])..where(
          _db.containerMovementTable.customerId.equals(customerId) &
              _db.containerMovementTable.reversesMovementId.isNull(),
        );
    return query.map((row) {
      final movement = row.readTable(_db.containerMovementTable);
      return CustomerRecord(
        id: movement.containerMovementId,
        type: CustomerRecordType.containerMovement,
        date: movement.createdAt,
        isCancelled:
            row.readTableOrNull(_db.saleTable)?.status ==
            RecordStatus.cancelled,
        containerType: movement.containerType,
        deliveredQuantity: movement.deliveredQuantity,
        returnedQuantity: movement.returnedQuantity,
      );
    }).get();
  }

  Future<List<HistoryEntry>> _toEntries(
    List<PendingChangeTableData> rows,
  ) async {
    final idsByEntity = <PendingEntity, Set<String>>{};
    for (final row in rows) {
      idsByEntity
          .putIfAbsent(PendingEntity.fromWire(row.entity), () => {})
          .add(row.entityId);
    }
    final details = await _loadDetails(idsByEntity);
    // Closing a visit also queues a stop update; the visit row already says
    // what happened at that stop.
    final visitedStops = {
      for (final id in idsByEntity[PendingEntity.visit] ?? const <String>{})
        ?details[_key(PendingEntity.visit, id)]?.routeStopId,
    };
    final names = await _customerNames({
      ...details.values.map((d) => d.customerId).whereType<String>(),
      ...?idsByEntity[PendingEntity.customer],
    });

    final shown = rows.where(
      (row) =>
          !(row.entity == PendingEntity.routeStop.wireName &&
              row.action == PendingAction.update.wireName &&
              visitedStops.contains(row.entityId)),
    );
    return shown.map((row) {
      final entity = PendingEntity.fromWire(row.entity);
      final action = PendingAction.fromWire(row.action);
      final payload = row.payload == null
          ? null
          : jsonDecode(row.payload!) as Map<String, dynamic>;
      final refused = payload?[PendingChange.rejectedValuesKey];
      final fields = payload?[PendingChange.changedFieldsKey];
      final detail = entity == PendingEntity.customer
          ? _Detail(customerId: row.entityId)
          : details[_key(entity, row.entityId)] ?? const _Detail();
      return HistoryEntry(
        id: row.pendingChangeId,
        type: _typeOf(entity),
        customerId: detail.customerId,
        customerName: names[detail.customerId] ?? _unknownCustomer,
        date: row.createdAt,
        amount: detail.amount,
        description: switch (entity) {
          // The record's own detail describes the record, not its
          // cancellation.
          PendingEntity.saleCancellation ||
          PendingEntity.paymentCancellation => _describe(entity, action),
          PendingEntity.customerAddress || PendingEntity.customerPreference =>
            _describeToggle(entity, action, row),
          _ => detail.description ?? _describe(entity, action),
        },
        status: PendingStatus.fromWire(row.status),
        rejectionReason: row.rejectionReason,
        rejectedValues: refused is Map<String, dynamic> ? refused : null,
        rollback: RejectionRollback.fromWire(
          payload?[PendingChange.rollbackKey],
        ),
        changedFields: fields is List ? fields.cast<String>() : null,
      );
    }).toList();
  }

  Future<Map<String, _Detail>> _loadDetails(
    Map<PendingEntity, Set<String>> idsByEntity,
  ) async {
    final details = <String, _Detail>{};
    for (final MapEntry(key: entity, value: ids) in idsByEntity.entries) {
      final found = switch (entity) {
        PendingEntity.customer => const <String, _Detail>{},
        PendingEntity.routeStop => await _routeStops(ids),
        PendingEntity.visit => await _visits(ids),
        PendingEntity.containerMovement => await _containerMovements(ids),
        PendingEntity.sale ||
        PendingEntity.saleCancellation => await _sales(ids),
        PendingEntity.payment ||
        PendingEntity.paymentCancellation => await _payments(ids),
        PendingEntity.customerAgreement => await _agreements(ids),
        PendingEntity.customerAddress => await _addresses(ids),
        PendingEntity.customerPreference => await _preferences(ids),
      };
      for (final MapEntry(:key, :value) in found.entries) {
        details[_key(entity, key)] = value;
      }
    }
    return details;
  }

  Future<Map<String, _Detail>> _routeStops(Set<String> ids) async {
    final rows = await (_db.select(
      _db.routeStopTable,
    )..where((t) => t.routeStopId.isIn(ids))).get();
    return {
      for (final r in rows) r.routeStopId: _Detail(customerId: r.customerId),
    };
  }

  Future<Map<String, _Detail>> _visits(Set<String> ids) async {
    final query = _db.select(_db.visitTable).join([
      leftOuterJoin(
        _db.visitOutcomeTable,
        _db.visitOutcomeTable.id.equalsExp(_db.visitTable.outcomeId),
      ),
    ])..where(_db.visitTable.visitId.isIn(ids));
    final details = <String, _Detail>{};
    for (final row in await query.get()) {
      final visit = row.readTable(_db.visitTable);
      details[visit.visitId] = _Detail(
        customerId: visit.customerId,
        routeStopId: visit.routeStopId,
        description: _joinNonBlank([
          row.readTableOrNull(_db.visitOutcomeTable)?.name,
          visit.observations,
        ]),
      );
    }
    return details;
  }

  Future<Map<String, _Detail>> _containerMovements(Set<String> ids) async {
    final rows = await (_db.select(
      _db.containerMovementTable,
    )..where((t) => t.containerMovementId.isIn(ids))).get();
    return {
      for (final r in rows)
        r.containerMovementId: _Detail(
          customerId: r.customerId,
          description:
              'Entregó ${r.deliveredQuantity} · Devolvió ${r.returnedQuantity}',
        ),
    };
  }

  Future<Map<String, _Detail>> _sales(Set<String> ids) async {
    final rows = await (_db.select(
      _db.saleTable,
    )..where((t) => t.saleId.isIn(ids))).get();
    return {
      for (final r in rows)
        r.saleId: _Detail(
          customerId: r.customerId,
          amount: r.totalAmount,
          description: r.paymentMethod == PaymentMethod.credit.name
              ? 'Venta a crédito'
              : null,
        ),
    };
  }

  Future<Map<String, _Detail>> _payments(Set<String> ids) async {
    final rows = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.paymentId.isIn(ids))).get();
    return {
      for (final r in rows)
        r.paymentId: _Detail(
          customerId: r.customerId,
          amount: r.amount,
          description: _nonBlank(r.notes),
        ),
    };
  }

  Future<Map<String, _Detail>> _agreements(Set<String> ids) async {
    final rows = await (_db.select(
      _db.customerAgreementTable,
    )..where((t) => t.agreementId.isIn(ids))).get();
    return {
      for (final r in rows)
        r.agreementId: _Detail(customerId: r.customerId, amount: r.unitPrice),
    };
  }

  Future<Map<String, _Detail>> _addresses(Set<String> ids) async {
    final rows = await (_db.select(
      _db.customerAddressTable,
    )..where((t) => t.addressId.isIn(ids))).get();
    return {
      for (final r in rows) r.addressId: _Detail(customerId: r.customerId),
    };
  }

  Future<Map<String, _Detail>> _preferences(Set<String> ids) async {
    final rows = await (_db.select(
      _db.customerPreferenceTable,
    )..where((t) => t.customerPreferenceId.isIn(ids))).get();
    return {
      for (final r in rows)
        r.customerPreferenceId: _Detail(customerId: r.customerId),
    };
  }

  /// A disable is an update whose payload turns the address or preference
  /// off.
  static String _describeToggle(
    PendingEntity entity,
    PendingAction action,
    PendingChangeTableData row,
  ) {
    final payload = row.payload == null ? null : jsonDecode(row.payload!);
    if (payload is Map && payload['enabled'] == false) {
      return entity == PendingEntity.customerPreference
          ? 'Preferencia desactivada'
          : 'Dirección desactivada';
    }
    return _describe(entity, action);
  }

  Future<Map<String, String>> _customerNames(Set<String> ids) async {
    if (ids.isEmpty) return const {};
    final rows = await (_db.select(
      _db.customerTable,
    )..where((t) => t.customerId.isIn(ids))).get();
    return {for (final r in rows) r.customerId: r.name};
  }

  static String _key(PendingEntity entity, String id) =>
      '${entity.wireName}:$id';

  static String? _nonBlank(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  static String? _joinNonBlank(List<String?> values) {
    final parts = values.map(_nonBlank).whereType<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static HistoryEntryType _typeOf(PendingEntity entity) => switch (entity) {
    PendingEntity.customer => HistoryEntryType.customer,
    PendingEntity.routeStop => HistoryEntryType.routeStop,
    PendingEntity.visit => HistoryEntryType.visit,
    PendingEntity.containerMovement => HistoryEntryType.delivery,
    PendingEntity.sale ||
    PendingEntity.saleCancellation => HistoryEntryType.sale,
    PendingEntity.payment ||
    PendingEntity.paymentCancellation => HistoryEntryType.payment,
    PendingEntity.customerAgreement => HistoryEntryType.agreement,
    PendingEntity.customerAddress ||
    PendingEntity.customerPreference => HistoryEntryType.customer,
  };

  static String _describe(PendingEntity entity, PendingAction action) =>
      switch ((entity, action)) {
        (PendingEntity.customer, PendingAction.insert) => 'Cliente nuevo',
        (PendingEntity.customer, PendingAction.update) => 'Cliente editado',
        (PendingEntity.customer, PendingAction.delete) => 'Cliente eliminado',
        (PendingEntity.routeStop, PendingAction.insert) =>
          'Parada reprogramada',
        (PendingEntity.routeStop, _) => 'Parada actualizada',
        (PendingEntity.visit, _) => 'Visita registrada',
        (PendingEntity.containerMovement, _) => 'Movimiento de envases',
        (PendingEntity.sale, _) => 'Venta registrada',
        (PendingEntity.payment, _) => 'Cobro registrado',
        (PendingEntity.customerAgreement, _) => 'Acuerdo de precio creado',
        (PendingEntity.saleCancellation, _) => 'Venta anulada',
        (PendingEntity.paymentCancellation, _) => 'Cobro anulado',
        (PendingEntity.customerAddress, PendingAction.insert) =>
          'Dirección agregada',
        (PendingEntity.customerAddress, _) => 'Dirección actualizada',
        (PendingEntity.customerPreference, PendingAction.insert) =>
          'Preferencia agregada',
        (PendingEntity.customerPreference, _) => 'Preferencia actualizada',
      };
}

class _Detail {
  const _Detail({
    this.customerId,
    this.routeStopId,
    this.amount,
    this.description,
  });

  final String? customerId;

  /// Stop a visit was made at; only set for visits.
  final String? routeStopId;
  final double? amount;
  final String? description;
}
