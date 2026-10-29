import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database.helper.dart';
import '../../sales/domain/models/payment_method.dart';
import 'pull_applier.dart';

/// Today's sales, carried only by the bootstrap so a reinstalled device
/// rebuilds the day's work; the incremental pull does not send them.
///
/// Rows are written directly, never through the sale repository: the
/// server balances and truck inventory already include these sales, so
/// they move no balance or stock and nothing is queued for push.
///
/// Limits of the download: payments are not in it, so the method is
/// `credit` for a credit sale and `cash` otherwise; and a cancelled sale
/// is not stored, since the local sales have no status yet.
class SaleApplier {
  SaleApplier(this._db);

  final AppDatabase _db;

  /// A sale already on the device (by client uuid or server id) is only
  /// linked to its server id. Lines whose product the download did not
  /// carry are dropped.
  Future<void> storeToday(List<Json> sales, PullContext context) async {
    for (final s in sales) {
      final serverId = s['id'] as int;
      final clientUuid = s['client_uuid'] as String?;
      final existing =
          await (_db.select(_db.saleTable)..where(
                (t) =>
                    t.serverId.equals(serverId) |
                    (clientUuid == null
                        ? const Constant(false)
                        : t.saleId.equals(clientUuid)),
              ))
              .getSingleOrNull();
      if (existing != null) {
        await (_db.update(_db.saleTable)
              ..where((t) => t.saleId.equals(existing.saleId)))
            .write(SaleTableCompanion(serverId: Value(serverId)));
        continue;
      }
      final customerId = await context.ids.customer(s['customer_id'] as int?);
      if (s['status'] == 'cancelled' || customerId == null) continue;

      final saleId = clientUuid ?? const Uuid().v4();
      final total = toDouble(s['total']);
      final isCredit = s['is_credit_sale'] == true;
      final date = DateTime.parse(s['date'] as String).toLocal();
      await _db
          .into(_db.saleTable)
          .insert(
            SaleTableCompanion.insert(
              saleId: Value(saleId),
              customerId: customerId,
              totalAmount: total,
              paymentMethod:
                  (isCredit ? PaymentMethod.credit : PaymentMethod.cash).name,
              saleDate: Value(date),
              quantity: 0,
              shipping_amount: 0,
              visitId: Value(
                await _stopOfVisit(s['visit_id'] as int?, context),
              ),
              serverId: Value(serverId),
            ),
          );
      for (final d in jsonList(s['details'])) {
        final productId = await context.ids.product(d['product_id'] as int?);
        if (productId == null) continue;
        final quantity = toDouble(d['quantity']).round();
        final unitPrice = toDouble(d['unit_price']);
        await _db
            .into(_db.saleItemTable)
            .insert(
              SaleItemTableCompanion.insert(
                saleId: saleId,
                productId: productId,
                quantity: quantity,
                unitPrice: unitPrice,
                subtotal: quantity * unitPrice,
                agreementServerId: Value(d['customer_agreement_id'] as int?),
                serverId: Value(d['id'] as int?),
              ),
            );
      }
      // The ledger line only; the downloaded balance already counts it.
      await _db
          .into(_db.customerAccountEntryTable)
          .insert(
            CustomerAccountEntryTableCompanion.insert(
              customerId: customerId,
              saleId: Value(saleId),
              entryType: 'SALE',
              amount: total,
              direction: 1,
              createdAt: Value(date),
              description: Value(isCredit ? 'Credit sale' : 'Sale'),
            ),
          );
    }
  }

  /// Sales of a visit carry its stop's id, like the ones made on the device.
  Future<String?> _stopOfVisit(int? serverId, PullContext context) async {
    final visitId = await context.ids.visit(serverId);
    if (visitId == null) return null;
    return (await (_db.select(
      _db.visitTable,
    )..where((t) => t.visitId.equals(visitId))).getSingleOrNull())?.routeStopId;
  }
}
