import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

void main() {
  testWidgets(
    'AmountField shows label, prefix, numeric keyboard and onChanged',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [MarilinTokens.light]),
          home: Scaffold(
            body: AmountField(
              label: 'Efectivo',
              controller: controller,
              onChanged: changes.add,
            ),
          ),
        ),
      );

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(find.text('Efectivo'), findsOneWidget);
      expect(field.decoration!.prefixText, '\$ ');
      expect(
        field.keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );

      await tester.enterText(find.byType(TextField), '125.5');
      expect(changes, ['125.5']);
      expect(controller.text, '125.5');
    },
  );

  group('AmountField.parseAmount', () {
    test('normalizes the decimal separator', () {
      expect(AmountField.parseAmount('1500'), 1500);
      expect(AmountField.parseAmount('1500,50'), 1500.5);
      expect(AmountField.parseAmount('1500.50'), 1500.5);
    });

    test('returns null for empty or invalid input', () {
      expect(AmountField.parseAmount(''), isNull);
      expect(AmountField.parseAmount('abc'), isNull);
      expect(AmountField.parseAmount('1.500,50'), isNull);
    });
  });

  group('AmountField input', () {
    Future<List<String>> pump(
      WidgetTester tester,
      TextEditingController controller,
    ) async {
      final changes = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: const [MarilinTokens.light]),
          home: Scaffold(
            body: AmountField(
              label: 'Efectivo',
              controller: controller,
              onChanged: changes.add,
            ),
          ),
        ),
      );
      return changes;
    }

    testWidgets('accepts a comma decimal separator without error', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = await pump(tester, controller);

      await tester.enterText(find.byType(TextField), '1500,50');
      await tester.pump();

      expect(changes, ['1500,50']);
      expect(controller.text, '1500,50');
      expect(find.text('Ingresá un monto válido'), findsNothing);
    });

    testWidgets('shows an inline error for invalid non-empty text', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, controller);

      // A trailing separator is still being typed: no error yet.
      await tester.enterText(find.byType(TextField), '1,');
      await tester.pump();
      expect(find.text('Ingresá un monto válido'), findsNothing);

      // Text the formatter cannot stop (set programmatically) still errors.
      controller.text = '1,2,3';
      await tester.pump();
      expect(find.text('Ingresá un monto válido'), findsOneWidget);
    });
  });
}
