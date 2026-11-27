import 'package:app/core/services/database.helper.dart';
import 'package:app/core/services/table_changes.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> insertProduct(String id) => db
      .into(db.productTable)
      .insert(
        ProductTableCompanion.insert(
          productId: drift.Value(id),
          name: id,
          price: 1,
        ),
      );

  test('each watcher follows its own tables, not a shared one', () async {
    final other = watchTables(db, [db.containerTypeTable]).listen((_) {});
    var events = 0;
    final sub = watchTables(db, [db.productTable]).listen((_) => events++);
    await pumpEventQueue();
    expect(events, 1);

    await insertProduct('p1');
    await pumpEventQueue();

    expect(events, 2);
    await other.cancel();
    await sub.cancel();
  });

  test('writes while paused come as one event on resume', () async {
    var events = 0;
    final sub = watchTables(db, [db.productTable]).listen((_) => events++);
    await pumpEventQueue();
    sub.pause();
    for (var i = 0; i < 5; i++) {
      await insertProduct('q$i');
    }
    await pumpEventQueue();
    expect(events, 1);

    sub.resume();
    await pumpEventQueue();

    expect(events, 2);
    await sub.cancel();
  });

  test('a write during a slow first read is not missed', () async {
    final loads = <int>[];
    final sub = watchTables(db, [db.productTable])
        .asyncMap((_) async {
          final count = (await db.select(db.productTable).get()).length;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return count;
        })
        .listen(loads.add);
    await Future<void>.delayed(const Duration(milliseconds: 1));
    await db.transaction(() async {
      await insertProduct('a');
      await insertProduct('b');
    });
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(loads.last, 2);
    await sub.cancel();
  });
}
