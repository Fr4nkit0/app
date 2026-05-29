import 'package:app/features/sales/data/repositories/product.repository.dart';
import 'package:app/features/sales/domain/models/product.dart';

class MockProductRepository implements ProductRepository {
  static const _products = [
    Product(id: 'prod-1', name: 'Bidón 20L', unitLabel: 'Bidón', price: 800),
    Product(id: 'prod-2', name: 'Sifón 5L', unitLabel: 'Sifón', price: 350),
    Product(id: 'prod-3', name: 'Bidón 10L', unitLabel: 'Bidón 10L', price: 500),
  ];

  @override
  Stream<List<Product>> watchAllProducts() =>
      Stream.value(List.of(_products));
}
