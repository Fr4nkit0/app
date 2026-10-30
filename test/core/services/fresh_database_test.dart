import 'dart:io';

import 'package:app/core/services/database.helper.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a fresh install starts with empty local lists', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await db.select(db.customerTable).get(), isEmpty);
    expect(await db.select(db.customerAddressTable).get(), isEmpty);
    expect(await db.select(db.customerPreferenceTable).get(), isEmpty);
    expect(await db.select(db.productTable).get(), isEmpty);
    expect(await db.select(db.routeTable).get(), isEmpty);
    expect(await db.select(db.routeStopTable).get(), isEmpty);
    expect(await db.select(db.neighborhoodTable).get(), isEmpty);
  });

  test('a fresh install stores new sales as confirmed', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Ana')",
    );
    await db.customStatement(
      'INSERT INTO sales (sale_id, customer_id, total_amount, payment_method, '
      "quantity, shipping_amount) VALUES ('sale-1', 'c-1', 10, 'cash', 0, 0)",
    );

    final sale = await db.select(db.saleTable).getSingle();
    expect(sale.status, 'CONFIRMED');
    expect(sale.cancelledAt, isNull);
  });

  test('a fresh install stores container movements without a sale or '
      'reversal link', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Ana')",
    );
    await db.customStatement(
      'INSERT INTO container_movements (container_movement_id, customer_id, '
      "container_type, delivered_quantity, returned_quantity) "
      "VALUES ('mov-1', 'c-1', 'BIDON_20L', 1, 0)",
    );

    final movement = await db.select(db.containerMovementTable).getSingle();
    expect(movement.saleId, isNull);
    expect(movement.reversesMovementId, isNull);
  });

  test('a fresh install stores route stops as not requested', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO customers (customer_id, name) VALUES ('c-1', 'Ana')",
    );
    await db.customStatement(
      "INSERT INTO routes (route_id, route_date) VALUES ('r-1', '2026-10-30')",
    );
    await db.customStatement(
      'INSERT INTO route_stops (route_stop_id, route_id, customer_id, '
      "sequence, scheduled_at) VALUES ('s-1', 'r-1', 'c-1', 1, 0)",
    );

    final stop = await db.select(db.routeStopTable).getSingle();
    expect(stop.isRequested, isFalse);
    expect(stop.note, isNull);
    expect(stop.scheduledVisitId, isNull);
  });

  test('reopening an existing empty database does not reseed it', () async {
    final dir = Directory.systemTemp.createTempSync('marilin_db_test_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/app.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    await first.select(first.customerTable).get();
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);

    expect(await second.select(second.customerTable).get(), isEmpty);
  });
}
