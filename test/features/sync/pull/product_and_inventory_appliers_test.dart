import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/product_applier.dart';
import 'package:app/features/sync/pull/truck_inventory_applier.dart';

import 'pull_support.dart';

void main() {
  late AppDatabase db;
  final today = DateTime(2026, 10, 19, 9);

  setUp(() => db = memoryDatabase());
  tearDown(() => db.close());

  Future<ProductTableData> product(String id) => (db.select(
    db.productTable,
  )..where((t) => t.productId.equals(id))).getSingle();

  group('ProductApplier', () {
    test('a pull takes the price and keeps the local stock', () async {
      await seedProduct(db, id: 'prod-1', serverId: 21, stock: 7);

      await ProductApplier(db).applyChanges({
        'products': [
          {
            'id': 21,
            'name': 'Water 20L (new)',
            'description': null,
            'price': '999.50',
          },
        ],
      }, await pullContext(db));

      final row = await product('prod-1');
      expect(row.name, 'Water 20L (new)');
      expect(row.price, 999.5);
      expect(row.stock, 7);
    });

    test('a pull without a price keeps the stored one', () async {
      await seedProduct(db, id: 'prod-1', serverId: 21, stock: 7);

      await ProductApplier(db).applyChanges({
        'products': [
          {'id': 21, 'name': 'Water 20L', 'description': null},
        ],
      }, await pullContext(db));

      expect((await product('prod-1')).price, 100);
    });

    test('a product new in a pull gets its price', () async {
      await ProductApplier(db).applyChanges({
        'products': [
          {'id': 23, 'name': 'Soda 1L', 'description': null, 'price': '80'},
        ],
      }, await pullContext(db));

      final row = await (db.select(
        db.productTable,
      )..where((t) => t.serverId.equals(23))).getSingle();
      expect(row.price, 80);
      expect(row.stock, 0);
    });

    test(
      'a bootstrap takes the stock from the truck inventory and maps the id',
      () async {
        await seedProduct(db, id: 'prod-1', serverId: 21, stock: 7);
        final context = await bootstrapContext(db);

        await ProductApplier(db).applySnapshot(
          [
            {'id': 21, 'name': 'Water 20L', 'price': '150'},
            {'id': 22, 'name': 'Soda 2L'},
            {'id': 24, 'name': 'Soda 1L', 'price': '80.00'},
          ],
          [
            {'id': 900, 'product_id': 21, 'current_quantity': '20.00'},
          ],
          context,
        );

        final row = await product('prod-1');
        expect(row.stock, 20);
        expect(row.price, 150);
        expect(await context.ids.product(21), 'prod-1');
        expect(await context.ids.product(22), isNotNull);
        expect((await product((await context.ids.product(22))!)).price, 0);
        expect((await product((await context.ids.product(24))!)).price, 80);
      },
    );

    test('a bootstrap keeps a negative truck stock as is', () async {
      await seedProduct(db, id: 'prod-1', serverId: 21, stock: 7);

      await ProductApplier(db).applySnapshot(
        [
          {'id': 21, 'name': 'Water 20L'},
        ],
        [
          {'id': 900, 'product_id': 21, 'current_quantity': '-3.00'},
        ],
        await bootstrapContext(db),
      );

      expect((await product('prod-1')).stock, -3);
    });

    test('a bootstrap keeps the stock while sales are unsent', () async {
      await seedProduct(db, id: 'prod-1', serverId: 21, stock: 7);
      await enqueueUnsent(db, PendingEntity.sale, 'sale-1');

      await ProductApplier(db).applySnapshot(
        [
          {'id': 21, 'name': 'Water 20L'},
        ],
        [
          {'id': 900, 'product_id': 21, 'current_quantity': '20.00'},
        ],
        await bootstrapContext(db),
      );

      expect((await product('prod-1')).stock, 7);
    });
  });

  group('TruckInventoryApplier', () {
    Map<String, List<Map<String, dynamic>>> inventory({
      int productId = 21,
      String quantity = '20.00',
    }) => {
      'route_inventories': [
        {
          'id': 900,
          'route_id': 7,
          'product_id': productId,
          'current_quantity': quantity,
        },
      ],
    };

    setUp(() async {
      await seedProduct(db, id: 'prod-1', serverId: 21, stock: 7);
    });

    test("today's route inventory sets the truck stock", () async {
      await seedRoute(db, id: 'route-1', serverId: 7, date: dayOf(today));

      await TruckInventoryApplier(
        db,
        today: () => today,
      ).applyChanges(inventory(), await pullContext(db));

      expect(
        (await db.select(db.routeInventoryLoadTable).getSingle()).quantity,
        20,
      );
      expect((await product('prod-1')).stock, 20);
    });

    test('keeps a negative current_quantity as is', () async {
      await seedRoute(db, id: 'route-1', serverId: 7, date: dayOf(today));

      await TruckInventoryApplier(
        db,
        today: () => today,
      ).applyChanges(inventory(quantity: '-1.00'), await pullContext(db));

      expect(
        (await db.select(db.routeInventoryLoadTable).getSingle()).quantity,
        -1,
      );
      expect((await product('prod-1')).stock, -1);
    });

    test('a bootstrap keeps a negative current_quantity as is', () async {
      await seedRoute(db, id: 'route-1', serverId: 7, date: dayOf(today));
      final context = await bootstrapContext(db);
      context.ids.recordProduct(21, 'prod-1');

      await TruckInventoryApplier(db, today: () => today).replaceRoute(
        'route-1',
        inventory(quantity: '-2.00')['route_inventories']!,
        context,
      );

      expect(
        (await db.select(db.routeInventoryLoadTable).getSingle()).quantity,
        -2,
      );
    });

    test(
      'keeps the truck stock while sales are unsent or the route is another day',
      () async {
        await seedRoute(db, id: 'route-1', serverId: 7, date: '2026-10-18');
        await TruckInventoryApplier(
          db,
          today: () => today,
        ).applyChanges(inventory(), await pullContext(db));
        expect((await product('prod-1')).stock, 7);

        await (db.update(db.routeTable)
              ..where((t) => t.routeId.equals('route-1')))
            .write(RouteTableCompanion(route_date: Value(dayOf(today))));
        await enqueueUnsent(db, PendingEntity.sale, 'sale-1');
        await TruckInventoryApplier(
          db,
          today: () => today,
        ).applyChanges(inventory(), await pullContext(db));
        expect((await product('prod-1')).stock, 7);
      },
    );

    test(
      'skips an inventory whose route or product is not on the device',
      () async {
        await TruckInventoryApplier(
          db,
          today: () => today,
        ).applyChanges(inventory(), await pullContext(db));
        await seedRoute(db, id: 'route-1', serverId: 7, date: dayOf(today));
        await TruckInventoryApplier(
          db,
          today: () => today,
        ).applyChanges(inventory(productId: 99), await pullContext(db));

        expect(await db.select(db.routeInventoryLoadTable).get(), isEmpty);
      },
    );

    test('a bootstrap replaces the server loads of the route', () async {
      await seedRoute(db, id: 'route-1', serverId: 7, date: dayOf(today));
      for (final (serverId, quantity) in [(800, 5), (null, 3)]) {
        await db
            .into(db.routeInventoryLoadTable)
            .insert(
              RouteInventoryLoadTableCompanion.insert(
                routeId: 'route-1',
                productId: 'prod-1',
                quantity: quantity,
                serverId: Value(serverId),
              ),
            );
      }
      final context = await bootstrapContext(db);
      context.ids.recordProduct(21, 'prod-1');

      await TruckInventoryApplier(
        db,
        today: () => today,
      ).replaceRoute('route-1', inventory()['route_inventories']!, context);

      final rows = await db.select(db.routeInventoryLoadTable).get();
      expect(rows.map((r) => r.serverId), unorderedEquals([900, null]));
    });
  });
}
