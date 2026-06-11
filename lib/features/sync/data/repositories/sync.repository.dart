import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/audit_log_entry.dart';

abstract class SyncRepository {
  /// Records a local mutation to the audit queue for later sync.
  Future<void> logMutation({
    required String tableName,
    required String recordId,
    required String action,
    String? payload,
  });

  /// Returns all log entries that have not yet been synced to the backend,
  /// ordered by [createdAt] ascending (oldest first).
  Future<List<AuditLogEntry>> getUnsyncedLogs();

  /// Marks the given log entries as synced by their IDs.
  Future<void> markAsSynced(List<String> logIds);
}

class DriftSyncRepository implements SyncRepository {
  DriftSyncRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> logMutation({
    required String tableName,
    required String recordId,
    required String action,
    String? payload,
  }) async {
    await _db.into(_db.auditLogTable).insert(
          AuditLogTableCompanion.insert(
            tableNameColumn: tableName,
            recordId: recordId,
            action: action,
            payload:
                payload != null ? Value(payload) : const Value.absent(),
          ),
        );
  }

  @override
  Future<List<AuditLogEntry>> getUnsyncedLogs() async {
    final rows = await (_db.select(_db.auditLogTable)
          ..where((t) => t.enabled.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_rowToEntry).toList();
  }

  @override
  Future<void> markAsSynced(List<String> logIds) async {
    if (logIds.isEmpty) return;
    await (_db.update(_db.auditLogTable)
          ..where((t) => t.auditLogId.isIn(logIds)))
        .write(const AuditLogTableCompanion(enabled: Value(false)));
  }

  AuditLogEntry _rowToEntry(AuditLogTableData row) => AuditLogEntry(
        id: row.auditLogId,
        tableName: row.tableNameColumn,
        recordId: row.recordId,
        action: row.action,
        payload: row.payload,
        createdAt: row.createdAt,
        synced: !row.enabled,
      );
}
