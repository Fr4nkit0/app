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
      expect(field.keyboardType, TextInputType.number);

      await tester.enterText(find.byType(TextField), '125');
      expect(changes, ['125']);
      expect(controller.text, '125');
    },
  );

  group('AmountField.parseAmount', () {
    test('parses whole pesos, dots being thousands separators', () {
      final int? amount = AmountField.parseAmount(' 1500 ');
      expect(amount, 1500);
      expect(AmountField.parseAmount('15.000'), 15000);
      expect(AmountField.parseAmount('340.000'), 340000);
    });

    test('returns null for empty, invalid or non-whole input', () {
      expect(AmountField.parseAmount(''), isNull);
      expect(AmountField.parseAmount('abc'), isNull);
      expect(AmountField.parseAmount('1500,50'), isNull);
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

    testWidgets('groups thousands while typing and drops a comma', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final changes = await pump(tester, controller);

      await tester.enterText(find.byType(TextField), '15000');
      await tester.pump();
      expect(controller.text, '15.000');
      expect(AmountField.parseAmount(controller.text), 15000);

      await tester.enterText(find.byType(TextField), '1500,50');
      await tester.pump();

      expect(changes, ['15.000', '150.050']);
      expect(controller.text, '150.050');
      expect(find.text('Ingresá un monto válido'), findsNothing);
    });

    testWidgets('shows an inline error for invalid non-empty text', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, controller);

      // Text the formatter cannot stop (set programmatically) still errors.
      controller.text = '1,5';
      await tester.pump();
      expect(find.text('Ingresá un monto válido'), findsOneWidget);
    });
  });

  testWidgets('exposes its label to TalkBack', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController(text: '1500');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [MarilinTokens.light]),
        home: Scaffold(
          body: AmountField(label: 'Efectivo', controller: controller),
        ),
      ),
    );

    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Efectivo')));
    expect(node.label, 'Efectivo');
    expect(node.value, '1500');
    expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
    semantics.dispose();
  });
}
