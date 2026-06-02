import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/product_chip.dart';

void main() {
  group('ProductChip', () {
    testWidgets('renders default layout correctly when unselected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProductChip(label: 'Soda')),
        ),
      );

      const blue = Color(0xFF1565C0);
      expect(find.text('Soda'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(blue.withValues(alpha: 0.1)));
      expect(decoration?.borderRadius, equals(BorderRadius.circular(20)));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, equals(blue));
      expect(text.style?.fontSize, equals(12.0));
      expect(text.style?.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('renders default layout correctly when selected', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProductChip(label: 'Soda', selected: true)),
        ),
      );

      const blue = Color(0xFF1565C0);
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(blue));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, equals(Colors.white));
    });

    testWidgets('respects customization parameters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductChip(
              label: 'Soda',
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(10),
              backgroundColor: Colors.purple,
              borderColor: Colors.amber,
              borderWidth: 3.0,
              textColor: Colors.red,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              icon: Icons.ac_unit,
              iconSize: 20,
              iconColor: Colors.yellow,
              showIcon: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.padding, equals(const EdgeInsets.all(12)));

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.purple));
      expect(decoration?.borderRadius, equals(BorderRadius.circular(10)));
      final border = decoration!.border as Border;
      expect(border.top.color, equals(Colors.amber));
      expect(border.top.width, equals(3.0));

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, equals(Colors.red));
      expect(text.style?.fontSize, equals(15.0));
      expect(text.style?.fontWeight, equals(FontWeight.bold));

      expect(find.byIcon(Icons.ac_unit), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.ac_unit));
      expect(icon.size, equals(20));
      expect(icon.color, equals(Colors.yellow));
    });

    testWidgets('hides icon when showIcon is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProductChip(label: 'Soda', showIcon: false)),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });
  });
}
