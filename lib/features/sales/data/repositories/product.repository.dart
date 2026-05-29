import 'package:app/features/sales/domain/models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchAllProducts();
}
