import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Customer price agreements. A row this device pushed is matched by its
/// own uuid, before (or without) the server id being stored, so it is never
/// duplicated.
class AgreementApplier implements PullApplier {
  AgreementApplier(this._db);

  final AppDatabase _db;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final a in rows['customer_agreements'] ?? const <Json>[]) {
      final customerId = await context.ids.customer(a['customer_id'] as int?);
      final productId = await context.ids.product(a['product_id'] as int?);
      if (customerId == null || productId == null) continue;
      final serverId = a['id'] as int;
      final clientUuid = a['client_uuid'] as String?;
      final fields = CustomerAgreementTableCompanion(
        customerId: Value(customerId),
        productId: Value(productId),
        unitPrice: Value(toDouble(a['unit_price'])),
        validFrom: Value(_date(a['valid_from'] as String)),
        validTo: Value(
          a['valid_to'] == null ? null : _date(a['valid_to'] as String),
        ),
        reason: Value(a['reason'] as String?),
        serverId: Value(serverId),
      );
      if (clientUuid != null && await _updateByUuid(clientUuid, fields)) {
        continue;
      }
      final updated = await (_db.update(
        _db.customerAgreementTable,
      )..where((t) => t.serverId.equals(serverId))).write(fields);
      if (updated == 0) await _insert(fields, clientUuid);
    }
  }

  /// The bootstrap carries every agreement of [customerId]: the server rows
  /// it does not carry are deleted, the ones only on the device stay.
  Future<void> replaceForCustomer(
    String customerId,
    List<Json> agreements,
    PullContext context,
  ) async {
    final pushedUuids = [
      for (final a in agreements)
        if (a['client_uuid'] case final String uuid) uuid,
    ];
    // Rows this device pushed keep their uuid: they are updated below
    // instead of being deleted and inserted again.
    await (_db.delete(_db.customerAgreementTable)..where(
          (t) =>
              t.customerId.equals(customerId) &
              t.serverId.isNotNull() &
              t.agreementId.isNotIn(pushedUuids),
        ))
        .go();
    for (final a in agreements) {
      final productId = await context.ids.product(a['product_id'] as int);
      if (productId == null) continue;
      final clientUuid = a['client_uuid'] as String?;
      final fields = CustomerAgreementTableCompanion(
        customerId: Value(customerId),
        productId: Value(productId),
        unitPrice: Value(toDouble(a['unit_price'])),
        validFrom: Value(a['valid_from'] as String),
        validTo: Value(a['valid_to'] as String?),
        reason: Value(a['reason'] as String?),
        serverId: Value(a['id'] as int),
      );
      if (clientUuid != null && await _updateByUuid(clientUuid, fields)) {
        continue;
      }
      await _insert(fields, clientUuid);
    }
  }

  Future<bool> _updateByUuid(
    String clientUuid,
    CustomerAgreementTableCompanion fields,
  ) async =>
      await (_db.update(
        _db.customerAgreementTable,
      )..where((t) => t.agreementId.equals(clientUuid))).write(fields) >
      0;

  Future<void> _insert(
    CustomerAgreementTableCompanion fields,
    String? clientUuid,
  ) => _db
      .into(_db.customerAgreementTable)
      .insert(
        fields.copyWith(
          agreementId: clientUuid == null
              ? const Value.absent()
              : Value(clientUuid),
        ),
      );

  /// Server dates may arrive as full ISO timestamps; only the day matters.
  static String _date(String value) => value.substring(0, 10);
}
