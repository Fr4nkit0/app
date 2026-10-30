import 'package:app/core/errors/domain_failure.dart';

/// What the driver types for one delivery address. Coordinates are not part
/// of it: they are fixed at the door and stay as stored.
class AddressDetails {
  const AddressDetails({
    this.street,
    this.neighborhood,
    this.apartment,
    this.floor,
    this.visualReference,
  });

  // The server's limits; a longer field would be rejected on push.
  static const maxStreetLength = 200;
  static const maxApartmentLength = 20;
  static const maxFloorLength = 20;
  static const maxNeighborhoodLength = 255;

  final String? street;

  /// The neighborhood name; it travels as text, not as a catalog id.
  final String? neighborhood;
  final String? apartment;
  final String? floor;
  final String? visualReference;

  /// A copy with every field trimmed and blank fields as null.
  AddressDetails trimmed() => AddressDetails(
    street: _clean(street),
    neighborhood: _clean(neighborhood),
    apartment: _clean(apartment),
    floor: _clean(floor),
    visualReference: _clean(visualReference),
  );

  /// Throws [ValidationFailure] for the fields the server would refuse: no
  /// street, or a field over its limit. Call it on a [trimmed] copy.
  void validate() {
    if (street == null) {
      throw const ValidationFailure('La calle es requerida');
    }
    void limit(String? value, int max, String field) {
      if (value != null && value.length > max) {
        throw ValidationFailure('$field admite hasta $max caracteres.');
      }
    }

    limit(street, maxStreetLength, 'La calle');
    limit(apartment, maxApartmentLength, 'El depto');
    limit(floor, maxFloorLength, 'El piso');
    limit(neighborhood, maxNeighborhoodLength, 'El barrio');
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
