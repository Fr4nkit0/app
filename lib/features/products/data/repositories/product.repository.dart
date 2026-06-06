import 'package:app/features/products/domain/models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchAllProducts();
}
