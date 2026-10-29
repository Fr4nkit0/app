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
