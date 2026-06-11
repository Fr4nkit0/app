import 'package:app/features/products/domain/models/product.dart';

class SaleItem {
  final Product product;
  final int quantity;

  const SaleItem({required this.product, required this.quantity});

  double get subtotal => product.price * quantity;
}
