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

  /// The app no longer deletes customers; a delete still queued by an older
  /// version finds no local row and is rejected with this reason.
  static const deletionNotSynced =
      'La baja de clientes no se sincroniza con el servidor.';

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

  /// The floor travels as typed ("PB", "3"); a blank floor travels as null.
  static String? _floor(String? floor) {
    final trimmed = floor?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
        // Lets a later address edit reach the same server row.
        'uuid': address?.addressId,
        'street': address?.street,
        'apartment': address?.apartment,
        'floor': _floor(address?.floor),
        'visual_reference': address?.visualReference,
        'neighborhood': address?.neighborhood,
        'latitude': address?.latitude,
        'longitude': address?.longitude,
      },
    };
  }
}
