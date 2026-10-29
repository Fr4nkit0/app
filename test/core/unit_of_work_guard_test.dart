import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADR 0001 and 0002: use cases own the unit of work and failures are thrown
/// as DomainFailure, never wrapped in a Resource.
void main() {
  List<File> dartFiles(String root) => [
    for (final entity in Directory(root).listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('.g.dart'))
        entity,
  ];

  String path(File file) => file.path.replaceAll(r'\', '/');

  test('no repository under lib/features/**/data/ opens a transaction', () {
    final offenders = [
      for (final file in dartFiles('lib/features'))
        if (path(file).contains('/data/') &&
            file.readAsStringSync().contains('.transaction('))
          path(file),
    ];

    expect(offenders, isEmpty);
  });

  test('Resource does not come back under lib/', () {
    final resource = RegExp(r'\bResource\b');
    final offenders = [
      for (final file in dartFiles('lib'))
        if (resource.hasMatch(file.readAsStringSync())) path(file),
    ];

    expect(offenders, isEmpty);
  });
}
