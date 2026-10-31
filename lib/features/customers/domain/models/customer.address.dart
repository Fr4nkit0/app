class CustomerAddress {
  final String id;
  final String? street;
  final String? apartment;
  final String? floor;
  final String? visualReference;
  final bool isPrimary;
  final double? latitude;
  final double? longitude;
  final String? neighborhood;

  CustomerAddress({
    required this.id,
    this.street,
    this.apartment,
    this.floor,
    this.visualReference,
    this.isPrimary = false,
    this.latitude,
    this.longitude,
    this.neighborhood,
  });

  CustomerAddress copyWith({
    String? street,
    String? apartment,
    String? floor,
    String? visualReference,
    bool? isPrimary,
    String? neighborhood,
  }) => CustomerAddress(
    id: id,
    street: street ?? this.street,
    apartment: apartment ?? this.apartment,
    floor: floor ?? this.floor,
    visualReference: visualReference ?? this.visualReference,
    isPrimary: isPrimary ?? this.isPrimary,
    latitude: latitude,
    longitude: longitude,
    neighborhood: neighborhood ?? this.neighborhood,
  );
}
