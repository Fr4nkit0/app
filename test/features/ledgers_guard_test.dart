import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// D10 and ADR 0003: each ledger has one module that owns its table, so the
/// reconciliation rule cannot be bypassed. The database itself only
/// registers the tables.
void main() {
  List<File> dartFiles(String root) => [
    for (final entity in Directory(root).listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('.g.dart'))
        entity,
  ];

  String path(File file) => file.path.replaceAll(r'\', '/');

  test('only CustomerAccount touches the customer balance table', () {
    final table = RegExp(r'\bcustomerBalanceTable\b');
    final touching = [
      for (final file in dartFiles('lib'))
        if (table.hasMatch(file.readAsStringSync())) path(file),
    ];

    expect(
      touching,
      unorderedEquals([
        'lib/core/services/database.helper.dart',
        'lib/features/payments/data/repositories/customer_account.dart',
      ]),
    );
  });

  test('only Custody writes the customer container balance table', () {
    final write = RegExp(
      r'\b(into|update|delete)\(\s*\w*\.?customerContainerBalanceTable\b',
    );
    final writing = [
      for (final file in dartFiles('lib'))
        if (write.hasMatch(file.readAsStringSync())) path(file),
    ];

    expect(writing, ['lib/features/inventory/data/repositories/custody.dart']);
  });
}
