import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../inventory/data/repositories/inventory.repository.dart';
import '../../payments/data/repositories/payment.repository.dart';
import '../../payments/domain/usecases/cancel_payment.usecase.dart';
import '../../sales/data/repositories/drift.sale.repository.dart';
import '../../sales/domain/usecases/cancel_sale.usecase.dart';
import '../data/repositories/admin_cancellations.dart';
import '../data/repositories/pending_change.repository.dart';
import '../domain/models/pending_change.dart';
import 'pull_applier.dart';

/// The driver's sales and payments the server cancelled (the office, or a
/// cancellation this device pushed), re-sent whenever the record changes.
///
/// A record on the device (by server id or client uuid) that is not
/// cancelled yet is cancelled through the same use case as a cancellation
/// on the device, so the truck stock, the customer account and custody move
/// the same way, but nothing is queued. A record already cancelled is left
/// as it is, so a re-sent event never reverses it twice; a cancellation
/// of it still queued is settled, since the server already holds it.
/// Records not on the device are ignored.
///
/// Runs before the balances and the truck inventory of the same download,
/// which already count the cancellation and replace the local values.
class CancellationApplier implements PullApplier {
  CancellationApplier(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      _queue = DriftPendingChangeRepository(_db),
      _admin = AdminCancellations(_db);

  final AppDatabase _db;
  final DateTime Function() _now;
  final PendingChangeRepository _queue;
  final AdminCancellations _admin;

  /// The pull already runs in one transaction.
  static Future<T> _inPull<T>(Future<T> Function() action) => action();

  late final _sales = CancelSaleUseCase(
    saleRepo: DriftSaleRepository(_db),
    paymentRepo: DriftPaymentRepository(_db),
    inventoryRepo: DriftInventoryRepository(_db),
    transaction: _inPull,
  );

  late final _payments = CancelPaymentUseCase(
    paymentRepo: DriftPaymentRepository(_db),
    transaction: _inPull,
  );

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final event in rows['sale_cancellations'] ?? const <Json>[]) {
      final saleId = await _localSale(event);
      if (saleId == null) continue;
      await _sales.applyServerCancellation(
        saleId,
        at: _cancelledAt(event),
        reason: event['reason'] as String?,
      );
      await _settleQueued(PendingEntity.saleCancellation, saleId);
      await _admin.setSale(saleId, byAdmin: _byAdmin(event));
    }
    for (final event in rows['payment_cancellations'] ?? const <Json>[]) {
      final paymentId = await _localPayment(event);
      if (paymentId == null) continue;
      await _payments.applyServerCancellation(
        paymentId,
        at: _cancelledAt(event),
        reason: event['reason'] as String?,
      );
      await _settleQueued(PendingEntity.paymentCancellation, paymentId);
      await _admin.setPayment(paymentId, byAdmin: _byAdmin(event));
    }
  }

  Future<String?> _localSale(Json event) async {
    final serverId = event['sale_id'] as int?;
    final clientUuid = event['client_uuid'] as String?;
    final row =
        await (_db.select(_db.saleTable)
              ..where(
                (t) =>
                    _matches(t.serverId, serverId) |
                    _matches(t.saleId, clientUuid),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.saleId;
  }

  Future<String?> _localPayment(Json event) async {
    final serverId = event['payment_id'] as int?;
    final clientUuid = event['client_uuid'] as String?;
    final row =
        await (_db.select(_db.paymentTable)
              ..where(
                (t) =>
                    _matches(t.serverId, serverId) |
                    _matches(t.paymentId, clientUuid),
              )
              ..limit(1))
            .getSingleOrNull();
    return row?.paymentId;
  }

  static Expression<bool> _matches<T extends Object>(
    GeneratedColumn<T> column,
    T? value,
  ) => value == null ? const Constant(false) : column.equals(value);

  /// The local cancellations of [entityId] still waiting to be pushed: the
  /// server already holds them, so they stop counting as unsent.
  Future<void> _settleQueued(PendingEntity entity, String entityId) async {
    final ids = [
      for (final change in await _queue.getPending())
        if (change.entity == entity && change.entityId == entityId) change.id,
    ];
    await _queue.markSent(ids);
  }

  DateTime _cancelledAt(Json event) {
    final at = event['cancelled_at'] as String?;
    return at == null ? _now() : DateTime.parse(at).toLocal();
  }

  static bool _byAdmin(Json event) => event['cancelled_by_admin'] == true;
}
