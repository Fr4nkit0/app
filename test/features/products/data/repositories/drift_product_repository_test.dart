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
    await db.into(db.productTable).insert(
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
    expect(emission.first.unitLabel, 'Bidón'); // Mapping description to unitLabel? Let's check Product model
  });
}
