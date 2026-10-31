import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/services/database.helper.dart';
import '../../domain/models/pending_change.dart';
import '../../push/customer_pusher.dart';
import '../../push/entity_pusher.dart' show Json;
import 'pending_change.repository.dart';

/// The last values the server is known to hold for a customer, address or
/// preference the driver edited, so a rejected or outdated answer can put
/// them back on the device.
///
/// Kept in `sync_state` under `shadow:<entity>:<localId>` (`entity` is the
/// [PendingEntity.wireName]) as a JSON object of the row's synced columns by
/// wire name, in the local format:
///
/// - preference: `day_of_week`, `time_window_start`, `time_window_end`,
///   `enabled`;
/// - address: `street`, `apartment`, `floor`, `visual_reference`,
///   `neighborhood`, `latitude`, `longitude`, `is_primary`, `enabled`;
/// - customer: `name`, `phone_number`, `enabled` and, under `address`, the
///   `uuid` of the address its push carries with that address's fields;
///   only the `uuid` when the address had a change of its own pending, until
///   the pull brings its server values.
///
/// Captured from the row before its first queued edit (its values then are
/// the server's as of the last download) and refreshed when the pull skips
/// the row because of that edit. Forgotten once the row has no pending
/// change left.
class ServerShadow {
  ServerShadow(this._db) : _queue = DriftPendingChangeRepository(_db);

  static const keyPrefix = 'shadow:';

  final AppDatabase _db;
  final PendingChangeRepository _queue;

  static String keyOf(PendingEntity entity, String localId) =>
      '$keyPrefix${entity.wireName}:$localId';

  /// The kept server values of the row, or null when there are none.
  Future<Json?> read(PendingEntity entity, String localId) async {
    final row = await (_db.select(
      _db.syncStateTable,
    )..where((t) => t.key.equals(keyOf(entity, localId)))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.value) as Json;
  }

  /// Call before writing a local edit of the row, inside the same unit of
  /// work. Keeps the row's current values when the server knows the row and
  /// no earlier change of it is still pending; otherwise the values from
  /// before that earlier change are already kept.
  Future<void> captureBeforeEdit(PendingEntity entity, String localId) async {
    if (await _hasPending(entity, localId)) return;
    final values = switch (entity) {
      PendingEntity.customer => await _customerValues(localId),
      PendingEntity.customerAddress => await _addressValues(localId),
      PendingEntity.customerPreference => await _preferenceValues(localId),
      _ => null,
    };
    if (values == null) {
      await _delete(keyOf(entity, localId));
    } else {
      await _put(keyOf(entity, localId), values);
    }
  }

  /// The server copy of a customer the pull did not apply because of its
  /// unsent changes.
  Future<void> storePulledCustomer(
    String customerId,
    CustomerTableCompanion fields,
  ) => _merge(keyOf(PendingEntity.customer, customerId), _customerJson(fields));

  /// The server copy of an address the pull did not apply. Kept for the
  /// address when [ownChange] (it has an unsent change of its own), and for
  /// its customer when it is the address that customer's kept values carry.
  Future<void> storePulledAddress(
    String customerId,
    String addressId,
    CustomerAddressTableCompanion fields, {
    required bool ownChange,
  }) async {
    final values = _addressJson(fields);
    if (ownChange) {
      await _merge(keyOf(PendingEntity.customerAddress, addressId), values);
    }
    final customerKey = keyOf(PendingEntity.customer, customerId);
    final customer = await read(PendingEntity.customer, customerId);
    final carried = customer?['address'];
    if (carried is Map && carried['uuid'] == addressId) {
      await _put(customerKey, {
        ...customer!,
        'address': {
          ...carried,
          for (final MapEntry(:key, :value) in values.entries)
            if (_carriedAddressKeys.contains(key)) key: value,
        },
      });
    }
  }

  /// The server copy of a preference the pull did not apply because of its
  /// unsent change.
  Future<void> storePulledPreference(
    String preferenceId,
    CustomerPreferenceTableCompanion fields,
  ) => _merge(
    keyOf(PendingEntity.customerPreference, preferenceId),
    _preferenceJson(fields),
  );

