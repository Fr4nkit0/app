import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/core_search_bar.dart';

void main() {
  group('CoreSearchBar Widget Tests', () {
    late TextEditingController controller;
    late List<String> onChangedValues;
    late int clearCallCount;

    setUp(() {
      controller = TextEditingController();
      onChangedValues = [];
      clearCallCount = 0;
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders hintText correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreSearchBar(
              controller: controller,
              onChanged: (val) => onChangedValues.add(val),
              hintText: 'Search customers...',
            ),
          ),
        ),
      );

      expect(find.text('Search customers...'), findsOneWidget);
    });

    testWidgets('triggers onChanged when typing', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreSearchBar(
              controller: controller,
              onChanged: (val) => onChangedValues.add(val),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'John Doe');
      expect(onChangedValues, ['John Doe']);
      expect(controller.text, 'John Doe');
    });

    testWidgets('respects focusedBorderColor and fillColor decoration', (
      WidgetTester tester,
    ) async {
      const customFocusColor = Colors.purple;
      const customFillColor = Colors.amber;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreSearchBar(
              controller: controller,
              onChanged: (val) => onChangedValues.add(val),
              focusedBorderColor: customFocusColor,
              fillColor: customFillColor,
            ),
          ),
        ),
      );

      final TextField textField = tester.widget(find.byType(TextField));
      final decoration = textField.decoration;

      expect(decoration?.fillColor, customFillColor);
      expect(decoration?.filled, true);

      final focusedBorder = decoration?.focusedBorder as OutlineInputBorder?;
      expect(focusedBorder?.borderSide.color, customFocusColor);
    });

    testWidgets('shows default and custom prefixIcon correctly', (
      WidgetTester tester,
    ) async {
      // Default prefix icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreSearchBar(
              controller: controller,
              onChanged: (val) => onChangedValues.add(val),
            ),
          ),
        ),
      );

      final defaultTextField = tester.widget<TextField>(find.byType(TextField));
      expect(
        (defaultTextField.decoration?.prefixIcon as Icon?)?.icon,
        Icons.search,
      );

      // Custom prefix icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreSearchBar(
              controller: controller,
              onChanged: (val) => onChangedValues.add(val),
              prefixIcon: const Icon(Icons.star),
            ),
          ),
        ),
      );

      final customTextField = tester.widget<TextField>(find.byType(TextField));
      expect(
        (customTextField.decoration?.prefixIcon as Icon?)?.icon,
        Icons.star,
      );
    });

    testWidgets('displays clear button and triggers onClear when pressed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreSearchBar(
              controller: controller,
              onChanged: (val) => onChangedValues.add(val),
              onClear: () => clearCallCount++,
            ),
          ),
        ),
      );

      // Suffix icon (clear button) should be displayed
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.suffixIcon, isNotNull);

      // Tap the clear button (inside suffixIcon)
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(clearCallCount, 1);
    });
  });
}
