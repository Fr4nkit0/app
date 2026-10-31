import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';
import '../data/repositories/server_shadow.dart';
import '../domain/models/pending_change.dart';
import 'entity_pusher.dart';

/// Customers created or edited on the street.
///
/// Every change of the same customer collapses into one record built from
/// the current local row. A customer the server does not know yet travels
/// whole. An edit of a known customer carries only the fields its queued
/// changes name ([PendingChange.changedFields]) with their latest values:
/// the server merges it field by field, so a field the driver did not touch
/// never overwrites the office's newer value. An edit queued by an older
/// version, which does not name its fields, still travels whole.
///
/// The server writes the record's address onto whichever address it holds
/// as primary, and customers are processed before `customer_addresses`. So
/// a customer the server already knows waits while any of its address
/// changes is unsent: once those are in, the server's primary is the local
/// one again.
///
/// A rejected customer goes back to the server's values (the server row the
/// answer carries, or the last ones known), or, when the server never stored
/// it, is deleted unless other records reference it.
class CustomerPusher implements EntityPusher, RejectionAware {
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
    final changesByCustomer = <String, List<PendingChange>>{};
    for (final c in changes) {
      changesByCustomer.putIfAbsent(c.entityId, () => []).add(c);
    }

    final records = <PushRecord>[];
    final rejections = <LocalRejection>[];
    final settled = <int>[];
    for (final MapEntry(key: customerId, value: ofCustomer)
        in changesByCustomer.entries) {
      final changeIds = [for (final c in ofCustomer) c.id];
      final customer = await (_db.select(
        _db.customerTable,
      )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
      if (customer == null) {
        rejections.add(LocalRejection(changeIds, deletionNotSynced));
        continue;
      }
      if (customer.serverId != null &&
          await _hasPendingAddressChanges(customerId)) {
        continue;
      }
      final fields = PendingChange.changedFieldsOf(ofCustomer);
      final body = customer.serverId == null || fields == null
          ? await _body(customer)
          : await _editBody(customer, fields);
      if (body == null) {
        // Nothing left to tell the server.
        settled.addAll(changeIds);
        continue;
      }
      records.add(
        PushRecord(uuid: customerId, body: body, changeIds: changeIds),
      );
    }
    return PushPlan(records: records, rejections: rejections, settled: settled);
  }

  @override
  Future<void> applyAccepted(PushRecord record, int serverId) async {
    await (_db.update(_db.customerTable)
          ..where((t) => t.customerId.equals(record.uuid)))
        .write(CustomerTableCompanion(serverId: Value(serverId)));
  }

  Future<bool> _hasPendingAddressChanges(String customerId) async {
    final query =
        _db.select(_db.pendingChangeTable).join([
            innerJoin(
              _db.customerAddressTable,
              _db.customerAddressTable.addressId.equalsExp(
                _db.pendingChangeTable.entityId,
              ),
            ),
          ])
          ..where(
            _db.pendingChangeTable.entity.equals(
                  PendingEntity.customerAddress.wireName,
                ) &
                _db.pendingChangeTable.status.equals(
                  PendingStatus.pending.wireName,
                ) &
                _db.customerAddressTable.customerId.equals(customerId),
          )
          ..limit(1);
    return (await query.get()).isNotEmpty;
  }

