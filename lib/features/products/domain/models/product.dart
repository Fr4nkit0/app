class Product {
  final String id;
  final String name;
  final String unitLabel;
  final double price;
  final int? available;

  const Product({
    required this.id,
    required this.name,
    required this.unitLabel,
    required this.price,
    this.available,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

extension ProductContainerExtension on Product {
  String? get containerType {
    if (name.contains('20L')) return 'BIDON_20L';
    if (name.contains('Sifón')) return 'SIFON_2L';
    return null;
  }
}
