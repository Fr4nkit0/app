import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../data/repositories/server_shadow.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Price agreements the driver created, edited, closed or disabled on the
/// street.
///
/// Every queued change of the same agreement collapses into one record
/// built whole from the current local row; the server compares its
/// `modified_at` with its own copy. Records travel in the order of their
/// oldest queued change: a replacement closes (or disables) the old
/// agreement before it creates the new one, and the server needs the old
/// one closed first.
///
/// A rejected agreement goes back to the server's values (the server row
/// the answer carries, or the last ones known), or is deleted when the
/// server never stored it and no sale used it.
class AgreementPusher implements EntityPusher, RejectionAware {
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
    int oldest(List<int> ids) => ids.reduce((a, b) => a < b ? a : b);
    final ordered = idsByAgreement.entries.toList()
      ..sort((a, b) => oldest(a.value).compareTo(oldest(b.value)));

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: agreementId, value: ids) in ordered) {
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
            'server_id': ?agreement.serverId,
            ...await customerReference(_db, agreement.customerId),
            'product_id': product!.serverId,
            ..._values(agreement),
            'modified_at': agreement.lastModifiedDate.toUtc().toIso8601String(),
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

  @override
  Future<void> applyRejected(String localId, {Json? current}) async {
    final agreement = await (_db.select(
      _db.customerAgreementTable,
    )..where((t) => t.agreementId.equals(localId))).getSingleOrNull();
    if (agreement == null) return;
    await ServerShadow(_db).rollBackRejected(
      entity,
      localId,
      refused: _values(agreement),
      stored: agreement.serverId != null,
      current: current,
      delete: () async {
        // A sale already priced with it keeps it, so the sale still says
        // which agreement priced it.
        final used = await (_db.select(_db.saleItemTable)
              ..where((t) => t.agreementUuid.equals(localId))
              ..limit(1))
            .get();
        if (used.isNotEmpty) return false;
        await (_db.delete(
          _db.customerAgreementTable,
        )..where((t) => t.agreementId.equals(localId))).go();
        return true;
      },
    );
  }

  /// The synced values of [agreement] by wire name.
  static Json _values(CustomerAgreementTableData agreement) => {
    'unit_price': agreement.unitPrice,
    'valid_from': agreement.validFrom.substring(0, 10),
    'valid_to': agreement.validTo?.substring(0, 10),
    'reason': agreement.reason,
    'enabled': agreement.enabled,
  };
}
