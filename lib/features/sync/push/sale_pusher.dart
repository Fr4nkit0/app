import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../payments/data/repositories/customer_balance.store.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Sales with their lines, each at the unit price the sale draft set.
class SalePusher implements EntityPusher, RejectionAware {
  SalePusher(this._db) : _balances = CustomerBalanceStore(_db);

  static const missing = 'The sale no longer exists on the device.';
  static const empty = 'The sale has no lines.';
  static String unknownProduct(String name) =>
      'Unknown product $name; sync the catalog first.';

  final AppDatabase _db;
  final CustomerBalanceStore _balances;

  @override
  PendingEntity get entity => PendingEntity.sale;

  @override
  String get wireKey => 'sales';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsBySale = <String, List<int>>{};
    for (final c in changes) {
      idsBySale.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: saleId, value: ids) in idsBySale.entries) {
      final sale = await (_db.select(
        _db.saleTable,
      )..where((t) => t.saleId.equals(saleId))).getSingleOrNull();
      if (sale == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      final lines = await (_db.select(_db.saleItemTable).join([
        innerJoin(
          _db.productTable,
          _db.productTable.productId.equalsExp(_db.saleItemTable.productId),
        ),
      ])
            ..where(_db.saleItemTable.saleId.equals(saleId))
            ..orderBy([OrderingTerm.asc(_db.saleItemTable.rowId)]))
          .get();
      if (lines.isEmpty) {
        rejections.add(LocalRejection(ids, empty));
        continue;
      }
      final unknown = [
        for (final l in lines)
          if (l.readTable(_db.productTable).serverId == null)
            l.readTable(_db.productTable).name,
      ];
      if (unknown.isNotEmpty) {
        rejections.add(LocalRejection(ids, unknownProduct(unknown.first)));
        continue;
      }

      final visit = await resolveVisit(_db, sale.visitId);
      records.add(
        PushRecord(
          uuid: saleId,
          changeIds: ids,
          body: {
            'uuid': saleId,
            ...await customerReference(_db, sale.customerId),
            if (visit != null)
              ...reference('visit', serverId: visit.serverId, uuid: visit.visitId),
            'date': sale.saleDate.toUtc().toIso8601String(),
            'total': sale.totalAmount,
            'is_credit_sale': sale.paymentMethod == 'credit',
            'notes': null,
            'details': [
              for (final l in lines)
                {
                  'product_id': l.readTable(_db.productTable).serverId,
                  'customer_agreement_id': l
                      .readTable(_db.saleItemTable)
                      .agreementServerId,
                  'quantity': l.readTable(_db.saleItemTable).quantity,
                  'unit_price': l.readTable(_db.saleItemTable).unitPrice,
                },
            ],
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.saleTable)
          ..where((t) => t.saleId.equals(record.uuid)))
        .write(SaleTableCompanion(serverId: Value(serverId)));
  }

  @override
  Future<void> applyRejected(String localId) async {
    final sale = await (_db.select(
      _db.saleTable,
    )..where((t) => t.saleId.equals(localId))).getSingleOrNull();
    if (sale == null) return;
    await _balances.adjust(sale.customerId, -sale.totalAmount);
  }
}
