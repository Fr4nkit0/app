import 'package:app/features/products/data/repositories/product.repository.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriftProductRepository implements ProductRepository {
  final AppDatabase db;

  DriftProductRepository(this.db);

  @override
  Stream<List<Product>> watchAllProducts() {
    return db.select(db.productTable).watch().map((rows) {
      return rows.map((row) {
        return Product(
          id: row.productId,
          name: row.name,
          unitLabel:
              row.description ?? '', // Using description as unitLabel mapping
          price: row.price,
          available: row.stock,
        );
      }).toList();
    });
  }
}

final driftProductRepositoryProvider = Provider<ProductRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftProductRepository(db);
});
