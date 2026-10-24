import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Price agreements the driver created on the street.
///
/// Agreements are never edited, so every queued change of one is a
/// creation and the record is built from the stored row.
class AgreementPusher implements EntityPusher {
  AgreementPusher(this._db);

  static const missing = 'El acuerdo ya no existe en el dispositivo.';
  static String unknownProduct(String name) =>
      'Producto desconocido: $name. Sincronizá el catálogo primero.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.customerAgreement;

  @override
  String get wireKey => 'customer_agreements';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByAgreement = <String, List<int>>{};
    for (final c in changes) {
      idsByAgreement.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: agreementId, value: ids)
        in idsByAgreement.entries) {
      final agreement = await (_db.select(
        _db.customerAgreementTable,
      )..where((t) => t.agreementId.equals(agreementId))).getSingleOrNull();
      if (agreement == null) {
        rejections.add(LocalRejection(ids, missing));
        continue;
      }
      final product = await (_db.select(
        _db.productTable,
      )..where((t) => t.productId.equals(agreement.productId))).getSingleOrNull();
      if (product?.serverId == null) {
        rejections.add(
          LocalRejection(ids, unknownProduct(product?.name ?? agreement.productId)),
        );
        continue;
      }
      records.add(
        PushRecord(
          uuid: agreementId,
          changeIds: ids,
          body: {
            'uuid': agreementId,
            ...await customerReference(_db, agreement.customerId),
            'product_id': product!.serverId,
            'unit_price': agreement.unitPrice,
            'valid_from': agreement.validFrom.substring(0, 10),
            'valid_to': agreement.validTo?.substring(0, 10),
            'reason': agreement.reason,
          },
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.customerAgreementTable)
          ..where((t) => t.agreementId.equals(record.uuid)))
        .write(CustomerAgreementTableCompanion(serverId: Value(serverId)));
  }
}
