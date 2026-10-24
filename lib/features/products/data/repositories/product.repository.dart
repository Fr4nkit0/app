import 'package:app/features/products/domain/models/product.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchAllProducts();

  /// Enabled products priced for [customerId]: the price of the agreement
  /// in force on [day] (today by default) when there is one, the list price
  /// otherwise.
  Stream<List<Product>> watchProductsFor(String customerId, {DateTime? day});
}
