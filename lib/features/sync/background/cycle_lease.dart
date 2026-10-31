import 'package:drift/drift.dart';

import '../../../core/services/database.helper.dart';

/// Cross-isolate "one cycle at a time" lock stored in the shared database.
///
/// The foreground app and a background job run in different isolates with
/// their own memory, so the engine's in-memory single-flight guard cannot see
/// across them. Both open the same SQLite file, so the lock lives there: one
/// `sync_state` row holding `<expiresAtEpochMs>|<owner>`.
///
/// The lease expires after [ttl] unless its holder renews it, so a process
/// killed mid-cycle (the OS stops background work without warning, the driver
/// swipes the app away) blocks syncing for at most [ttl]. A live holder
/// renews it on a heartbeat for as long as its cycle runs.
///
/// Every process instance uses its own [owner]: a relaunched app must not
/// take over the lease of an older instance that is still mid-cycle.
class CycleLease {
  CycleLease(
    this._db, {
    required this.owner,
    this.ttl = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const key = 'cycle_lease';

  final AppDatabase _db;
  final String owner;
  final Duration ttl;
  final DateTime Function() _now;

  /// Takes the lease when it is free, expired or already ours. A single
  /// conditional upsert keeps the check and the write atomic across
  /// connections.
  Future<bool> acquire() async {
    final now = _now().millisecondsSinceEpoch;
    final value = '${now + ttl.inMilliseconds}|$owner';
    await _db.customUpdate(
      'INSERT INTO sync_state (key, value) VALUES (?1, ?2) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value '
      'WHERE CAST(substr(sync_state.value, 1, '
      'instr(sync_state.value, \'|\') - 1) AS INTEGER) <= ?3 '
      'OR substr(sync_state.value, instr(sync_state.value, \'|\') + 1) = ?4',
      variables: [
        Variable.withString(key),
        Variable.withString(value),
        Variable.withInt(now),
        Variable.withString(owner),
      ],
      updates: {_db.syncStateTable},
      updateKind: UpdateKind.update,
    );
    final stored = await (_db.select(
      _db.syncStateTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return stored?.value == value;
  }

  /// Pushes the expiry of a lease this owner still holds [ttl] ahead.
  Future<void> renew() {
    final expiresAt = _now().millisecondsSinceEpoch + ttl.inMilliseconds;
    return _db.customUpdate(
      'UPDATE sync_state SET value = ?1 WHERE key = ?2 '
      'AND substr(value, instr(value, \'|\') + 1) = ?3',
      variables: [
        Variable.withString('$expiresAt|$owner'),
        Variable.withString(key),
        Variable.withString(owner),
      ],
      updates: {_db.syncStateTable},
      updateKind: UpdateKind.update,
    );
  }

  /// Time left until the current lease expires, or null when it is free.
  Future<Duration?> remaining() async {
    final stored = await (_db.select(
      _db.syncStateTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    final expiresAt = int.tryParse(stored?.value.split('|').first ?? '');
    if (expiresAt == null) return null;
    final left = expiresAt - _now().millisecondsSinceEpoch;
    return left > 0 ? Duration(milliseconds: left) : null;
  }

  /// Frees the lease if this owner still holds it.
  Future<void> release() => _db.customUpdate(
    'DELETE FROM sync_state WHERE key = ?1 '
    'AND substr(value, instr(value, \'|\') + 1) = ?2',
    variables: [Variable.withString(key), Variable.withString(owner)],
    updates: {_db.syncStateTable},
    updateKind: UpdateKind.delete,
  );
}
