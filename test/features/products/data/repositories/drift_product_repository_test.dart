import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';

void main() {
  late AppDatabase db;
  late DriftProductRepository sut;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftProductRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('watchAllProducts returns empty list initially', () async {
    final stream = sut.watchAllProducts();
    final firstEmission = await stream.first;
    expect(firstEmission, isEmpty);
  });

  test('watchAllProducts returns seeded products if inserted', () async {
    // Insert a product manually
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('prod-1'),
            name: 'Bidón 20L',
            price: 800.0,
            stock: const drift.Value(25),
            description: const drift.Value('Bidón'),
          ),
        );

    final stream = sut.watchAllProducts();
    final emission = await stream.first;

    expect(emission.length, 1);
    expect(emission.first.id, 'prod-1');
    expect(emission.first.name, 'Bidón 20L');
    expect(emission.first.price, 800.0);
    expect(emission.first.available, 25);
    expect(
      emission.first.unitLabel,
      'Bidón',
    ); // Mapping description to unitLabel? Let's check Product model
  });

  test('watchProductsFor uses the list price when the customer has no agreement', () async {
    await db.into(db.productTable).insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('prod-1'),
            name: 'Bidón 20L',
            price: 800.0,
          ),
        );

    final products = await sut.watchProductsFor('cust-1').first;

    expect(products.single.price, 800.0);
    expect(products.single.agreementId, isNull);
  });

  group('watchProductsFor with two agreements in force from the same day', () {
    Future<void> seed() async {
      await db.into(db.customerTable).insert(
            CustomerTableCompanion.insert(
              customerId: const drift.Value('cust-1'),
              name: 'Kiosco Norte',
            ),
          );
      await db.into(db.productTable).insert(
            ProductTableCompanion.insert(
              productId: const drift.Value('prod-1'),
              name: 'Bidón 20L',
              price: 800.0,
            ),
          );
    }

    Future<void> agreement(String id, double price, {int? serverId}) =>
        db.into(db.customerAgreementTable).insert(
              CustomerAgreementTableCompanion.insert(
                agreementId: drift.Value(id),
                customerId: 'cust-1',
                productId: 'prod-1',
                unitPrice: price,
                validFrom: '2026-10-01',
                serverId: drift.Value(serverId),
              ),
            );

    test('the one with the highest server id wins, like the server', () async {
      await seed();
      await agreement('a-low', 650.0, serverId: 3);
      await agreement('a-high', 700.0, serverId: 9);

      final products = await sut
          .watchProductsFor('cust-1', day: DateTime(2026, 10, 20))
          .first;

      expect(products.single.price, 700.0);
      expect(products.single.agreementId, 9);
    });

    test('one not yet synced wins, because the server will give it the highest id', () async {
      await seed();
      await agreement('a-synced', 700.0, serverId: 9);
      await agreement('a-local', 600.0);

      final products = await sut
          .watchProductsFor('cust-1', day: DateTime(2026, 10, 20))
          .first;

      expect(products.single.price, 600.0);
      expect(products.single.agreementUuid, 'a-local');
    });
  });

  group('containerType', () {
    Future<void> seedProduct(String id, String name, {int? containerTypeId}) =>
        db.into(db.productTable).insert(
              ProductTableCompanion.insert(
                productId: drift.Value(id),
                name: name,
                price: 800.0,
                containerTypeId: drift.Value(containerTypeId),
              ),
            );

    setUp(() async {
      await db.into(db.containerTypeTable).insert(
            ContainerTypeTableCompanion.insert(
              id: const drift.Value(7),
              code: 'JUG_12L',
              description: const drift.Value('Jug 12L'),
            ),
          );
    });

    test('is the catalog code of the product containerTypeId', () async {
      // The name would guess another type: the catalog link wins.
      await seedProduct('prod-1', 'Agua 20L', containerTypeId: 7);

      final product = (await sut.watchAllProducts().first).single;

      expect(product.containerType, 'JUG_12L');
    });

    test('falls back to the name guess without a containerTypeId', () async {
      await seedProduct('prod-1', 'Agua 20L');
      await seedProduct('prod-2', 'Sifón 1.5L');
      await seedProduct('prod-3', 'Hielo');

      final products = await sut.watchAllProducts().first;

      expect(
        {for (final p in products) p.id: p.containerType},
        {'prod-1': 'BIDON_20L', 'prod-2': 'SIFON_2L', 'prod-3': null},
      );
    });

    test('falls back to the name guess when the catalog lacks the type', () async {
      await seedProduct('prod-1', 'Agua 20L', containerTypeId: 99);

      final product = (await sut.watchAllProducts().first).single;

      expect(product.containerType, 'BIDON_20L');
    });

    test('is resolved for customer priced products too', () async {
      await seedProduct('prod-1', 'Hielo', containerTypeId: 7);

      final product = (await sut.watchProductsFor('cust-1').first).single;

      expect(product.containerType, 'JUG_12L');
    });
  });
}
