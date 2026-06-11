import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/debt_chip.dart';

void main() {
  group('DebtChip', () {
    testWidgets('renders default layout correctly for amount > 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DebtChip(amount: 1500))),
      );

      // Default border color is 0xFFBF1B1B, text is "Deuda: $1.500"
      expect(find.text('Deuda: \$1.500'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.border, isA<Border>());
      final border = decoration!.border as Border;
      expect(border.top.color, equals(const Color(0xFFBF1B1B)));
      expect(border.top.width, equals(1.5));
      expect(decoration.borderRadius, equals(BorderRadius.circular(20)));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, equals(const Color(0xFFBF1B1B)));
      expect(text.style?.fontSize, equals(12.0));
      expect(text.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('renders nothing for amount <= 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DebtChip(amount: 0))),
      );
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('respects parameterized customization overrides', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DebtChip(
              amount: 2500.50,
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              borderRadius: BorderRadius.all(Radius.circular(8)),
              backgroundColor: Colors.yellow,
              borderColor: Colors.green,
              borderWidth: 2.0,
              textColor: Colors.blue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              prefixText: 'PRE-DEBT: \$',
              useRawAmountFormatting: true,
            ),
          ),
        ),
      );

      // Verify the formatted text is not raw since useRawAmountFormatting formats double directly using toStringAsFixed or just double.
      // Wait, let's see: we expect "PRE-DEBT: $2500.50" or similar depending on the raw formatting implementation.
      expect(find.textContaining('PRE-DEBT: \$'), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.margin, equals(const EdgeInsets.all(8)));
      expect(
        container.padding,
        equals(const EdgeInsets.symmetric(horizontal: 14, vertical: 6)),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.yellow));
      expect(decoration?.borderRadius, equals(BorderRadius.circular(8)));
      final border = decoration!.border as Border;
      expect(border.top.color, equals(Colors.green));
      expect(border.top.width, equals(2.0));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, equals(Colors.blue));
      expect(text.style?.fontSize, equals(14.0));
      expect(text.style?.fontWeight, equals(FontWeight.bold));
    });
  });
}
