import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'customer_pusher.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Addresses added or changed from the customer profile.
///
/// Like customers, every change of the same address collapses into one
/// record rebuilt from the current local row. Primary addresses travel
/// first: the server unsets the previous primary when it gets the new one,
/// and refuses to leave a customer without a primary in between.
class CustomerAddressPusher implements EntityPusher {
  CustomerAddressPusher(this._db);

  /// An address is never deleted on the device; a change whose row is gone
  /// cannot be sent.
  static const missingAddress = 'La dirección ya no existe en el teléfono.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.customerAddress;

  @override
  String get wireKey => 'customer_addresses';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByAddress = <String, List<int>>{};
    for (final c in changes) {
      idsByAddress.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final primaries = <PushRecord>[];
    final others = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: addressId, value: changeIds)
        in idsByAddress.entries) {
      final address = await (_db.select(
        _db.customerAddressTable,
      )..where((t) => t.addressId.equals(addressId))).getSingleOrNull();
      if (address == null) {
        rejections.add(LocalRejection(changeIds, missingAddress));
        continue;
      }
      final record = PushRecord(
        uuid: addressId,
        body: await _body(address),
        changeIds: changeIds,
      );
      (address.isPrimary ? primaries : others).add(record);
    }
    return PushPlan(records: [...primaries, ...others], rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.customerAddressTable)
          ..where((t) => t.addressId.equals(record.uuid)))
        .write(CustomerAddressTableCompanion(serverId: Value(serverId)));
  }

  Future<Json> _body(CustomerAddressTableData address) async => {
    'uuid': address.addressId,
    'server_id': ?address.serverId,
    ...await customerReference(_db, address.customerId),
    'street': address.street,
    'apartment': address.apartment,
    'floor': CustomerPusher.floorOf(address.floor),
    'visual_reference': address.visualReference,
    'neighborhood': address.neighborhood,
    'latitude': address.latitude,
    'longitude': address.longitude,
    'is_primary': address.isPrimary,
    'enabled': address.enabled,
    'modified_at': address.lastModifiedDate.toUtc().toIso8601String(),
  };
}
