class Product {
  final String id;
  final String name;
  final String unitLabel;
  final double price;
  final int? available;

  /// Code of the container type the product is delivered in; null when it
  /// needs no returnable container.
  final String? containerType;

  /// Server id of the customer agreement that set [price]; null when
  /// [price] is the list price.
  final int? agreementId;

  /// Local uuid of that agreement; the only reference while the agreement
  /// has not reached the server.
  final String? agreementUuid;

  const Product({
    required this.id,
    required this.name,
    required this.unitLabel,
    required this.price,
    this.available,
    this.containerType,
    this.agreementId,
    this.agreementUuid,
  });

  /// The list price comes from the server; a product without agreement
  /// whose price is still 0 cannot be sold.
  bool get hasPrice => price > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
