import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';

/// Customers created or edited on the street.
///
/// Queued payloads may be partial (a coordinates fix carries only lat/lng),
/// so the record is rebuilt from the current local row: every change of the
/// same customer collapses into one record carrying its latest state.
class CustomerPusher implements EntityPusher {
  CustomerPusher(this._db);

  static const deletionNotSynced =
      'Deleting a customer is not synced with the server.';

  final AppDatabase _db;

  @override
  PendingEntity get entity => PendingEntity.customer;

  @override
  String get wireKey => 'customers';

  @override
  Future<PushPlan> plan(List<PendingChange> changes) async {
    final idsByCustomer = <String, List<int>>{};
    for (final c in changes) {
      idsByCustomer.putIfAbsent(c.entityId, () => []).add(c.id);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    for (final MapEntry(key: customerId, value: changeIds)
        in idsByCustomer.entries) {
      final customer = await (_db.select(
        _db.customerTable,
      )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
      if (customer == null) {
        rejections.add(LocalRejection(changeIds, deletionNotSynced));
        continue;
      }
      records.add(
        PushRecord(
          uuid: customerId,
          body: await _body(customer),
          changeIds: changeIds,
        ),
      );
    }
    return PushPlan(records: records, rejections: rejections);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.customerTable)
          ..where((t) => t.customerId.equals(record.uuid)))
        .write(CustomerTableCompanion(serverId: Value(serverId)));
  }

  Future<Json> _body(CustomerTableData customer) async {
    final addresses =
        await (_db.select(_db.customerAddressTable)
              ..where(
                (t) =>
                    t.customerId.equals(customer.customerId) &
                    t.enabled.equals(true),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.isPrimary),
                (t) => OrderingTerm.asc(t.createdAt),
              ])
              ..limit(1))
            .get();
    final address = addresses.isEmpty ? null : addresses.first;

    var modifiedAt = customer.lastModifiedDate;
    if (address != null && address.lastModifiedDate.isAfter(modifiedAt)) {
      modifiedAt = address.lastModifiedDate;
    }

    return {
      'uuid': customer.customerId,
      'server_id': ?customer.serverId,
      'name': customer.name,
      'phone_number': customer.phone,
      'modified_at': modifiedAt.toUtc().toIso8601String(),
      'address': {
        'street': address?.street,
        'apartment': address?.apartment,
        // The server stores the floor as a number; free text cannot travel.
        'floor': address?.floor == null
            ? null
            : int.tryParse(address!.floor!.trim()),
        'visual_reference': address?.visualReference,
        'neighborhood': address?.neighborhood,
        'latitude': address?.latitude,
        'longitude': address?.longitude,
      },
    };
  }
}
