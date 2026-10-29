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

  /// An address created on the street has no server id yet; the server's
  /// primary address of the same customer is that one, so it gets linked
  /// instead of duplicated.
  Future<void> _upsert(Json a, String customerId, PullContext context) async {
    final keepLocal = context.unsent.customers.contains(customerId);
    final serverId = a['id'] as int;
    final existing =
        await (_db.select(
          _db.customerAddressTable,
        )..where((t) => t.serverId.equals(serverId))).getSingleOrNull() ??
        (a['is_primary'] == true
            ? await _unlinkedPrimaryAddress(customerId)
            : null);
    final fields = CustomerAddressTableCompanion(
      customerId: Value(customerId),
      street: Value(a['street'] as String?),
      apartment: Value(a['apartment'] as String?),
      // The server stores the floor as an integer column, so a free-text floor
      // ("PB") comes back as null; keep the device's value until the server
      // can store text.
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

  Future<CustomerAddressTableData?> _unlinkedPrimaryAddress(
    String customerId,
  ) async =>
      (await (_db.select(_db.customerAddressTable)
                ..where(
                  (t) =>
                      t.customerId.equals(customerId) &
                      t.serverId.isNull() &
                      t.isPrimary.equals(true),
                )
                ..limit(1))
              .get())
          .firstOrNull;
}
