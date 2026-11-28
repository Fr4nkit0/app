import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/agreement_terms.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/data/repositories/server_shadow.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Each write stamps `last_modified_date` and queues one
/// `customer_agreement` change; the push rebuilds the record from the stored
/// row. An edit of a synced agreement first keeps the server's values of the
/// row ([ServerShadow]) for a rollback.
class DriftCustomerAgreementRepository implements CustomerAgreementRepository {
  DriftCustomerAgreementRepository(this.db, {DateTime Function()? now})
    : _queue = DriftPendingChangeRepository(db),
      _shadow = ServerShadow(db),
      _now = now ?? DateTime.now;

  final AppDatabase db;
  final PendingChangeRepository _queue;
  final ServerShadow _shadow;
  final DateTime Function() _now;

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static const _statusOrder = {
    AgreementStatus.inForce: 0,
    AgreementStatus.future: 1,
    AgreementStatus.ended: 2,
  };

  @override
  Stream<List<CustomerAgreement>> watchForCustomer(
    String customerId, {
    DateTime? today,
  }) {
    final query = _withProduct()
      ..where(
        db.customerAgreementTable.customerId.equals(customerId) &
            db.customerAgreementTable.enabled.equals(true),
      );
    return query.watch().map((rows) {
      final day = _dateOnly(today ?? DateTime.now());
      final list = [for (final r in rows) _toModel(r, day)];
      list.sort((a, b) {
        final byStatus = _statusOrder[a.status]!.compareTo(
          _statusOrder[b.status]!,
        );
        return byStatus != 0 ? byStatus : b.validFrom.compareTo(a.validFrom);
      });
      return list;
    });
  }

  @override
  Future<String> create({
    required String customerId,
    required String productId,
    required int unitPrice,
    required String validFrom,
    String? validTo,
    String? reason,
  }) async {
    final id = const Uuid().v4();
    await db
        .into(db.customerAgreementTable)
        .insert(
          CustomerAgreementTableCompanion.insert(
            agreementId: Value(id),
            customerId: customerId,
            productId: productId,
            unitPrice: unitPrice,
            validFrom: validFrom,
            validTo: Value(validTo),
            reason: Value(reason),
            lastModifiedDate: Value(_now()),
          ),
        );
    await _queue.enqueue(
      entity: PendingEntity.customerAgreement,
      entityId: id,
      action: PendingAction.insert,
      payload: {
        'agreementId': id,
        'customerId': customerId,
        'productId': productId,
        'unitPrice': unitPrice,
        'validFrom': validFrom,
        'validTo': validTo,
        'reason': reason,
      },
    );
    return id;
  }

  @override
  Future<CustomerAgreement?> findEnabled(
    String agreementId, {
    DateTime? today,
  }) async {
    final row =
        await (_withProduct()..where(
              db.customerAgreementTable.agreementId.equals(agreementId) &
                  db.customerAgreementTable.enabled.equals(true),
            ))
            .getSingleOrNull();
    return row == null ? null : _toModel(row, _dateOnly(today ?? _now()));
  }

  @override
  Future<void> edit(String agreementId, AgreementTerms terms) async {
    await _write(
      agreementId,
      CustomerAgreementTableCompanion(
        unitPrice: Value(terms.unitPrice),
        validFrom: Value(terms.validFrom),
        validTo: Value(terms.validTo),
        reason: Value(terms.reason),
      ),
    );
    await _enqueueUpdate(agreementId);
  }

  @override
  Future<void> disable(String agreementId) async {
    await _write(
      agreementId,
      const CustomerAgreementTableCompanion(enabled: Value(false)),
    );
    await _enqueueUpdate(agreementId, const {'enabled': false});
  }

  @override
  Future<bool> isUsedBySale(String agreementId) async {
    final line =
        await (db.select(db.saleItemTable)
              ..where((t) => t.agreementUuid.equals(agreementId))
              ..limit(1))
            .getSingleOrNull();
    return line != null;
  }

