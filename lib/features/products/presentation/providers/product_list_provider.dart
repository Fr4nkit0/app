import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';
import 'package:app/features/products/domain/models/product.dart';

final productListProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(driftProductRepositoryProvider).watchAllProducts();
});

/// Products priced for one customer (agreement in force or list price).
final customerProductListProvider =
    StreamProvider.family<List<Product>, String>((ref, customerId) {
      return ref
          .watch(driftProductRepositoryProvider)
          .watchProductsFor(customerId);
    });
