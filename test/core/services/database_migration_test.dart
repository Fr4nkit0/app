import 'dart:io';

import 'package:app/core/services/database.helper.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens a raw database file at a previous development version without the
/// app's migrations.
class _LegacyUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 16;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

/// Writes a v16 development database: route_stops with the legacy `notes`
/// column and without the requested-visit columns, plus a few stored rows.
Future<void> _writeV16Database(File file) async {
  final legacy = NativeDatabase(
    file,
    setup: (raw) {
      raw.execute('''
        CREATE TABLE customers (customer_id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL);
        CREATE TABLE routes (route_id TEXT NOT NULL PRIMARY KEY,
          route_date INTEGER NOT NULL);
        CREATE TABLE route_stops (route_stop_id TEXT NOT NULL PRIMARY KEY,
          route_id TEXT NOT NULL, customer_id TEXT NOT NULL,
          sequence INTEGER NOT NULL, status TEXT NOT NULL DEFAULT 'pending',
          scheduled_at INTEGER NOT NULL, notes TEXT);
        INSERT INTO customers VALUES ('c-1', 'Ana');
        INSERT INTO routes VALUES ('r-1', 0);
        INSERT INTO route_stops (route_stop_id, route_id, customer_id,
          sequence, scheduled_at, notes) VALUES ('s-1', 'r-1', 'c-1', 1, 0, 'x');
        PRAGMA user_version = 16;
      ''');
    },
  );
  await legacy.ensureOpen(_LegacyUser());
  await legacy.close();
}

Future<int> _userVersion(AppDatabase db) async =>
    (await db.customSelect('PRAGMA user_version').getSingle()).read<int>(
      'user_version',
    );

Future<Set<String>> _columns(AppDatabase db, String table) async => {
  for (final row in await db.customSelect('PRAGMA table_info($table)').get())
    row.read<String>('name'),
};

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('marilin_migration_test_');
    file = File('${dir.path}/app.sqlite');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('the schema version is 20', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 20);
  });

  test('a version 18 database gains balance_corrections and keeps its '
      'data and unsent changes', () async {
    // A v18 database: the current schema without balance_corrections and
    // without route_stops.position.
    final v18 = AppDatabase(NativeDatabase(file));
    await v18.customStatement('DROP TABLE balance_corrections');
    await v18.customStatement('ALTER TABLE route_stops DROP COLUMN position');
    await v18.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Ana')",
    );
    await v18.customStatement(
      'INSERT INTO pending_changes (entity, entity_id, action) '
      "VALUES ('customer', 'c-1', 'insert')",
    );
    await v18.customStatement('PRAGMA user_version = 18');
    await v18.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await _userVersion(db), 20);
    expect((await db.select(db.customerTable).get()).map((c) => c.customerId), [
      'c-1',
    ]);
    expect(
      (await db.select(db.pendingChangeTable).get()).map((c) => c.entityId),
      ['c-1'],
    );
    expect(await _columns(db, 'balance_corrections'), {
      for (final c in db.balanceCorrectionTable.$columns) c.name,
    });
    expect(await _columns(db, 'route_stops'), contains('position'));
  });

  test('a version 19 database gains route_stops.position and keeps its '
      'stops and unsent changes', () async {
    // A v19 database: the current schema without route_stops.position.
    final v19 = AppDatabase(NativeDatabase(file));
    await v19.customStatement('ALTER TABLE route_stops DROP COLUMN position');
    await v19.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Ana')",
    );
    await v19.customStatement(
      "INSERT INTO routes (route_id, route_date) VALUES ('r-1', '2026-11-25')",
    );
    await v19.customStatement(
      'INSERT INTO route_stops (route_stop_id, route_id, customer_id, '
      "sequence, scheduled_at) VALUES ('s-1', 'r-1', 'c-1', 3, 0)",
    );
    await v19.customStatement(
      'INSERT INTO pending_changes (entity, entity_id, action) '
      "VALUES ('route_stop', 's-1', 'update')",
    );
    await v19.customStatement('PRAGMA user_version = 19');
    await v19.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await _userVersion(db), 20);
    final stops = await db.select(db.routeStopTable).get();
    expect(stops.map((s) => (s.routeStopId, s.sequence, s.position)), [
      ('s-1', 3, null),
    ]);
    expect(
      (await db.select(db.pendingChangeTable).get()).map((c) => c.entityId),
      ['s-1'],
    );
    expect(await _columns(db, 'route_stops'), {
      for (final c in db.routeStopTable.$columns) c.name,
    });
  });

  test(
    'a fresh install creates every table with the current columns',
    () async {
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      expect(await _userVersion(db), 20);
      for (final table in db.allTables) {
        expect(await _columns(db, table.actualTableName), {
          for (final c in table.$columns) c.name,
        }, reason: table.actualTableName);
      }
      expect(
        await _columns(db, 'route_stops'),
        allOf(
          containsAll(['is_requested', 'note', 'scheduled_visit_id']),
          isNot(contains('notes')),
        ),
      );
    },
  );

  test('an older development database is rebuilt empty with the current '
      'schema', () async {
    await _writeV16Database(file);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await db.select(db.customerTable).get(), isEmpty);
    expect(await db.select(db.routeTable).get(), isEmpty);
    expect(await db.select(db.routeStopTable).get(), isEmpty);
    for (final table in db.allTables) {
      expect(await _columns(db, table.actualTableName), {
        for (final c in table.$columns) c.name,
      }, reason: table.actualTableName);
    }
    expect(await _userVersion(db), 20);
  });

  test('reopening a rebuilt database keeps the data written after the '
      'rebuild', () async {
    await _writeV16Database(file);

    final first = AppDatabase(NativeDatabase(file));
    await first.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-2', 'Bea')",
    );
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);

    final customers = await second.select(second.customerTable).get();
    expect(customers.map((c) => c.customerId), ['c-2']);
    expect(await _userVersion(second), 20);
  });
}
