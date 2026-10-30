import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/domain/models/salta_neighborhoods.dart';

void main() {
  group('Salta Neighborhoods', () {
    test('contains exactly 398 neighborhoods', () {
      expect(saltaNeighborhoods.length, 398);
    });

    test('contains required representative neighborhoods', () {
      final requiredNeighborhoods = [
        'Centro',
        'Grand Bourg',
        'Tres Cerritos',
        'Intersindical',
        'Limache',
        'Ciudad del Milagro',
        'San Lorenzo',
      ];
      for (final neighborhood in requiredNeighborhoods) {
        expect(saltaNeighborhoods.contains(neighborhood), isTrue,
            reason: '$neighborhood should be in the list of neighborhoods');
      }
    });
  });
}
