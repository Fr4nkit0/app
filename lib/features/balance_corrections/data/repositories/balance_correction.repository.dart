import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/balance_corrections/domain/models/balance_correction.dart';
import 'package:app/features/inventory/data/repositories/custody.dart';
import 'package:app/features/payments/data/repositories/customer_account.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Stores balance corrections, moves the balance they correct and queues
/// them. Never opens a transaction: the caller owns the unit of work
/// (ADR 0001).
abstract interface class BalanceCorrectionRepository {
  /// The balance the device shows for [target] of [customerId]: the
  /// account, or the custody of [containerType].
  Future<int> shownBalance(
    String customerId,
    BalanceTarget target, {
    String? containerType,
  });

  /// Records [correction], moves its balance by its difference and queues
  /// it for the server.
  Future<void> record(BalanceCorrection correction);

  /// Moves the balance of the correction [correctionId] back by its
  /// difference: the server rejected it. Nothing when it no longer exists.
  Future<void> takeBack(String correctionId);
}

class DriftBalanceCorrectionRepository implements BalanceCorrectionRepository {
  DriftBalanceCorrectionRepository(AppDatabase db)
    : _db = db,
      _account = CustomerAccount(db),
      _custody = Custody(db),
      _queue = DriftPendingChangeRepository(db);

  final AppDatabase _db;
  final CustomerAccount _account;
  final Custody _custody;
  final PendingChangeRepository _queue;

  @override
  Future<int> shownBalance(
    String customerId,
    BalanceTarget target, {
    String? containerType,
  }) async => switch (target) {
    BalanceTarget.debt => await _account.balanceOf(customerId),
    BalanceTarget.containers => (await _custody.quantityOf(
      customerId,
      containerType!,
    )),
  };

  @override
  Future<void> record(BalanceCorrection correction) async {
    await _db
        .into(_db.balanceCorrectionTable)
        .insert(
          BalanceCorrectionTableCompanion.insert(
            correctionId: Value(correction.id),
            customerId: correction.customerId,
            visitId: Value(correction.visitId),
            target: correction.target.wireName,
            containerType: Value(correction.containerType),
            counted: correction.counted,
            seenBalance: correction.seenBalance,
            reason: correction.reason,
            correctedAt: correction.correctedAt,
            createdAt: Value(correction.correctedAt),
          ),
        );
    await _post(
      correction.customerId,
      correction.target,
      correction.containerType,
      correction.difference,
    );
    await _queue.enqueue(
      entity: PendingEntity.balanceCorrection,
      entityId: correction.id,
      action: PendingAction.insert,
      payload: {
        'correctionId': correction.id,
        'customerId': correction.customerId,
        'target': correction.target.wireName,
        'containerType': correction.containerType,
        'counted': correction.counted,
        'seenBalance': correction.seenBalance,
        'reason': correction.reason,
        'correctedAt': correction.correctedAt.toIso8601String(),
      },
    );
  }

  @override
  Future<void> takeBack(String correctionId) async {
    final row = await (_db.select(
      _db.balanceCorrectionTable,
    )..where((t) => t.correctionId.equals(correctionId))).getSingleOrNull();
    if (row == null) return;
    await _post(
      row.customerId,
      BalanceTarget.fromWire(row.target),
      row.containerType,
      row.seenBalance - row.counted,
    );
  }

  Future<void> _post(
    String customerId,
    BalanceTarget target,
    String? containerType,
    int delta,
  ) async {
    if (delta == 0) return;
    switch (target) {
      case BalanceTarget.debt:
        await _account.post(customerId, delta);
      case BalanceTarget.containers:
        await _custody.post(customerId, containerType!, delta);
    }
  }
}
