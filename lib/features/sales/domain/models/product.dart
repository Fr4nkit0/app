class Product {
  final String id;
  final String name;
  final String unitLabel;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.unitLabel,
    required this.price,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
