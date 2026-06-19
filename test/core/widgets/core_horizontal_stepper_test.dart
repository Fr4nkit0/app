import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/widgets/core_horizontal_stepper.dart';

void main() {
  group('CoreHorizontalStepper Widget Tests', () {
    final List<String> steps = ['Step One', 'Step Two', 'Step Three'];

    testWidgets('renders all steps and dividers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreHorizontalStepper(currentStep: 1, steps: steps),
          ),
        ),
      );

      // Verify step labels are rendered
      expect(find.text('Step One'), findsOneWidget);
      expect(find.text('Step Two'), findsOneWidget);
      expect(find.text('Step Three'), findsOneWidget);

      // Verify step numbers or checkmarks
      // For currentStep = 1:
      // Step index 0 is completed -> checkmark icon.
      // Step index 1 is active -> text '2'.
      // Step index 2 is inactive -> text '3'.
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'shows loading indicator on active step when isSubmitting is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoreHorizontalStepper(
                currentStep: 1,
                steps: steps,
                isSubmitting: true,
              ),
            ),
          ),
        );

        // Active step is index 1 (Step Two, normally shows '2')
        // Since isSubmitting is true, it should show a CircularProgressIndicator instead of '2'
        expect(find.text('2'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('respects custom activeColor and inactiveColor', (
      WidgetTester tester,
    ) async {
      const customActiveColor = Colors.green;
      const customInactiveColor = Colors.orange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreHorizontalStepper(
              currentStep: 1,
              steps: steps,
              activeColor: customActiveColor,
              inactiveColor: customInactiveColor,
            ),
          ),
        ),
      );

      // We can verify colors of the animated containers or the dividers.
      // Let's verify by finding the divider container decorations or container colors.
      // Step 0-1 divider is active -> color customActiveColor
      // Step 1-2 divider is inactive -> color customInactiveColor

      final dividers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(Row),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Container && widget.constraints?.maxHeight == 2,
          ),
        ),
      );

      expect(dividers.length, 2);
      expect(
        (dividers.first.decoration as BoxDecoration?)?.color ??
            dividers.first.color,
        customActiveColor,
      );
      expect(
        (dividers.last.decoration as BoxDecoration?)?.color ??
            dividers.last.color,
        customInactiveColor,
      );
    });

    testWidgets('renders step descriptions when stepDescriptions is provided', (
      WidgetTester tester,
    ) async {
      final descriptions = ['Desc One', 'Desc Two', 'Desc Three'];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreHorizontalStepper(
              currentStep: 1,
              steps: steps,
              stepDescriptions: descriptions,
            ),
          ),
        ),
      );

      // Verify description labels are rendered
      expect(find.text('Desc One'), findsOneWidget);
      expect(find.text('Desc Two'), findsOneWidget);
      expect(find.text('Desc Three'), findsOneWidget);
    });

    testWidgets(
      'renders step descriptions when stepDescriptions has fewer items than steps',
      (WidgetTester tester) async {
        final descriptions = ['Desc One', 'Desc Two'];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CoreHorizontalStepper(
                currentStep: 1,
                steps: steps,
                stepDescriptions: descriptions,
              ),
            ),
          ),
        );

        // Verify first two description labels are rendered
        expect(find.text('Desc One'), findsOneWidget);
        expect(find.text('Desc Two'), findsOneWidget);
        // Verify third is not rendered and does not crash
        expect(find.text('Desc Three'), findsNothing);
      },
    );

    testWidgets('renders horizontal layout when layoutRow is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CoreHorizontalStepper(
              currentStep: 1,
              steps: steps,
              layoutRow: true,
            ),
          ),
        ),
      );

      // We expect each step to render as a Row containing a circle dot and a Column of texts.
      // Find the step Row by checking for a Row containing the circle container.
      final stepRowFinder = find.byWidgetPredicate((widget) {
        return widget is Row &&
            widget.children.any(
              (child) =>
                  child is AnimatedContainer &&
                  child.decoration is BoxDecoration &&
                  (child.decoration as BoxDecoration).shape == BoxShape.circle,
            );
      });

      expect(stepRowFinder, findsNWidgets(3));
    });
  });
}