  @override
  Future<void> deleteUnsynced(String agreementId) async {
    final removed =
        await (db.delete(db.customerAgreementTable)..where(
              (t) => t.agreementId.equals(agreementId) & t.serverId.isNull(),
            ))
            .go();
    if (removed == 0) return;
    await (db.delete(db.pendingChangeTable)..where(
          (t) =>
              t.entity.equals(PendingEntity.customerAgreement.wireName) &
              t.entityId.equals(agreementId),
        ))
        .go();
  }

  @override
  Future<String> replace(
    String agreementId,
    AgreementTerms terms, {
    required DateTime today,
  }) async {
    final old = await (db.select(
      db.customerAgreementTable,
    )..where((t) => t.agreementId.equals(agreementId))).getSingle();
    final day = _dateOnly(today);
    final yesterday = _dateOnly(
      DateTime(today.year, today.month, today.day - 1),
    );
    // The server refuses an end before the start: one that started today
    // cannot end yesterday, so it is disabled instead.
    if (old.validFrom.substring(0, 10) == day) {
      await _write(
        agreementId,
        const CustomerAgreementTableCompanion(enabled: Value(false)),
      );
      await _enqueueUpdate(agreementId, const {'enabled': false});
    } else {
      final end = old.validTo?.substring(0, 10);
      await _write(
        agreementId,
        CustomerAgreementTableCompanion(
          validTo: Value(
            end != null && end.compareTo(yesterday) < 0
                ? old.validTo
                : yesterday,
          ),
        ),
      );
      await _enqueueUpdate(agreementId);
    }
    return create(
      customerId: old.customerId,
      productId: old.productId,
      unitPrice: terms.unitPrice,
      validFrom: terms.validFrom,
      validTo: terms.validTo,
      reason: terms.reason,
    );
  }

  /// Writes [fields] stamped with now; keeps the server's values first when
  /// the server knows the agreement.
  Future<void> _write(
    String agreementId,
    CustomerAgreementTableCompanion fields,
  ) async {
    final row = await (db.select(
      db.customerAgreementTable,
    )..where((t) => t.agreementId.equals(agreementId))).getSingle();
    if (row.serverId != null) {
      await _shadow.captureBeforeEdit(
        PendingEntity.customerAgreement,
        agreementId,
      );
    }
    await (db.update(db.customerAgreementTable)
          ..where((t) => t.agreementId.equals(agreementId)))
        .write(fields.copyWith(lastModifiedDate: Value(_now())));
  }

  Future<void> _enqueueUpdate(
    String agreementId, [
    Map<String, dynamic> payload = const {},
  ]) => _queue.enqueue(
    entity: PendingEntity.customerAgreement,
    entityId: agreementId,
    action: PendingAction.update,
    payload: {'agreementId': agreementId, ...payload},
  );

  JoinedSelectStatement<HasResultSet, dynamic> _withProduct() =>
      db.select(db.customerAgreementTable).join([
        innerJoin(
          db.productTable,
          db.productTable.productId.equalsExp(
            db.customerAgreementTable.productId,
          ),
        ),
      ]);

  CustomerAgreement _toModel(TypedResult r, String day) {
    final a = r.readTable(db.customerAgreementTable);
    return CustomerAgreement(
      id: a.agreementId,
      productId: a.productId,
      productName: r.readTable(db.productTable).name,
      unitPrice: a.unitPrice,
      validFrom: a.validFrom.substring(0, 10),
      validTo: a.validTo?.substring(0, 10),
      reason: a.reason,
      status: CustomerAgreement.statusOn(day, a.validFrom, a.validTo),
      isSynced: a.serverId != null,
    );
  }
}

final driftCustomerAgreementRepositoryProvider =
    Provider<CustomerAgreementRepository>(
      (ref) => DriftCustomerAgreementRepository(
        ref.watch(databaseProvider),
        now: ref.watch(clockProvider),
      ),
    );
