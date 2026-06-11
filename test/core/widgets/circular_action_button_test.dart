import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/circular_action_button.dart';

void main() {
  group('CircularActionButton', () {
    testWidgets('should render icon and handle taps', (
      WidgetTester tester,
    ) async {
      var pressedCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              icon: Icons.add,
              onPressed: () => pressedCount++,
            ),
          ),
        ),
      );

      // Verify icon exists
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Verify no label by default
      expect(find.byType(Text), findsNothing);

      // Tap the button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(pressedCount, equals(1));
    });

    testWidgets('should render label if provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              icon: Icons.add,
              onPressed: () {},
              label: 'Test Label',
            ),
          ),
        ),
      );

      // Verify icon and label exist
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Test Label'), findsOneWidget);
    });

    testWidgets('should respect custom color', (WidgetTester tester) async {
      const customColor = Colors.purple;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CircularActionButton(
              icon: Icons.add,
              onPressed: () {},
              color: customColor,
            ),
          ),
        ),
      );

      // Let's verify that the container or CircleAvatar or widget has customColor.
      // We'll assert this in the widget tree structure.
      final container = tester.widget<Container>(
        find
            .ancestor(
              of: find.byIcon(Icons.add),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(customColor.withValues(alpha: 0.12)));
    });
  });
}
