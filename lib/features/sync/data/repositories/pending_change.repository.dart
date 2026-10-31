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

  /// The most recent queue row (highest id) for the record, or null when it
  /// has none.
  Stream<PendingChange?> watchLatestFor(PendingEntity entity, String entityId);

  /// pending → sent. Changes in any other state are left untouched.
  Future<void> markSent(List<int> ids);

  /// pending → rejected with [reason]. Other states are left untouched.
  Future<void> markRejected(int id, String reason);

  /// pending → outdated: the server applied none of it. Other states are
  /// left untouched.
  Future<void> markOutdated(List<int> ids);

  /// pending → awaiting approval: the server holds it until the admin
  /// decides. Other states are left untouched.
  Future<void> markAwaitingApproval(List<int> ids);

  /// rejected or outdated → dismissed, keeping the row and its reason. Other
  /// states are left untouched.
  Future<void> dismiss(int id);

  /// Records on the rejected changes of the record that do not have it yet
  /// what the server refused ([PendingChange.rejectedValuesKey]; an edit
  /// that names its fields keeps only those) and what the device did with
  /// the row ([PendingChange.rollbackKey]).
  Future<void> recordRejection({
    required PendingEntity entity,
    required String entityId,
    required Map<String, dynamic> refused,
    required RejectionRollback rollback,
  });
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
  Stream<PendingChange?> watchLatestFor(PendingEntity entity, String entityId) {
    final query = _db.select(_db.pendingChangeTable)
      ..where(
        (t) => t.entity.equals(entity.wireName) & t.entityId.equals(entityId),
      )
      ..orderBy([(t) => OrderingTerm.desc(t.pendingChangeId)])
      ..limit(1);
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _rowToChange(row),
    );
  }

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

  @override
  Future<void> markOutdated(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.pendingChangeTable)..where(
          (t) =>
              t.pendingChangeId.isIn(ids) &
              t.status.equals(PendingStatus.pending.wireName),
        ))
        .write(_transition(PendingStatus.outdated));
  }

  @override
  Future<void> markAwaitingApproval(List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.pendingChangeTable)..where(
          (t) =>
              t.pendingChangeId.isIn(ids) &
              t.status.equals(PendingStatus.pending.wireName),
        ))
        .write(_transition(PendingStatus.awaitingApproval));
  }

  @override
  Future<void> dismiss(int id) async {
    await (_db.update(_db.pendingChangeTable)..where(
          (t) =>
              t.pendingChangeId.equals(id) &
              t.status.isIn([
                PendingStatus.rejected.wireName,
                PendingStatus.outdated.wireName,
              ]),
        ))
        .write(
          PendingChangeTableCompanion(
            status: Value(PendingStatus.dismissed.wireName),
            lastModifiedDate: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<void> recordRejection({
    required PendingEntity entity,
    required String entityId,
    required Map<String, dynamic> refused,
    required RejectionRollback rollback,
  }) async {
    final rows =
        await (_db.select(_db.pendingChangeTable)..where(
              (t) =>
                  t.entity.equals(entity.wireName) &
                  t.entityId.equals(entityId) &
                  t.status.equals(PendingStatus.rejected.wireName),
            ))
            .get();
    for (final change in rows.map(_rowToChange)) {
      if (change.rollback != null) continue;
      final fields = change.changedFields;
      final values = fields == null
          ? refused
          : {
              for (final MapEntry(:key, :value) in refused.entries)
                if (fields.contains(key)) key: value,
            };
      await (_db.update(
        _db.pendingChangeTable,
      )..where((t) => t.pendingChangeId.equals(change.id))).write(
        PendingChangeTableCompanion(
          payload: Value(
            jsonEncode({
              ...?change.payload,
              PendingChange.rejectedValuesKey: values.isEmpty
                  ? refused
                  : values,
              PendingChange.rollbackKey: rollback.wireName,
            }),
          ),
        ),
      );
    }
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
