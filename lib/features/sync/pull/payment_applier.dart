import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database.helper.dart';
import '../../payments/data/repositories/payment.repository.dart';
import '../../payments/domain/models/payment.dart';
import '../../sales/data/database/record_status.dart';
import 'pull_applier.dart';

/// Today's payments, carried only by the bootstrap so a reinstalled device
/// rebuilds the day's work; the incremental pull does not send them.
///
/// Rows are written directly, never through the payment repository: the
/// server balances already include these payments, so they move no balance
/// and nothing is queued for push. A cancelled payment is stored as
/// cancelled, with its adjustment.
class PaymentApplier {
  PaymentApplier(this._db);

  final AppDatabase _db;

  /// Local payment methods by the server catalog code they stand for; any
  /// other code is stored as it is.
  static final _localMethods = {
    'CASH': PaymentType.cash.dbValue,
    'TRANSFER': PaymentType.transfer.dbValue,
  };

  /// A payment already on the device (by client uuid or server id) is only
  /// linked to its server id. One whose customer or payment method the
  /// download did not carry is dropped.
  Future<void> storeToday(List<Json> payments, PullContext context) async {
    for (final p in payments) {
      final serverId = p['id'] as int;
      final clientUuid = p['client_uuid'] as String?;
      final existing =
          await (_db.select(_db.paymentTable)..where(
                (t) =>
                    t.serverId.equals(serverId) |
                    (clientUuid == null
                        ? const Constant(false)
                        : t.paymentId.equals(clientUuid)),
              ))
              .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.paymentTable)
              ..where((t) => t.paymentId.equals(existing.paymentId)))
            .write(PaymentTableCompanion(serverId: Value(serverId)));
        continue;
      }
      final customerId = await context.ids.customer(p['customer_id'] as int?);
      final method = await _localMethod(p['payment_method_id'] as int?);
      if (customerId == null || method == null) continue;

      final paymentId = clientUuid ?? const Uuid().v4();
      final amount = toDouble(p['amount']);
      final paidAt = DateTime.parse(p['paid_at'] as String).toLocal();
      final cancelled = p['status'] == RecordStatus.cancelled;
      // The server sends no cancellation date: its last update is it.
      final cancelledAt = cancelled
          ? DateTime.parse(p['updated_at'] as String).toLocal()
          : null;
      await _db
          .into(_db.paymentTable)
          .insert(
            PaymentTableCompanion.insert(
              paymentId: Value(paymentId),
              customerId: customerId,
              amount: amount,
              paymentMethod: method,
              createdAt: Value(paidAt),
              visitId: Value(
                await context.ids.stopOfVisit(p['visit_id'] as int?),
              ),
              saleId: Value(await context.ids.sale(p['sale_id'] as int?)),
              serverId: Value(serverId),
              status: Value(
                cancelled ? RecordStatus.cancelled : RecordStatus.confirmed,
              ),
              cancelledAt: Value(cancelledAt),
            ),
          );
      // The ledger lines only; the downloaded balance already counts them.
      await _db
          .into(_db.customerAccountEntryTable)
          .insert(
            CustomerAccountEntryTableCompanion.insert(
              customerId: customerId,
              paymentId: Value(paymentId),
              entryType: 'PAYMENT',
              amount: amount,
              direction: -1,
              createdAt: Value(paidAt),
              description: const Value('Payment recorded'),
            ),
          );
      if (cancelledAt != null) {
        await _db
            .into(_db.customerAccountEntryTable)
            .insert(
              CustomerAccountEntryTableCompanion.insert(
                customerId: customerId,
                paymentId: Value(paymentId),
                entryType: DriftPaymentRepository.adjustmentEntry,
                amount: amount,
                direction: 1,
                createdAt: Value(cancelledAt),
                description: const Value('Payment cancelled'),
              ),
            );
      }
    }
  }

  Future<String?> _localMethod(int? catalogId) async {
    if (catalogId == null) return null;
    final method = await (_db.select(
      _db.paymentMethodTable,
    )..where((t) => t.id.equals(catalogId))).getSingleOrNull();
    if (method == null) return null;
    return _localMethods[method.code] ?? method.code;
  }
}
