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

  testWidgets('a taken day and start keeps the dialog open until changed', (
    tester,
  ) async {
    final added = <(int, String, String)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepPreferenceView(
            preferences: [
              CustomerPreference(
                id: 'p-1',
                dayOfWeek: 1,
                timeWindowStart: '09:00',
                timeWindowEnd: '12:00',
              ),
            ],
            onAddPreference: () {},
            onRemovePreference: (_) {},
            onPreferenceChanged:
                (id, {dayOfWeek, timeWindowStart, timeWindowEnd}) {},
            onNewPreferenceSaved: (day, start, end) =>
                added.add((day, start, end)),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Agregar otro horario'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar horario'));
    await tester.pumpAndSettle();

    expect(
      find.text('El cliente ya tiene una preferencia para ese día y horario.'),
      findsOneWidget,
    );
    expect(find.text('Agregar Preferencia Horaria'), findsOneWidget);
    expect(added, isEmpty);

    await tester.tap(find.text('Lunes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Martes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar horario'));
    await tester.pumpAndSettle();

    expect(find.text('Agregar Preferencia Horaria'), findsNothing);
    expect(added, [(2, '09:00', '12:00')]);
  });

  testWidgets('editing a preference into its own slot is not a duplicate', (
    tester,
  ) async {
    final changed = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StepPreferenceView(
            preferences: [
              CustomerPreference(
                id: 'p-1',
                dayOfWeek: 1,
                timeWindowStart: '09:00',
                timeWindowEnd: '12:00',
              ),
            ],
            onAddPreference: () {},
            onRemovePreference: (_) {},
            onPreferenceChanged:
                (id, {dayOfWeek, timeWindowStart, timeWindowEnd}) =>
                    changed.add(id),
            onNewPreferenceSaved: (_, _, _) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Lunes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Editar horario'), findsNothing);
    expect(changed, ['p-1']);
  });
}
