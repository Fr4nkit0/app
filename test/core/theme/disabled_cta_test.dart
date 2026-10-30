import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/marilin_tokens.dart';

void main() {
  for (final (name, theme, tokens) in [
    ('light', AppTheme.lightTheme, MarilinTokens.light),
    ('dark', AppTheme.darkTheme, MarilinTokens.dark),
  ]) {
    testWidgets('a disabled filled button stays visible in $name', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: Center(
              child: FilledButton(onPressed: null, child: Text('Continuar')),
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, tokens.fill);
      expect(material.textStyle?.color, tokens.textMuted);
      final side = (material.shape! as OutlinedBorder).side;
      expect(side.color, tokens.lineStrong);
      expect(side.width, 1.5);
    });
  }

  test('navigation bar labels are 13sp in both states', () {
    final style = AppTheme.lightTheme.navigationBarTheme.labelTextStyle!;
    final selected = style.resolve({WidgetState.selected})!;
    final unselected = style.resolve({})!;
    expect(selected.fontSize, 13);
    expect(selected.fontWeight, FontWeight.w600);
    expect(unselected.fontSize, 13);
    expect(unselected.fontWeight, FontWeight.w500);
  });
}