  /// The floor travels as typed ("PB", "3"); a blank floor travels as null.
  static String? floorOf(String? floor) {
    final trimmed = floor?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// The address fields a customer record carries, as the server names
  /// them under `address`.
  static Json addressValues(CustomerAddressTableData? address) => {
    'street': address?.street,
    'apartment': address?.apartment,
    'floor': floorOf(address?.floor),
    'visual_reference': address?.visualReference,
    'neighborhood': address?.neighborhood,
    'latitude': address?.latitude,
    'longitude': address?.longitude,
  };

  static const _addressPrefix = 'address.';

  /// The edit of a customer the server knows: [fields] with their current
  /// values, or null when none of them has anything to send.
  Future<Json?> _editBody(
    CustomerTableData customer,
    Set<String> fields,
  ) async {
    final addressFields = {
      for (final f in fields)
        if (f.startsWith(_addressPrefix)) f.substring(_addressPrefix.length),
    };
    final address = addressFields.isEmpty
        ? null
        : await _pushedAddress(customer.customerId);
    final values = addressValues(address);
    final changes = <String, dynamic>{
      if (fields.contains('name')) 'name': customer.name,
      if (fields.contains('phone_number')) 'phone_number': customer.phone,
      // Drivers can only disable; re-enabling is up to the office.
      if (fields.contains('enabled') && !customer.enabled) 'enabled': false,
      if (address != null)
        'address': {
          'uuid': address.addressId,
          for (final f in addressFields)
            if (values.containsKey(f)) f: values[f],
        },
    };
    if (changes.isEmpty) return null;
    return {
      'uuid': customer.customerId,
      'server_id': customer.serverId,
      'modified_at': _modifiedAt(customer, address),
      ...changes,
    };
  }

  @override
  Future<void> applyRejected(String localId, {Json? current}) async {
    final customer = await (_db.select(
      _db.customerTable,
    )..where((t) => t.customerId.equals(localId))).getSingleOrNull();
    if (customer == null) return;
    final address = await _pushedAddress(localId);
    await ServerShadow(_db).rollBackRejected(
      entity,
      localId,
      refused: {
        'name': customer.name,
        'phone_number': customer.phone,
        'enabled': customer.enabled,
        if (address != null)
          for (final MapEntry(:key, :value) in addressValues(address).entries)
            if (key != 'latitude' && key != 'longitude')
              '$_addressPrefix$key': value,
      },
      stored: customer.serverId != null,
      current: current,
      delete: () => _deleteUnreferenced(localId),
    );
  }

  /// Deletes a customer the server never stored, with its addresses and
  /// preferences, unless a record of the day or a balance references it.
  Future<bool> _deleteUnreferenced(String customerId) async {
    final referenced = await _db
        .customSelect(
          'SELECT 1 FROM sales WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM payments WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM visits WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM container_movements WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM route_stops WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM customer_agreements WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM customer_account_entries '
          'WHERE customer_id = ?1 '
          // Balances belong to their ledgers; one that exists keeps the
          // customer.
          'UNION ALL SELECT 1 FROM customer_balances WHERE customer_id = ?1 '
          'UNION ALL SELECT 1 FROM customer_container_balances '
          'WHERE customer_id = ?1 LIMIT 1',
          variables: [Variable.withString(customerId)],
        )
        .get();
    if (referenced.isNotEmpty) return false;
    await (_db.delete(
      _db.customerAddressTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerPreferenceTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    await (_db.delete(
      _db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).go();
    return true;
  }

  Future<CustomerAddressTableData?> _pushedAddress(String customerId) =>
      pushedAddress(_db, customerId);

  /// The address the record carries: the primary, or the oldest enabled
  /// one when there is no primary.
  static Future<CustomerAddressTableData?> pushedAddress(
    AppDatabase db,
    String customerId,
  ) async {
    final addresses =
        await (db.select(db.customerAddressTable)
              ..where(
                (t) => t.customerId.equals(customerId) & t.enabled.equals(true),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.isPrimary),
                (t) => OrderingTerm.asc(t.createdAt),
              ])
              ..limit(1))
            .get();
    return addresses.isEmpty ? null : addresses.first;
  }

  /// The latest local modification of what the record carries.
  static String _modifiedAt(
    CustomerTableData customer,
    CustomerAddressTableData? address,
  ) {
    var modifiedAt = customer.lastModifiedDate;
    if (address != null && address.lastModifiedDate.isAfter(modifiedAt)) {
      modifiedAt = address.lastModifiedDate;
    }
    return modifiedAt.toUtc().toIso8601String();
  }

  Future<Json> _body(CustomerTableData customer) async {
    final address = await _pushedAddress(customer.customerId);
    return {
      'uuid': customer.customerId,
      'server_id': ?customer.serverId,
      'name': customer.name,
      'phone_number': customer.phone,
      // Drivers can only disable; re-enabling is up to the office, so an
      // enabled customer leaves the server's flag as it is.
      if (!customer.enabled) 'enabled': false,
      'modified_at': _modifiedAt(customer, address),
      'address': {
        // Lets a later address edit reach the same server row.
        'uuid': address?.addressId,
        ...addressValues(address),
      },
    };
  }
}
