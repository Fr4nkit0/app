import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Container types come only from the server catalog, so no code under lib/
/// may name a container code.
void main() {
  test('no container code is named under lib/', () {
    final codes = RegExp('BIDON_20L|SIFON_2L');
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            codes.hasMatch(file.readAsStringSync()))
          file.path.replaceAll(r'\', '/'),
    ];

    expect(offenders, isEmpty);
  });
}
