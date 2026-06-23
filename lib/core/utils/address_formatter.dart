class AddressFormatter {
  static String format({
    String? street,
    String? floor,
    String? apartment,
    String? visualReference,
  }) {
    final parts = <String>[];

    if (street != null && street.trim().isNotEmpty) {
      parts.add(_normalizeStreet(street.trim()));
    }

    final floorAndDept = <String>[];
    if (floor != null && floor.trim().isNotEmpty) {
      final f = floor.trim();
      final numericOnly = RegExp(r'^\d+$').hasMatch(f);
      if (numericOnly) {
        floorAndDept.add('Piso $f');
      } else {
        floorAndDept.add(_capitalize(f));
      }
    }

    if (apartment != null && apartment.trim().isNotEmpty) {
      final apt = apartment.trim();
      final singleOrShort = apt.length <= 2;
      if (singleOrShort) {
        floorAndDept.add('Depto $apt');
      } else {
        floorAndDept.add(_capitalize(apt));
      }
    }

    if (floorAndDept.isNotEmpty) {
      parts.add(floorAndDept.join(', '));
    }

    if (visualReference != null && visualReference.trim().isNotEmpty) {
      parts.add('(${visualReference.trim()})');
    }

    return parts.isEmpty ? 'Sin dirección' : parts.join(' - ');
  }

  static String _normalizeStreet(String street) {
    String value = street;

    value = value.replaceAllMapped(
      RegExp(r'\b(mza|manzana)\b\.?', caseSensitive: false),
      (_) => 'Mza.',
    );

    value = value.replaceAllMapped(
      RegExp(r'\b(lte|lote)\b\.?', caseSensitive: false),
      (_) => 'Lote',
    );

    // Replace nro/n°/num with N°
    value = value.replaceAllMapped(
      RegExp(r'\b(nro|n°|num|numero)\b\.?', caseSensitive: false),
      (_) => 'N°',
    );

    // Replace av/avenida with Av.
    value = value.replaceAllMapped(
      RegExp(r'\b(av|avenida)\b\.?', caseSensitive: false),
      (_) => 'Av.',
    );

    value = value.replaceAll(RegExp(r'\s+'), ' ');

    return value.trim();
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
