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

/// Every money column, by table: whole pesos since v23.
const _moneyColumns = {
  'products': ['price'],
  'customer_agreements': ['unit_price'],
  'sales': [
    'total_amount',
    'shipping_amount',
    'cash_amount',
    'transfer_amount',
  ],
  'sale_items': ['unit_price', 'subtotal'],
  'payments': ['amount'],
  'customer_account_entries': ['amount'],
  'customer_balances': ['current_balance'],
  'visits': ['amount_collected'],
  'balance_corrections': ['counted', 'seen_balance'],
};

Future<Map<String, String>> _columnTypes(
  AppDatabase db,
  String table,
) async => {
  for (final row in await db.customSelect('PRAGMA table_info($table)').get())
    row.read<String>('name'): row.read<String>('type'),
};

Future<void> _expectCurrentSchema(AppDatabase db) async {
  for (final table in db.allTables) {
    expect(await _columns(db, table.actualTableName), {
      for (final c in table.$columns) c.name,
    }, reason: table.actualTableName);
  }
  for (final MapEntry(key: table, value: columns) in _moneyColumns.entries) {
    final types = await _columnTypes(db, table);
    for (final column in columns) {
      expect(types[column], 'INTEGER', reason: '$table.$column');
    }
  }
}

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('marilin_migration_test_');
    file = File('${dir.path}/app.sqlite');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('the schema version is 23', () {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 23);
  });

  test('a fresh install creates every table with the current columns and '
      'integer money columns', () async {
    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await _userVersion(db), 23);
    await _expectCurrentSchema(db);
    expect(
      await _columns(db, 'route_stops'),
      allOf(
        containsAll(['is_requested', 'note', 'scheduled_visit_id']),
        isNot(contains('notes')),
      ),
    );
  });

  test('a version 22 database with REAL money columns is rebuilt empty with '
      'integer money columns', () async {
    // A v22 database: the current schema with its money columns as REAL.
    final v22 = AppDatabase(NativeDatabase(file));
    for (final MapEntry(key: table, value: columns) in _moneyColumns.entries) {
      var sql =
          (await v22
                  .customSelect(
                    'SELECT sql FROM sqlite_master WHERE name = ?',
                    variables: [Variable.withString(table)],
                  )
                  .getSingle())
              .read<String>('sql');
      for (final column in columns) {
        sql = sql.replaceFirst('"$column" INTEGER', '"$column" REAL');
      }
      await v22.customStatement('DROP TABLE $table');
      await v22.customStatement(sql);
      final types = await _columnTypes(v22, table);
      for (final column in columns) {
        expect(types[column], 'REAL', reason: '$table.$column');
      }
    }
    await v22.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Ana')",
    );
    await v22.customStatement(
      "INSERT INTO products (product_id, name, price) "
      "VALUES ('p-1', 'Agua', 19500.07)",
    );
    await v22.customStatement(
      'INSERT INTO payments (payment_id, customer_id, amount, payment_method) '
      "VALUES ('pay-1', 'c-1', 3999.99, 'EFECTIVO')",
    );
    await v22.customStatement(
      'INSERT INTO pending_changes (entity, entity_id, action) '
      "VALUES ('payment', 'pay-1', 'insert')",
    );
    await v22.customStatement('PRAGMA user_version = 22');
    await v22.close();

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await _userVersion(db), 23);
    expect(await db.select(db.customerTable).get(), isEmpty);
    expect(await db.select(db.productTable).get(), isEmpty);
    expect(await db.select(db.paymentTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    await _expectCurrentSchema(db);
  });

  test('an older development database is rebuilt empty with the current '
      'schema', () async {
    await _writeV16Database(file);

    final db = AppDatabase(NativeDatabase(file));
    addTearDown(db.close);

    expect(await db.select(db.customerTable).get(), isEmpty);
    expect(await db.select(db.routeTable).get(), isEmpty);
    expect(await db.select(db.routeStopTable).get(), isEmpty);
    await _expectCurrentSchema(db);
    expect(await _userVersion(db), 23);
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
    expect(await _userVersion(second), 23);
  });
}
