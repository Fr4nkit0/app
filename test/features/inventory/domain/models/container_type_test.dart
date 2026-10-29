import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/inventory/domain/models/container_type.dart';

void main() {
  test('the label is the catalog description', () {
    expect(
      ContainerType.fromCatalog(
        id: 1,
        code: 'BIDON_20L',
        description: 'Bidón 20L',
      ).label,
      'Bidón 20L',
    );
  });

  test('the label falls back to the code when the description is null', () {
    expect(
      ContainerType.fromCatalog(
        id: 1,
        code: 'BIDON_20L',
        description: null,
      ).label,
      'BIDON_20L',
    );
  });

  test('the label falls back to the code when the description is blank', () {
    expect(
      ContainerType.fromCatalog(
        id: 2,
        code: 'SIFON_2L',
        description: '  ',
      ).label,
      'SIFON_2L',
    );
  });

  test('two types with the same id, code and label are equal', () {
    expect(
      const ContainerType(id: 1, code: 'BIDON_20L', label: 'Bidón 20L'),
      const ContainerType(id: 1, code: 'BIDON_20L', label: 'Bidón 20L'),
    );
  });
}
