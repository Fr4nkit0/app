import '../../../core/services/database.helper.dart';
import '../../payments/data/repositories/payment.repository.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';
import 'sale_cancellation_pusher.dart' show cancellationUuid;

/// Payment cancellations: a debt payment's, or each payment of a cancelled
/// sale (the server does not cancel them with the sale).
class PaymentCancellationPusher implements EntityPusher, RejectionAware {
  PaymentCancellationPusher(this._db, {DateTime Function()? today})
    : _payments = DriftPaymentRepository(_db),
      _today = today ?? DateTime.now;

  static const missing = 'El cobro anulado ya no existe en el dispositivo.';

  final AppDatabase _db;
  final DriftPaymentRepository _payments;
  final DateTime Function() _today;

  @override
  PendingEntity get entity => PendingEntity.paymentCancellation;

  @override
  String get wireKey => 'payment_cancellations';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByPayment = <String, List<int>>{};
    for (final c in changes) {
      idsByPayment.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: paymentId, value: ids) in idsByPayment.entries) {
      final payment = await (_db.select(
        _db.paymentTable,
      )..where((t) => t.paymentId.equals(paymentId))).getSingleOrNull();
      if (payment == null || payment.cancelledAt == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      // The payment waits for its open visit, so its cancellation waits too.
      if (await awaitsOpenVisit(_db, payment.visitId, today: _today())) {
        continue;
      }

      final uuid = cancellationUuid('payment', paymentId, ids.first);
      records.add(
        PushRecord(
          uuid: uuid,
          localId: paymentId,
          changeIds: ids,
          body: {
            'uuid': uuid,
            ...reference(
              'payment',
              serverId: payment.serverId,
              uuid: paymentId,
            ),
            'cancelled_at': payment.cancelledAt!.toUtc().toIso8601String(),
            'reason': payment.cancellationReason,
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  /// The server answers the payment's own id, which it already has.
  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {}

  @override
  Future<void> applyRejected(String localId, {Json? current}) =>
      _payments.undoCancellation(localId);
}
