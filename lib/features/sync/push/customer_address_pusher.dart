import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../data/repositories/server_shadow.dart';
import '../domain/models/pending_change.dart';
import 'customer_pusher.dart';
import 'entity_pusher.dart';
import 'references.dart';

/// Addresses added or changed from the customer profile.
///
/// Like customers, every change of the same address collapses into one
/// record built from the current local row: whole while the server does not
/// know the address, and with only the changed fields once it does (see
/// `CustomerPusher`). Primary addresses travel
/// first: the server unsets the previous primary when it gets the new one,
/// and refuses to leave a customer without a primary in between.
///
/// A rejected address goes back to the server's values (the server row the
/// answer carries, or the last ones known), or is deleted when the server
/// never stored it.
class CustomerAddressPusher implements EntityPusher, RejectionAware {
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
    final changesByAddress = <String, List<PendingChange>>{};
    for (final c in changes) {
      changesByAddress.putIfAbsent(c.entityId, () => []).add(c);
    }

    final primaries = <PushRecord>[];
    final others = <PushRecord>[];
    final rejections = <LocalRejection>[];
    final settled = <int>[];
    for (final MapEntry(key: addressId, value: ofAddress)
        in changesByAddress.entries) {
      final changeIds = [for (final c in ofAddress) c.id];
      final address = await (_db.select(
        _db.customerAddressTable,
      )..where((t) => t.addressId.equals(addressId))).getSingleOrNull();
      if (address == null) {
        rejections.add(LocalRejection(changeIds, missingAddress));
        continue;
      }
      final fields = PendingChange.changedFieldsOf(ofAddress);
      final body = await _body(
        address,
        only: address.serverId == null ? null : fields,
      );
      if (body == null) {
        // Nothing left to tell the server.
        settled.addAll(changeIds);
        continue;
      }
      final record = PushRecord(
        uuid: addressId,
        body: body,
        changeIds: changeIds,
      );
      (address.isPrimary ? primaries : others).add(record);
    }
    return PushPlan(
      records: [...primaries, ...others],
      rejections: rejections,
      settled: settled,
    );
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.customerAddressTable)
          ..where((t) => t.addressId.equals(record.uuid)))
        .write(CustomerAddressTableCompanion(serverId: Value(serverId)));
  }

  @override
  Future<void> applyRejected(String localId, {Json? current}) async {
    final address = await (_db.select(
      _db.customerAddressTable,
    )..where((t) => t.addressId.equals(localId))).getSingleOrNull();
    if (address == null) return;
    await ServerShadow(_db).rollBackRejected(
      entity,
      localId,
      refused: {
        for (final MapEntry(:key, :value) in CustomerPusher.addressValues(
          address,
        ).entries)
          if (key != 'latitude' && key != 'longitude') key: value,
        'is_primary': address.isPrimary,
        'enabled': address.enabled,
      },
      stored: address.serverId != null,
      current: current,
      delete: () async {
        await (_db.delete(
          _db.customerAddressTable,
        )..where((t) => t.addressId.equals(localId))).go();
        return true;
      },
    );
  }

  /// The whole record, or only the fields in [only] when it is given; null
  /// when [only] leaves nothing to send.
  Future<Json?> _body(
    CustomerAddressTableData address, {
    Set<String>? only,
  }) async {
    final values = {
      ...CustomerPusher.addressValues(address),
      'is_primary': address.isPrimary,
      'enabled': address.enabled,
    };
    if (only != null) {
      values.removeWhere((field, _) => !only.contains(field));
      if (values.isEmpty) return null;
    }
    return {
      'uuid': address.addressId,
      'server_id': ?address.serverId,
      ...await customerReference(_db, address.customerId),
      ...values,
      'modified_at': address.lastModifiedDate.toUtc().toIso8601String(),
    };
  }
}
