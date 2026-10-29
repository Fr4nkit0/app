import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Container types come from the server catalog; only the legacy name guess
/// may still name container codes (until Fr4nkit0/server#1 ships).
void main() {
  test('container codes appear only in the legacy name guess', () {
    final codes = RegExp('BIDON_20L|SIFON_2L');
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            codes.hasMatch(file.readAsStringSync()))
          file.path.replaceAll(r'\', '/'),
    ];

    expect(offenders, [
      'lib/features/inventory/domain/legacy_container_type.dart',
    ]);
  });
}
