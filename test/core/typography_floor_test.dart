import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no fontSize under lib/ is below the 12sp floor', () {
    const floor = 12.0;
    final pattern = RegExp(r'fontSize:\s*(\d+(?:\.\d+)?)');
    final violations = <String>[];

    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final match in pattern.allMatches(lines[i])) {
          final size = double.parse(match.group(1)!);
          if (size < floor) {
            violations.add('${file.path}:${i + 1} (fontSize: $size)');
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'fontSize below ${floor}sp:\n${violations.join('\n')}',
    );
  });
}
