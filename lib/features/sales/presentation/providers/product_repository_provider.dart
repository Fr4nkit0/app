import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/sales/data/repositories/mock_product_repository.dart';
import 'package:app/features/sales/data/repositories/product.repository.dart';
import 'package:app/features/sales/domain/models/product.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => MockProductRepository(),
);

final productListProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllProducts();
});
