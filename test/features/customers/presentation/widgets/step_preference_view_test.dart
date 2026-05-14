import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/presentation/widgets/step_preference_view.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';

void main() {
  testWidgets('StepPreferenceView renders multiple preferences', (
    WidgetTester tester,
  ) async {
    final preferences = [
      CustomerPreference(
        id: '1',
        dayOfWeek: 1,
        timeWindowStart: '08:00',
        timeWindowEnd: '12:00',
      ),
      CustomerPreference(
        id: '2',
        dayOfWeek: 2,
        timeWindowStart: '14:00',
        timeWindowEnd: '18:00',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepPreferenceView(
            preferences: preferences,
            onAddPreference: () {},
            onRemovePreference: (id) {},
            onPreferenceChanged:
                (id, {dayOfWeek, timeWindowStart, timeWindowEnd}) {},
          ),
        ),
      ),
    );

    // Verify it renders "Preferencias"
    expect(find.text('Preferencias'), findsOneWidget);

    // Verify it renders two sets of fields (day dropdowns, time inputs)
    // There should be 2 dropdowns with Lunes and Martes
    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('Martes'), findsOneWidget);

    // Verify time windows
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('14:00'), findsOneWidget);
  });

  testWidgets('StepPreferenceView triggers onAddPreference', (
    WidgetTester tester,
  ) async {
    bool addTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepPreferenceView(
            preferences: const [],
            onAddPreference: () => addTriggered = true,
            onRemovePreference: (id) {},
            onPreferenceChanged:
                (id, {dayOfWeek, timeWindowStart, timeWindowEnd}) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_rounded));
    expect(addTriggered, true);
  });
}
