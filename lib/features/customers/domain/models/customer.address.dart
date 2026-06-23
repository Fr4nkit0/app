class CustomerAddress {
  final String id;
  final String? street;
  final String? apartment;
  final String? floor;
  final String? visualReference;
  final bool isPrimary;
  final double? latitude;
  final double? longitude;

  CustomerAddress({
    required this.id,
    this.street,
    this.apartment,
    this.floor,
    this.visualReference,
    this.isPrimary = false,
    this.latitude,
    this.longitude,
  });
}
