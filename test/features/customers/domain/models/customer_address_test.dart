import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';

void main() {
  group('CustomerAddress', () {
    test('can be created with a neighborhood', () {
      final address = CustomerAddress(
        id: 'addr-123',
        street: 'Calle Falsa 123',
        neighborhood: 'Centro',
        isPrimary: true,
      );

      expect(address.id, 'addr-123');
      expect(address.street, 'Calle Falsa 123');
      expect(address.neighborhood, 'Centro');
      expect(address.isPrimary, isTrue);
    });

    test('can be created with a null neighborhood', () {
      final address = CustomerAddress(
        id: 'addr-123',
        street: 'Calle Falsa 123',
        isPrimary: true,
      );

      expect(address.neighborhood, isNull);
    });
  });
}
