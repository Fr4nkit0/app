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

  /// The server has no list price yet, so a product without agreement may
  /// arrive at 0; such a product cannot be sold.
  bool get hasPrice => price > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Product && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
