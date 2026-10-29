import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/inventory/domain/custody.dart';

void main() {
  test('sums the delivered quantity per container code', () {
    expect(
      deliveredByContainerType([
        (containerType: 'JUG', quantity: 2),
        (containerType: 'SIPHON', quantity: 1),
        (containerType: 'JUG', quantity: 3),
      ]),
      {'JUG': 5, 'SIPHON': 1},
    );
  });

  test('items without a container type deliver no containers', () {
    expect(
      deliveredByContainerType([
        (containerType: null, quantity: 4),
        (containerType: 'JUG', quantity: 1),
      ]),
      {'JUG': 1},
    );
  });

  test('omits container types with zero delivered', () {
    expect(
      deliveredByContainerType([
        (containerType: 'JUG', quantity: 0),
        (containerType: 'SIPHON', quantity: 2),
      ]),
      {'SIPHON': 2},
    );
  });

  test('no items deliver nothing', () {
    expect(deliveredByContainerType(const []), isEmpty);
  });
}
