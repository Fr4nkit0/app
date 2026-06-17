import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/sync.repository.dart';

void main() {
  late AppDatabase db;
  late DriftSyncRepository sut;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftSyncRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // logMutation
  // ──────────────────────────────────────────────────────────────────────────

  group('logMutation', () {
    test('inserts an audit log entry with correct fields', () async {
      await sut.logMutation(
        tableName: 'payments',
        recordId: 'pay-1',
        action: 'INSERT',
        payload: '{"amount": 500}',
      );

      final rows = await db.select(db.auditLogTable).get();
      expect(rows.length, 1);
      expect(rows.first.tableNameColumn, 'payments');
      expect(rows.first.recordId, 'pay-1');
      expect(rows.first.action, 'INSERT');
      expect(rows.first.payload, '{"amount": 500}');
    });

    test('entry starts as pending sync (enabled = true)', () async {
      await sut.logMutation(
        tableName: 'sales',
        recordId: 'sale-1',
        action: 'INSERT',
      );

      final row = await db.select(db.auditLogTable).getSingle();
      expect(row.enabled, isTrue);
    });

    test('inserts entry with null payload when payload is omitted', () async {
      await sut.logMutation(
        tableName: 'visits',
        recordId: 'visit-1',
        action: 'UPDATE',
      );

      final row = await db.select(db.auditLogTable).getSingle();
      expect(row.payload, isNull);
    });

    test('inserts multiple entries independently', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'sales', recordId: 's-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'visits', recordId: 'v-1', action: 'UPDATE');

      final rows = await db.select(db.auditLogTable).get();
      expect(rows.length, 3);
    });

    test('each entry receives a unique id', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-2', action: 'INSERT');

      final rows = await db.select(db.auditLogTable).get();
      final ids = rows.map((r) => r.auditLogId).toSet();
      expect(ids.length, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // getUnsyncedLogs
  // ──────────────────────────────────────────────────────────────────────────

  group('getUnsyncedLogs', () {
    test('returns empty list when there are no log entries', () async {
      final logs = await sut.getUnsyncedLogs();
      expect(logs, isEmpty);
    });

    test('returns all entries when none have been synced', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'sales', recordId: 's-1', action: 'INSERT');

      final logs = await sut.getUnsyncedLogs();
      expect(logs.length, 2);
    });

    test('returns empty list when all entries are marked as synced', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');

      final all = await sut.getUnsyncedLogs();
      await sut.markAsSynced(all.map((e) => e.id).toList());

      final remaining = await sut.getUnsyncedLogs();
      expect(remaining, isEmpty);
    });

    test('returns only unsynced entries in mixed-state log', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-2', action: 'INSERT');

      final first = await sut.getUnsyncedLogs();
      await sut.markAsSynced([first.first.id]);

      final remaining = await sut.getUnsyncedLogs();
      expect(remaining.length, 1);
      expect(remaining.first.recordId, 'p-2');
    });

    test('maps entry fields correctly', () async {
      await sut.logMutation(
        tableName: 'customers',
        recordId: 'cust-99',
        action: 'UPDATE',
        payload: '{"name":"Test"}',
      );

      final logs = await sut.getUnsyncedLogs();
      final entry = logs.first;

      expect(entry.id, isNotNull);
      expect(entry.tableName, 'customers');
      expect(entry.recordId, 'cust-99');
      expect(entry.action, 'UPDATE');
      expect(entry.payload, '{"name":"Test"}');
      expect(entry.synced, isFalse);
    });

    test('returns entries ordered by createdAt ascending', () async {
      // Insert with explicit timestamps via companion to guarantee order.
      final earlier = DateTime(2024, 1, 1, 10, 0, 0);
      final later = DateTime(2024, 1, 1, 12, 0, 0);

      await db.into(db.auditLogTable).insert(
            AuditLogTableCompanion.insert(
              tableNameColumn: 'payments',
              recordId: 'p-old',
              action: 'INSERT',
              createdAt: drift.Value(earlier),
            ),
          );
      await db.into(db.auditLogTable).insert(
            AuditLogTableCompanion.insert(
              tableNameColumn: 'payments',
              recordId: 'p-new',
              action: 'INSERT',
              createdAt: drift.Value(later),
            ),
          );

      final logs = await sut.getUnsyncedLogs();
      expect(logs.first.recordId, 'p-old');
      expect(logs.last.recordId, 'p-new');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // markAsSynced
  // ──────────────────────────────────────────────────────────────────────────

  group('markAsSynced', () {
    test('marks specified entries as synced', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');

      final logs = await sut.getUnsyncedLogs();
      await sut.markAsSynced([logs.first.id]);

      final row = await db.select(db.auditLogTable).getSingle();
      expect(row.enabled, isFalse);
    });

    test('only marks specified ids — others remain pending', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-2', action: 'INSERT');

      final logs = await sut.getUnsyncedLogs();
      await sut.markAsSynced([logs.first.id]);

      final unsynced = await sut.getUnsyncedLogs();
      expect(unsynced.length, 1);
      expect(unsynced.first.recordId, 'p-2');
    });

    test('does nothing when called with an empty list', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');

      await sut.markAsSynced([]);

      final unsynced = await sut.getUnsyncedLogs();
      expect(unsynced.length, 1);
    });

    test('marks multiple entries in a single call', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'sales', recordId: 's-1', action: 'INSERT');
      await sut.logMutation(
          tableName: 'visits', recordId: 'v-1', action: 'UPDATE');

      final logs = await sut.getUnsyncedLogs();
      final ids = logs.map((e) => e.id).toList();
      await sut.markAsSynced(ids);

      final remaining = await sut.getUnsyncedLogs();
      expect(remaining, isEmpty);
    });

    test('synced entries have synced = true in domain model', () async {
      await sut.logMutation(
          tableName: 'payments', recordId: 'p-1', action: 'INSERT');

      final before = await sut.getUnsyncedLogs();
      expect(before.first.synced, isFalse);

      await sut.markAsSynced([before.first.id]);

      // Verify via direct DB query since getUnsyncedLogs filters them out.
      final row = await db.select(db.auditLogTable).getSingle();
      expect(row.enabled, isFalse);
    });
  });
}
