import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../payments/data/repositories/customer_account.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Payments, with or without a visit or a sale.
class PaymentPusher implements EntityPusher, RejectionAware {
  PaymentPusher(this._db, {DateTime Function()? today})
    : _account = CustomerAccount(_db),
      _today = today ?? DateTime.now;

  static const missing = 'El pago ya no existe en el dispositivo.';
  static String unknownMethod(String method) =>
      'Medio de pago desconocido: $method. Sincronizá el catálogo primero.';

  /// Local payment methods by the server catalog code they stand for.
  static const _catalogCodes = {
    'EFECTIVO': 'CASH',
    'TRANSFERENCIA': 'TRANSFER',
  };

  final AppDatabase _db;
  final DateTime Function() _today;
  final CustomerAccount _account;

  @override
  PendingEntity get entity => PendingEntity.payment;

  @override
  String get wireKey => 'payments';

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
      if (payment == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      // Its visit is still open: it waits so it travels linked to it.
      if (await awaitsOpenVisit(_db, payment.visitId, today: _today())) {
        continue;
      }
      final code =
          _catalogCodes[payment.paymentMethod] ?? payment.paymentMethod;
      final method =
          await (_db.select(_db.paymentMethodTable)
                ..where((t) => t.code.equals(code))
                ..limit(1))
              .getSingleOrNull();
      if (method == null) {
        rejections.add(
          LocalRejection(ids, unknownMethod(payment.paymentMethod)),
        );
        continue;
      }

      final visit = await resolveVisit(_db, payment.visitId);
      final sale = payment.saleId == null
          ? null
          : await (_db.select(_db.saleTable)
                  ..where((t) => t.saleId.equals(payment.saleId!)))
                .getSingleOrNull();
      records.add(
        PushRecord(
          uuid: paymentId,
          changeIds: ids,
          body: {
            'uuid': paymentId,
            ...await customerReference(_db, payment.customerId),
            if (visit != null)
              ...reference(
                'visit',
                serverId: visit.serverId,
                uuid: visit.visitId,
              ),
            if (payment.saleId != null)
              ...reference(
                'sale',
                serverId: sale?.serverId,
                uuid: payment.saleId!,
              ),
            'payment_method_id': method.id,
            'amount': payment.amount,
            'paid_at': payment.createdAt.toUtc().toIso8601String(),
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.paymentTable)
          ..where((t) => t.paymentId.equals(record.uuid)))
        .write(PaymentTableCompanion(serverId: Value(serverId)));
  }

  @override
  Future<void> applyRejected(String localId, {Json? current}) async {
    final payment = await (_db.select(
      _db.paymentTable,
    )..where((t) => t.paymentId.equals(localId))).getSingleOrNull();
    if (payment == null) return;
    await _account.post(payment.customerId, payment.amount);
  }
}
