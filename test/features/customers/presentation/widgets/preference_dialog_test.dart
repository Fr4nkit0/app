import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/presentation/widgets/preference_dialog.dart';

void main() {
  const endBeforeStart = 'La hora "Hasta" tiene que ser posterior a "Desde".';
  const slotTaken =
      'El cliente ya tiene una preferencia para ese día y horario.';

  late List<(int, String, String)> saved;
  late String? Function(int, String, String) answer;
  bool? result;

  setUp(() {
    saved = [];
    answer = (_, _, _) => null;
    result = null;
  });

  Future<void> openDialog(
    WidgetTester tester, {
    CustomerPreference? existing,
  }) async {
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showPreferenceDialog(
                  context,
                  existing: existing,
                  onSave: (day, start, end) async {
                    final error = answer(day, start, end);
                    if (error == null) saved.add((day, start, end));
                    return error;
                  },
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  CustomerPreference preference(int day, String start, String end) =>
      CustomerPreference(
        id: 'p-1',
        dayOfWeek: day,
        timeWindowStart: start,
        timeWindowEnd: end,
      );

  Future<void> pickDay(WidgetTester tester, String from, String to) async {
    await tester.tap(find.text(from).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(to).last);
    await tester.pumpAndSettle();
  }

  /// Types [hour]:[minute] in the keyboard mode of the picker opened from
  /// the [label] field and confirms it.
  Future<void> typeTime(
    WidgetTester tester,
    String label,
    String hour,
    String minute,
  ) async {
    await tester.tap(find.widgetWithText(InputDecorator, label));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), hour);
    await tester.enterText(fields.at(1), minute);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
  }

  group('S1 validates only that the end is after the start', () {
    testWidgets('saves an unchanged Monday 08:30-13:00 preference', (
      tester,
    ) async {
      await openDialog(tester, existing: preference(1, '08:30', '13:00'));

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(saved, [(1, '08:30', '13:00')]);
      expect(result, isTrue);
      expect(find.text('Editar horario'), findsNothing);
    });

    testWidgets('accepts Saturday 16:00-18:00', (tester) async {
      await openDialog(tester, existing: preference(6, '16:00', '18:00'));

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(saved, [(6, '16:00', '18:00')]);
    });

    testWidgets('refuses an end not after the start with the real cause', (
      tester,
    ) async {
      await openDialog(tester, existing: preference(2, '13:00', '13:00'));

      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text(endBeforeStart), findsOneWidget);
      expect(find.textContaining('L a V'), findsNothing);
      expect(saved, isEmpty);
      expect(find.text('Editar horario'), findsOneWidget);
    });
  });

  group('S2 the time picker is in 24-hour format', () {
    testWidgets('the picker subtree always uses 24-hour format', (
      tester,
    ) async {
      await openDialog(tester);

      await tester.tap(find.widgetWithText(InputDecorator, 'Desde'));
      await tester.pumpAndSettle();

      final picker = tester.element(find.byType(TimePickerDialog));
      expect(MediaQuery.of(picker).alwaysUse24HourFormat, isTrue);
    });

    testWidgets('typing 14:00 in keyboard mode is accepted', (tester) async {
      await openDialog(tester);

      await typeTime(tester, 'Hasta', '14', '00');

      expect(find.byType(TimePickerDialog), findsNothing);
      expect(find.text('14:00'), findsOneWidget);
      await tester.tap(find.text('Agregar horario'));
      await tester.pumpAndSettle();
      expect(saved, [(1, '09:00', '14:00')]);
    });
  });

  testWidgets('the picker speaks one consistent Spanish in es_AR', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('es', 'AR'),
        supportedLocales: const [Locale('es', 'AR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showPreferenceDialog(
                context,
                onSave: (_, _, _) async => null,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InputDecorator, 'Desde'));
    await tester.pumpAndSettle();

    final picker = find.byType(TimePickerDialog);
    Finder inPicker(String text) =>
        find.descendant(of: picker, matching: find.text(text));
    expect(inPicker('Elegí la hora'), findsOneWidget);
    expect(inPicker('Cancelar'), findsOneWidget);
    expect(inPicker('Aceptar'), findsOneWidget);
    expect(inPicker('ACEPTAR'), findsNothing);
  });

  group('S3 a taken slot keeps the dialog open', () {
    testWidgets('shows the reason, keeps the edit, then saves a free slot', (
      tester,
    ) async {
      answer = (day, _, _) => day == 3 ? slotTaken : null;
      await openDialog(tester, existing: preference(1, '08:30', '13:00'));

      await pickDay(tester, 'Lunes', 'Miércoles');
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(find.text(slotTaken), findsOneWidget);
      expect(find.text('Editar horario'), findsOneWidget);
      expect(find.text('Miércoles'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(saved, isEmpty);
      expect(result, isNull);

      await pickDay(tester, 'Miércoles', 'Jueves');
      expect(find.text(slotTaken), findsNothing);
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      expect(saved, [(4, '08:30', '13:00')]);
      expect(result, isTrue);
      expect(find.text('Editar horario'), findsNothing);
    });

    testWidgets('cancelling reports nothing saved', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(saved, isEmpty);
    });
  });

  group('S4 the save label fits its button at 360dp', () {
    for (final (existing, label) in [
      (preference(1, '09:00', '12:00'), 'Guardar cambios'),
      (null, 'Agregar horario'),
    ]) {
      testWidgets('"$label" stays on one line with side padding', (
        tester,
      ) async {
        await openDialog(tester, existing: existing);

        expect(tester.takeException(), isNull);
        final text = find.text(label);
        final button = find.ancestor(
          of: text,
          matching: find.byType(FilledButton),
        );
        final textRect = tester.getRect(text);
        final buttonRect = tester.getRect(button);
        final style = tester.widget<Text>(text).style!;
        expect(textRect.height, lessThan(style.fontSize! * 2));
        expect(textRect.left - buttonRect.left, greaterThanOrEqualTo(16));
        expect(buttonRect.right - textRect.right, greaterThanOrEqualTo(16));
      });
    }
  });
}
