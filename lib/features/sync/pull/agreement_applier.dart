import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../data/repositories/server_shadow.dart';
import 'pull_applier.dart';

/// Customer price agreements, disabled ones included: a disabled agreement
/// is stored as such, so it stops pricing sales and leaves the list.
///
/// A row this device pushed is matched by its own uuid, before (or without)
/// the server id being stored, so it is never duplicated. An agreement with
/// an unsent change keeps its local values and only gets linked to its
/// server id; the server values it skipped are kept ([ServerShadow]) for a
/// rollback of that change.
class AgreementApplier implements PullApplier {
  AgreementApplier(this._db) : _shadow = ServerShadow(_db);

  final AppDatabase _db;
  final ServerShadow _shadow;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final a in rows['customer_agreements'] ?? const <Json>[]) {
      final customerId = await context.ids.customer(a['customer_id'] as int?);
      final productId = await context.ids.product(a['product_id'] as int?);
      if (customerId == null || productId == null) continue;
      await _upsert(a, customerId, productId, context);
    }
  }

  /// The bootstrap carries the agreements of [customerId] that are enabled
  /// and in force or future: the server rows it does not carry are deleted,
  /// the ones only on the device stay, and so do the ones with an unsent
  /// change (a close or a soft delete the server does not have yet).
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
              t.agreementId.isNotIn(pushedUuids) &
              t.agreementId.isNotIn(context.unsent.agreements),
        ))
        .go();
    for (final a in agreements) {
      final productId = await context.ids.product(a['product_id'] as int?);
      if (productId == null) continue;
      await _upsert(a, customerId, productId, context);
    }
  }

  /// The local columns of the server agreement row [a], server id included
  /// and customer and product left out. A row without `enabled` leaves the
  /// stored flag as it is (enabled for a new row).
  static CustomerAgreementTableCompanion fieldsOf(Json a) =>
      CustomerAgreementTableCompanion(
        unitPrice: Value(toDouble(a['unit_price'])),
        validFrom: Value(_date(a['valid_from'] as String)),
        validTo: Value(
          a['valid_to'] == null ? null : _date(a['valid_to'] as String),
        ),
        reason: Value(a['reason'] as String?),
        enabled: enabledOf(a),
        serverId: Value(a['id'] as int),
      );

  /// Matched by client uuid, then by server id.
  Future<void> _upsert(
    Json a,
    String customerId,
    String productId,
    PullContext context,
  ) async {
    final serverId = a['id'] as int;
    final clientUuid = a['client_uuid'] as String?;
    final fields = fieldsOf(
      a,
    ).copyWith(customerId: Value(customerId), productId: Value(productId));
    final existing =
        (clientUuid == null
            ? null
            : await (_db.select(_db.customerAgreementTable)
                    ..where((t) => t.agreementId.equals(clientUuid)))
                  .getSingleOrNull()) ??
        await (_db.select(
          _db.customerAgreementTable,
        )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.customerAgreementTable)
          .insert(
            fields.copyWith(
              agreementId: clientUuid == null
                  ? const Value.absent()
                  : Value(clientUuid),
            ),
          );
      return;
    }
    final keepLocal = context.unsent.agreements.contains(existing.agreementId);
    if (keepLocal) {
      await _shadow.storePulledAgreement(existing.agreementId, fields);
    }
    await (_db.update(
      _db.customerAgreementTable,
    )..where((t) => t.agreementId.equals(existing.agreementId))).write(
      keepLocal
          ? CustomerAgreementTableCompanion(serverId: Value(serverId))
          : fields,
    );
  }

  /// Server dates may arrive as full ISO timestamps; only the day matters.
  static String _date(String value) => value.substring(0, 10);
}
