import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/address_formatter.dart';

void main() {
  group('AddressFormatter.format', () {
    test('formats street only when neighborhood is null or empty', () {
      expect(
        AddressFormatter.format(street: 'Av. Belgrano 1200'),
        'Av. Belgrano 1200',
      );
      expect(
        AddressFormatter.format(street: 'Av. Belgrano 1200', neighborhood: ''),
        'Av. Belgrano 1200',
      );
      expect(
        AddressFormatter.format(street: 'Av. Belgrano 1200', neighborhood: '   '),
        'Av. Belgrano 1200',
      );
    });

    test('formats street with neighborhood when neighborhood is provided', () {
      expect(
        AddressFormatter.format(street: 'Av. Belgrano 1200', neighborhood: 'Centro'),
        'Av. Belgrano 1200, Centro',
      );
      expect(
        AddressFormatter.format(street: 'mza 517 C', neighborhood: 'Grand Bourg'),
        'Mza. 517 C, Grand Bourg',
      );
    });

    test('formats street with neighborhood and additional fields (floor, apartment, reference)', () {
      expect(
        AddressFormatter.format(
          street: 'Av. Belgrano 1200',
          neighborhood: 'Centro',
          floor: '3',
          apartment: 'B',
          visualReference: 'Frente a la plaza',
        ),
        'Av. Belgrano 1200, Centro - Piso 3, Depto B - (Frente a la plaza)',
      );
    });
  });
}
