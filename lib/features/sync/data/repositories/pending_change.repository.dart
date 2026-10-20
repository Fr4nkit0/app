import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// The single, ordered queue of local changes waiting to be synced.
abstract class PendingChangeRepository {
  /// Appends a change to the queue. Call it inside the same transaction that
  /// writes the record so both land together or not at all.
  Future<void> enqueue({
    required PendingEntity entity,
    required String entityId,
    required PendingAction action,
    Map<String, dynamic>? payload,
  });

  /// Changes not yet sent, oldest first.
  Future<List<PendingChange>> getPending();

  /// Changes the server refused, oldest first.
  Future<List<PendingChange>> getRejected();

  Future<int> countPending();

  Stream<int> watchPendingCount();

  /// pending → sent. Changes in any other state are left untouched.
  Future<void> markSent(List<int> ids);

  /// pending → rejected with [reason]. Other states are left untouched.
  Future<void> markRejected(int id, String reason);
}

class DriftPendingChangeRepository implements PendingChangeRepository {
  DriftPendingChangeRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> enqueue({
    required PendingEntity entity,
    required String entityId,
    required PendingAction action,
    Map<String, dynamic>? payload,
  }) async {
    await _db
        .into(_db.pendingChangeTable)
        .insert(
          PendingChangeTableCompanion.insert(
            entity: entity.wireName,
            entityId: entityId,
            action: action.wireName,
            payload: Value(payload == null ? null : jsonEncode(payload)),
          ),
        );
  }

  @override
  Future<List<PendingChange>> getPending() => _byStatus(PendingStatus.pending);

  @override
  Future<List<PendingChange>> getRejected() =>
      _byStatus(PendingStatus.rejected);

  @override
  Future<int> countPending() => _pendingCount().getSingle();

  @override
  Stream<int> watchPendingCount() => _pendingCount().watchSingle();

  @override
  Future<void> markSent(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.pendingChangeTable)..where(
          (t) =>
              t.pendingChangeId.isIn(ids) &
              t.status.equals(PendingStatus.pending.wireName),
        ))
        .write(_transition(PendingStatus.sent));
  }

  @override
  Future<void> markRejected(int id, String reason) async {
    await (_db.update(_db.pendingChangeTable)..where(
          (t) =>
              t.pendingChangeId.equals(id) &
              t.status.equals(PendingStatus.pending.wireName),
        ))
        .write(_transition(PendingStatus.rejected, reason: reason));
  }

  Selectable<int> _pendingCount() {
    final count = _db.pendingChangeTable.pendingChangeId.count();
    return (_db.selectOnly(_db.pendingChangeTable)
          ..addColumns([count])
          ..where(
            _db.pendingChangeTable.status.equals(
              PendingStatus.pending.wireName,
            ),
          ))
        .map((row) => row.read(count) ?? 0);
  }

  Future<List<PendingChange>> _byStatus(PendingStatus status) async {
    final rows =
        await (_db.select(_db.pendingChangeTable)
              ..where((t) => t.status.equals(status.wireName))
              ..orderBy([(t) => OrderingTerm.asc(t.pendingChangeId)]))
            .get();
    return rows.map(_rowToChange).toList();
  }

  PendingChangeTableCompanion _transition(
    PendingStatus status, {
    String? reason,
  }) => PendingChangeTableCompanion(
    status: Value(status.wireName),
    rejectionReason: Value(reason),
    lastModifiedDate: Value(DateTime.now()),
  );

  PendingChange _rowToChange(PendingChangeTableData row) => PendingChange(
    id: row.pendingChangeId,
    entity: PendingEntity.fromWire(row.entity),
    entityId: row.entityId,
    action: PendingAction.fromWire(row.action),
    payload: row.payload == null
        ? null
        : jsonDecode(row.payload!) as Map<String, dynamic>,
    status: PendingStatus.fromWire(row.status),
    rejectionReason: row.rejectionReason,
    createdAt: row.createdAt,
  );
}
