import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';
import 'package:app/features/products/domain/models/product.dart';

final productListProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(driftProductRepositoryProvider).watchAllProducts();
});
