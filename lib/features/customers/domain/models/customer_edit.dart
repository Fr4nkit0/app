/// What the driver can change on an existing customer: exactly what the
/// customer push sends (name, phone and one address). Coordinates and
/// preferences are not part of it and stay as stored.
class CustomerEdit {
  final String customerId;
  final String name;
  final String? phone;
  final String? street;
  final String? neighborhood;
  final String? apartment;
  final String? floor;
  final String? visualReference;

  const CustomerEdit({
    required this.customerId,
    required this.name,
    this.phone,
    this.street,
    this.neighborhood,
    this.apartment,
    this.floor,
    this.visualReference,
  });
}