  /// Writes the kept server values back onto the row; false when none are
  /// kept.
  Future<bool> restore(PendingEntity entity, String localId) async {
    final values = await read(entity, localId);
    if (values == null) return false;
    switch (entity) {
      case PendingEntity.customer:
        await (_db.update(_db.customerTable)
              ..where((t) => t.customerId.equals(localId)))
            .write(_customerFields(values));
        final address = values['address'];
        // An address with a newer change of its own keeps it.
        if (address is Map &&
            address['uuid'] is String &&
            address.keys.any(_carriedAddressKeys.contains) &&
            !await _hasPending(
              PendingEntity.customerAddress,
              address['uuid'] as String,
            )) {
          await (_db.update(_db.customerAddressTable)
                ..where((t) => t.addressId.equals(address['uuid'] as String)))
              .write(_addressFields(Map<String, dynamic>.from(address)));
        }
      case PendingEntity.customerAddress:
        await (_db.update(_db.customerAddressTable)
              ..where((t) => t.addressId.equals(localId)))
            .write(_addressFields(values));
      case PendingEntity.customerPreference:
        await (_db.update(_db.customerPreferenceTable)
              ..where((t) => t.customerPreferenceId.equals(localId)))
            .write(_preferenceFields(values));
      default:
        return false;
    }
    return true;
  }

  /// Restores the row unless a newer change of it waits to be sent.
  Future<bool> restoreIfSettled(PendingEntity entity, String localId) async {
    if (await _hasPending(entity, localId)) return false;
    return restore(entity, localId);
  }

  /// Rolls back the row of a rejected change and records on its rejected
  /// changes the [refused] values (by wire name) and what was done:
  ///
  /// - a newer change of the row waits to be sent: the row is kept;
  /// - the server never stored the row ([stored] is false): [delete] removes
  ///   it, or returns false to keep it;
  /// - otherwise the kept server values are written back, when there are
  ///   any.
  Future<RejectionRollback> rollBackRejected(
    PendingEntity entity,
    String localId, {
    required Json refused,
    required bool stored,
    required Future<bool> Function() delete,
  }) async {
    final RejectionRollback rollback;
    if (await _hasPending(entity, localId)) {
      rollback = RejectionRollback.kept;
    } else if (!stored) {
      rollback = await delete()
          ? RejectionRollback.deleted
          : RejectionRollback.kept;
    } else {
      rollback = await restore(entity, localId)
          ? RejectionRollback.restored
          : RejectionRollback.kept;
    }
    await _queue.recordRejection(
      entity: entity,
      entityId: localId,
      refused: refused,
      rollback: rollback,
    );
    return rollback;
  }

  /// Forgets the kept values of every row with no pending change left.
  Future<void> clearSettled() => _db.customUpdate(
    'DELETE FROM sync_state WHERE substr(key, 1, ?1) = ?2 AND NOT EXISTS ('
    'SELECT 1 FROM pending_changes c WHERE c.status = ?3 '
    "AND ?2 || c.entity || ':' || c.entity_id = sync_state.key)",
    variables: [
      Variable.withInt(keyPrefix.length),
      Variable.withString(keyPrefix),
      Variable.withString(PendingStatus.pending.wireName),
    ],
    updates: {_db.syncStateTable},
    updateKind: UpdateKind.delete,
  );

  Future<bool> _hasPending(PendingEntity entity, String localId) async =>
      (await (_db.select(_db.pendingChangeTable)
                ..where(
                  (t) =>
                      t.entity.equals(entity.wireName) &
                      t.entityId.equals(localId) &
                      t.status.equals(PendingStatus.pending.wireName),
                )
                ..limit(1))
              .get())
          .isNotEmpty;

  Future<Json?> _customerValues(String customerId) async {
    final customer = await (_db.select(
      _db.customerTable,
    )..where((t) => t.customerId.equals(customerId))).getSingleOrNull();
    if (customer?.serverId == null) return null;
    final address = await CustomerPusher.pushedAddress(_db, customerId);
    final carried = address != null && address.serverId != null;
    // An address with a pending change of its own does not hold the
    // server's values; the pull fills them in.
    final addressValues =
        carried &&
            !await _hasPending(PendingEntity.customerAddress, address.addressId)
        ? _addressJson(address.toCompanion(false))
        : {};
    return {
      ..._customerJson(customer!.toCompanion(false)),
      if (carried)
        'address': {
          'uuid': address.addressId,
          for (final MapEntry(:key, :value) in addressValues.entries)
            if (_carriedAddressKeys.contains(key)) key: value,
        },
    };
  }

