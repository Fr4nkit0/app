import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every IconButton under lib/ declares a tooltip', () {
    final failures = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('IconButton(')) continue;
        final end = (i + 7).clamp(0, lines.length);
        final window = lines.sublist(i, end).join('\n');
        if (!window.contains('tooltip:')) {
          failures.add('${file.path}:${i + 1}');
        }
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'IconButton without tooltip:\n${failures.join('\n')}',
    );
  });
}
