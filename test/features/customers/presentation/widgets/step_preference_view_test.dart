import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/presentation/widgets/step_preference_view.dart';

void main() {
  testWidgets('preference card controls are at least 48dp with 22dp icons', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepPreferenceView(
            preferences: [
              CustomerPreference(
                id: 'p-1',
                dayOfWeek: 1,
                timeWindowStart: '08:00',
                timeWindowEnd: '12:00',
              ),
            ],
            onAddPreference: () {},
            onRemovePreference: (_) {},
            onPreferenceChanged:
                (id, {dayOfWeek, timeWindowStart, timeWindowEnd}) {},
            onNewPreferenceSaved: (_, __, ___) {},
          ),
        ),
      ),
    );

    final leading = tester.getSize(
      find
          .ancestor(
            of: find.byIcon(Icons.schedule_rounded),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(leading.width, greaterThanOrEqualTo(48));
    expect(leading.height, greaterThanOrEqualTo(48));
    expect(tester.widget<Icon>(find.byIcon(Icons.schedule_rounded)).size, 22);

    final remove = find.byTooltip('Quitar');
    expect(remove, findsOneWidget);
    final removeSize = tester.getSize(remove);
    expect(removeSize.width, greaterThanOrEqualTo(48));
    expect(removeSize.height, greaterThanOrEqualTo(48));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.delete_outline_rounded)).size,
      22,
    );
  });
}