  Future<Json?> _addressValues(String addressId) async {
    final address = await (_db.select(
      _db.customerAddressTable,
    )..where((t) => t.addressId.equals(addressId))).getSingleOrNull();
    if (address?.serverId == null) return null;
    return _addressJson(address!.toCompanion(false));
  }

  Future<Json?> _preferenceValues(String preferenceId) async {
    final preference =
        await (_db.select(_db.customerPreferenceTable)
              ..where((t) => t.customerPreferenceId.equals(preferenceId)))
            .getSingleOrNull();
    if (preference?.serverId == null) return null;
    return _preferenceJson(preference!.toCompanion(false));
  }

  Future<void> _merge(String key, Json values) async {
    final row = await (_db.select(
      _db.syncStateTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    await _put(key, {
      if (row != null) ...jsonDecode(row.value) as Json,
      ...values,
    });
  }

  Future<void> _put(String key, Json values) => _db
      .into(_db.syncStateTable)
      .insertOnConflictUpdate(
        SyncStateTableCompanion.insert(key: key, value: jsonEncode(values)),
      );

  Future<void> _delete(String key) =>
      (_db.delete(_db.syncStateTable)..where((t) => t.key.equals(key))).go();

  /// The address fields a customer edit can change.
  static const _carriedAddressKeys = {
    'street',
    'apartment',
    'floor',
    'visual_reference',
    'neighborhood',
    'latitude',
    'longitude',
  };

  static Json _customerJson(CustomerTableCompanion c) => {
    if (c.name.present) 'name': c.name.value,
    if (c.phone.present) 'phone_number': c.phone.value,
    if (c.enabled.present) 'enabled': c.enabled.value,
  };

  static CustomerTableCompanion _customerFields(Json j) =>
      CustomerTableCompanion(
        name: _value(j, 'name'),
        phone: _value(j, 'phone_number'),
        enabled: _value(j, 'enabled'),
      );

  static Json _addressJson(CustomerAddressTableCompanion c) => {
    if (c.street.present) 'street': c.street.value,
    if (c.apartment.present) 'apartment': c.apartment.value,
    if (c.floor.present) 'floor': c.floor.value,
    if (c.visualReference.present) 'visual_reference': c.visualReference.value,
    if (c.neighborhood.present) 'neighborhood': c.neighborhood.value,
    if (c.latitude.present) 'latitude': c.latitude.value,
    if (c.longitude.present) 'longitude': c.longitude.value,
    if (c.isPrimary.present) 'is_primary': c.isPrimary.value,
    if (c.enabled.present) 'enabled': c.enabled.value,
  };

  static CustomerAddressTableCompanion _addressFields(Json j) =>
      CustomerAddressTableCompanion(
        street: _value(j, 'street'),
        apartment: _value(j, 'apartment'),
        floor: _value(j, 'floor'),
        visualReference: _value(j, 'visual_reference'),
        neighborhood: _value(j, 'neighborhood'),
        latitude: _double(j, 'latitude'),
        longitude: _double(j, 'longitude'),
        isPrimary: _value(j, 'is_primary'),
        enabled: _value(j, 'enabled'),
      );

  static Json _preferenceJson(CustomerPreferenceTableCompanion c) => {
    if (c.dayOfWeek.present) 'day_of_week': c.dayOfWeek.value,
    if (c.timeWindowStart.present) 'time_window_start': c.timeWindowStart.value,
    if (c.timeWindowEnd.present) 'time_window_end': c.timeWindowEnd.value,
    if (c.enabled.present) 'enabled': c.enabled.value,
  };

  static CustomerPreferenceTableCompanion _preferenceFields(Json j) =>
      CustomerPreferenceTableCompanion(
        dayOfWeek: _value(j, 'day_of_week'),
        timeWindowStart: _value(j, 'time_window_start'),
        timeWindowEnd: _value(j, 'time_window_end'),
        enabled: _value(j, 'enabled'),
      );

  static Value<T> _value<T>(Json j, String key) =>
      j.containsKey(key) ? Value(j[key] as T) : const Value.absent();

  static Value<double?> _double(Json j, String key) => j.containsKey(key)
      ? Value((j[key] as num?)?.toDouble())
      : const Value.absent();
}
