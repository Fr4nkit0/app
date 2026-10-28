import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';

void main() {
  test('lib/ has no raw Color(0x...) outside lib/core/theme', () {
    final raw = RegExp(r'Color\(\s*0x', caseSensitive: false);
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;
      if (entity.path.startsWith('lib/core/theme/')) continue;

      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (raw.hasMatch(lines[i])) offenders.add('${entity.path}:${i + 1}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use design tokens:\n${offenders.join('\n')}',
    );
  });

  test('warning token: light is the constant, dark differs', () {
    expect(MarilinTokens.light.warning, MarilinColors.warning);
    expect(MarilinTokens.dark.warning, isNot(MarilinColors.warning));
  });
}
