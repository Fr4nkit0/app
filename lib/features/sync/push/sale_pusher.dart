import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../../payments/data/repositories/customer_account.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Sales with their lines, each at the unit price the sale draft set.
class SalePusher implements EntityPusher, RejectionAware {
  SalePusher(this._db) : _account = CustomerAccount(_db);

  static const missing = 'La venta ya no existe en el dispositivo.';
  static const empty = 'La venta no tiene productos.';
  static String unknownProduct(String name) =>
      'Producto desconocido: $name. Sincronizá el catálogo primero.';

  final AppDatabase _db;
  final CustomerAccount _account;

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
                  ...await _agreementReference(
                    l.readTable(_db.saleItemTable),
                  ),
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

  /// The line's agreement by server id when it has one (the line's own or
  /// the one stored since), by local uuid while it has not.
  Future<Json> _agreementReference(SaleItemTableData line) async {
    final uuid = line.agreementUuid;
    var serverId = line.agreementServerId;
    if (serverId == null && uuid != null) {
      serverId = (await (_db.select(_db.customerAgreementTable)
                ..where((t) => t.agreementId.equals(uuid)))
              .getSingleOrNull())
          ?.serverId;
    }
    if (uuid == null) return {'customer_agreement_id': serverId};
    return reference('customer_agreement', serverId: serverId, uuid: uuid);
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
    await _account.post(sale.customerId, -sale.totalAmount);
  }
}
