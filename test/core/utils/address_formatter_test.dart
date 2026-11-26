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
        AddressFormatter.format(
          street: 'Av. Belgrano 1200',
          neighborhood: '   ',
        ),
        'Av. Belgrano 1200',
      );
    });

    test('formats street with neighborhood when neighborhood is provided', () {
      expect(
        AddressFormatter.format(
          street: 'Av. Belgrano 1200',
          neighborhood: 'Centro',
        ),
        'Av. Belgrano 1200, Centro',
      );
      expect(
        AddressFormatter.format(
          street: 'mza 517 C',
          neighborhood: 'Grand Bourg',
        ),
        'Mza. 517 C, Grand Bourg',
      );
    });

    test(
      'formats street with neighborhood and additional fields (floor, apartment, reference)',
      () {
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
      },
    );
  });

  group('manzana addresses', () {
    test('a street starting with Mza shows the depto field as Lote', () {
      expect(
        AddressFormatter.format(street: 'Mza 12', apartment: '5'),
        'Mza. 12 - Lote 5',
      );
    });

    test('a street starting with Mnza is a manzana too', () {
      expect(
        AddressFormatter.format(street: 'mnza 4', apartment: '18'),
        'Mza. 4 - Lote 18',
      );
    });

    test('a long lot value is not shown as Depto either', () {
      expect(
        AddressFormatter.format(street: 'MZA. B', apartment: '123'),
        'Mza. B - Lote 123',
      );
    });

    test('a lot already written as lote is not repeated', () {
      expect(
        AddressFormatter.format(street: 'Mza 3', apartment: 'lote 7'),
        'Mza. 3 - Lote 7',
      );
    });

    test('a street that only contains Mza later keeps Depto', () {
      expect(
        AddressFormatter.format(street: 'Belgrano Mza 3', apartment: 'B'),
        'Belgrano Mza. 3 - Depto B',
      );
    });

    test('a manzana with a floor keeps the floor before the lot', () {
      expect(
        AddressFormatter.format(street: 'Mza 3', floor: '1', apartment: '2'),
        'Mza. 3 - Piso 1, Lote 2',
      );
    });
  });
}
