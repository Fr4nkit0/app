import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import 'pull_applier.dart';

/// Customer addresses. A customer with unsent changes keeps its local
/// addresses; they only get linked to their server id.
class AddressApplier implements PullApplier {
  AddressApplier(this._db);

  final AppDatabase _db;

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

  /// An address created on the street has no server id yet. The server keeps
  /// one address per customer, built from the address the customer push sent,
  /// so the server address is linked to that local row instead of duplicated,
  /// whether or not either side marks it as primary.
  Future<void> _upsert(Json a, String customerId, PullContext context) async {
    final keepLocal = context.unsent.customers.contains(customerId);
    final serverId = a['id'] as int;
    final existing =
        await (_db.select(
          _db.customerAddressTable,
        )..where((t) => t.serverId.equals(serverId))).getSingleOrNull() ??
        await _unlinkedPushedAddress(customerId);
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
          .insertReturning(fields);
      context.ids.recordAddress(serverId, row.addressId);
      return;
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

  static bool _isFreeTextFloor(String? floor) =>
      floor != null &&
      floor.trim().isNotEmpty &&
      int.tryParse(floor.trim()) == null;

  /// The unlinked address the customer push sends: same selection and order
  /// as `CustomerPusher`.
  Future<CustomerAddressTableData?> _unlinkedPushedAddress(
    String customerId,
  ) async =>
      (await (_db.select(_db.customerAddressTable)
                ..where(
                  (t) =>
                      t.customerId.equals(customerId) &
                      t.serverId.isNull() &
                      t.enabled.equals(true),
                )
                ..orderBy([
                  (t) => OrderingTerm.desc(t.isPrimary),
                  (t) => OrderingTerm.asc(t.createdAt),
                ])
                ..limit(1))
              .get())
          .firstOrNull;
}
