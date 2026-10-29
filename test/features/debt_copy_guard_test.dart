import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// S12: a customer's debt reads "Debe $X" on every screen, never
/// "Deuda: $X" or a negative amount.
void main() {
  test('no screen labels a debt as "Deuda: "', () {
    final offenders = [
      for (final entity in Directory('lib').listSync(recursive: true))
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            entity.readAsStringSync().contains("Deuda: "))
          entity.path,
    ];

    expect(offenders, isEmpty);
  });
}
