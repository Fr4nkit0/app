class AddressFormatter {
  static String format({
    String? street,
    String? neighborhood,
    String? floor,
    String? apartment,
    String? visualReference,
  }) {
    final parts = <String>[];

    if (street != null && street.trim().isNotEmpty) {
      final normalizedStreet = _normalizeStreet(street.trim());
      if (neighborhood != null && neighborhood.trim().isNotEmpty) {
        parts.add('$normalizedStreet, ${neighborhood.trim()}');
      } else {
        parts.add(normalizedStreet);
      }
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
      if (_isManzana(street)) {
        // On a manzana the depto field holds the lot number.
        floorAndDept.add('Lote ${apt.replaceFirst(_lotPrefix, '').trim()}');
      } else if (singleOrShort) {
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

  static final _manzana = RegExp(
    r'\b(mnza|mza|manzana)\b\.?',
    caseSensitive: false,
  );
  static final _lotPrefix = RegExp(r'^(lte|lote)\b\.?', caseSensitive: false);

  /// Whether [street] starts with a manzana (Mza, Mnza or Manzana).
  static bool _isManzana(String? street) {
    final value = street?.trim() ?? '';
    final match = _manzana.matchAsPrefix(value);
    return match != null;
  }

  static String _normalizeStreet(String street) {
    String value = street;

    value = value.replaceAllMapped(_manzana, (_) => 'Mza.');

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
