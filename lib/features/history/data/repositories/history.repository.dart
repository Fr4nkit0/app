import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

abstract class HistoryRepository {
  /// Every record in the local sync queue, newest first.
  Stream<List<HistoryEntry>> watchHistory();
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
        description: detail.description ?? _describe(entity, action),
        status: PendingStatus.fromWire(row.status),
        rejectionReason: row.rejectionReason,
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
        PendingEntity.sale => await _sales(ids),
        PendingEntity.payment => await _payments(ids),
        PendingEntity.customerAgreement => await _agreements(ids),
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
    PendingEntity.sale => HistoryEntryType.sale,
    PendingEntity.payment => HistoryEntryType.payment,
    PendingEntity.customerAgreement => HistoryEntryType.agreement,
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
