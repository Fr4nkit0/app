import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../data/repositories/server_shadow.dart';
import 'pull_applier.dart';

/// Customer addresses, several per customer, disabled ones included.
class AddressApplier implements PullApplier {
  AddressApplier(this._db) : _shadow = ServerShadow(_db);

  final AppDatabase _db;
  final ServerShadow _shadow;

  @override
  Future<void> applyChanges(
    Map<String, List<Json>> rows,
    PullContext context,
  ) async {
    for (final a in rows['customer_addresses'] ?? const <Json>[]) {
      final customerId = await context.ids.customer(a['customer_id'] as int?);
      if (customerId == null) continue;
      await _upsert(a, customerId, context);
    }
  }

  /// Stores the [addresses] of [customerId], as the bootstrap nests them.
  Future<void> applyForCustomer(
    String customerId,
    List<Json> addresses,
    PullContext context,
  ) async {
    for (final a in addresses) {
      await _upsert(a, customerId, context);
    }
  }

  /// A server address is matched by its server id, then by its client uuid
  /// (the local id it was pushed with). A server row without client uuid
  /// comes from a push that did not send one: the server built it from the
  /// address the customer push sent, so it is linked to that local row
  /// instead of duplicated, whether or not either side marks it as primary.
  ///
  /// A customer with unsent changes, of its own or of any of its addresses,
  /// keeps its local addresses; they only get linked to their server id.
  /// The server values they skipped are kept for a rollback of those
  /// changes.
  Future<void> _upsert(Json a, String customerId, PullContext context) async {
    final keepLocal =
        context.unsent.customers.contains(customerId) ||
        context.unsent.addressOwners.contains(customerId);
    final serverId = a['id'] as int;
    final clientUuid = a['client_uuid'] as String?;
    final existing =
        await (_db.select(
          _db.customerAddressTable,
        )..where((t) => t.serverId.equals(serverId))).getSingleOrNull() ??
        await (clientUuid == null
            ? _unlinkedPushedAddress(customerId, context)
            : (_db.select(_db.customerAddressTable)
                    ..where((t) => t.addressId.equals(clientUuid)))
                  .getSingleOrNull());
    final fields = CustomerAddressTableCompanion(
      customerId: Value(customerId),
      street: Value(a['street'] as String?),
      apartment: Value(a['apartment'] as String?),
      // Older server rows stored the floor as an integer, so a free-text floor
      // ("PB") could come back as null; keep the device's value then.
      floor: a['floor'] == null && _isFreeTextFloor(existing?.floor)
          ? const Value.absent()
          : Value(a['floor']?.toString()),
      visualReference: Value(a['visual_reference'] as String?),
      isPrimary: Value(a['is_primary'] == true),
      latitude: Value(toNullableDouble(a['latitude'])),
      longitude: Value(toNullableDouble(a['longitude'])),
      neighborhood: Value(a['neighborhood'] as String?),
      enabled: enabledOf(a),
      serverId: Value(serverId),
    );
    if (existing == null) {
      final row = await _db
          .into(_db.customerAddressTable)
          .insertReturning(
            fields.copyWith(
              addressId: clientUuid == null
                  ? const Value.absent()
                  : Value(clientUuid),
              // The local primary stands until its unsent switch is sent.
              isPrimary: keepLocal && await _hasPrimary(customerId)
                  ? const Value(false)
                  : fields.isPrimary,
            ),
          );
      context.ids.recordAddress(serverId, row.addressId);
      return;
    }
    if (keepLocal) {
      await _shadow.storePulledAddress(
        customerId,
        existing.addressId,
        fields,
        ownChange: context.unsent.addresses.contains(existing.addressId),
      );
    }
    await (_db.update(
      _db.customerAddressTable,
    )..where((t) => t.addressId.equals(existing.addressId))).write(
      keepLocal
          ? CustomerAddressTableCompanion(serverId: Value(serverId))
          : fields,
    );
    context.ids.recordAddress(serverId, existing.addressId);
  }

  Future<bool> _hasPrimary(String customerId) async =>
      (await (_db.select(_db.customerAddressTable)
                ..where(
                  (t) =>
                      t.customerId.equals(customerId) &
                      t.isPrimary.equals(true) &
                      t.enabled.equals(true),
                )
                ..limit(1))
              .get())
          .isNotEmpty;

  static bool _isFreeTextFloor(String? floor) =>
      floor != null &&
      floor.trim().isNotEmpty &&
      int.tryParse(floor.trim()) == null;

  /// The unlinked address the customer push sends: same selection and order
  /// as `CustomerPusher`. An address with its own unsent change travels
  /// under its own uuid and is linked by it instead; one whose latest change
  /// was rejected is never linked (APP-29).
  Future<CustomerAddressTableData?> _unlinkedPushedAddress(
    String customerId,
    PullContext context,
  ) async =>
      (await (_db.select(_db.customerAddressTable)
                ..where(
                  (t) =>
                      t.customerId.equals(customerId) &
                      t.serverId.isNull() &
                      t.enabled.equals(true) &
                      t.addressId.isNotIn(context.unsent.addresses) &
                      t.addressId.isNotIn(context.unsent.rejectedAddresses),
                )
                ..orderBy([
                  (t) => OrderingTerm.desc(t.isPrimary),
                  (t) => OrderingTerm.asc(t.createdAt),
                ])
                ..limit(1))
              .get())
          .firstOrNull;
}
