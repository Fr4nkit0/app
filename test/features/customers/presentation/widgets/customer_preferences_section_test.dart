import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/widgets/customer_preferences_section.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('cust-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
          ),
        );
    for (final (id, day, start, end, enabled) in [
      ('p-1', 1, '09:00', '12:00', true),
      ('p-2', 4, '14:00', '17:00', true),
      ('p-off', 2, '10:00', '11:00', false),
    ]) {
      await db
          .into(db.customerPreferenceTable)
          .insert(
            CustomerPreferenceTableCompanion.insert(
              customerPreferenceId: drift.Value(id),
              customerId: const drift.Value('cust-1'),
              dayOfWeek: drift.Value(day),
              timeWindowStart: start,
              timeWindowEnd: drift.Value(end),
              enabled: drift.Value(enabled),
            ),
          );
    }
  });
  tearDown(() => db.close());

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: CustomerPreferencesSection(customerId: 'cust-1'),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
  }

  // Drift schedules a zero-duration timer when a watched query is cancelled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  Future<CustomerPreferenceTableData> row(
    WidgetTester tester,
    String id,
  ) async => (await tester.runAsync(
    () => (db.select(
      db.customerPreferenceTable,
    )..where((t) => t.customerPreferenceId.equals(id))).getSingle(),
  ))!;

  Future<List<PendingChangeTableData>> queued(WidgetTester tester) async =>
      (await tester.runAsync(() => db.select(db.pendingChangeTable).get()))!;

  Finder optionsOf(String day) => find.descendant(
    of: find.ancestor(
      of: find.text(day),
      matching: find.byKey(const ValueKey('preference_card')),
    ),
    matching: find.byTooltip('Opciones de horario'),
  );

  Future<void> pickDay(WidgetTester tester, String from, String to) async {
    await tester.tap(find.text(from).last);
    await settle(tester);
    await tester.tap(find.text(to).last);
    await settle(tester);
  }

  testWidgets('lists the enabled preferences by day with their window', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.text('Lunes'), findsOneWidget);
    expect(find.text('Jueves'), findsOneWidget);
    expect(find.text('Martes'), findsNothing);
    expect(find.text('de 09:00 a 12:00 hs'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Lunes')).dy,
      lessThan(tester.getTopLeft(find.text('Jueves')).dy),
    );
    await unmount(tester);
  });

  testWidgets('adds a preference from the dialog', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Agregar preferencia'));
    await settle(tester);
    expect(find.text('Agregar Preferencia Horaria'), findsOneWidget);
    await pickDay(tester, 'Lunes', 'Miércoles');
    await tester.tap(find.text('Agregar horario'));
    await settle(tester);

    expect(find.text('Agregar Preferencia Horaria'), findsNothing);
    expect(find.text('Miércoles'), findsOneWidget);
    final added = (await tester.runAsync(
      () => (db.select(
        db.customerPreferenceTable,
      )..where((t) => t.dayOfWeek.equals(3))).getSingle(),
    ))!;
    expect(added.timeWindowStart, '09:00');
    expect(added.timeWindowEnd, '12:00');
    final change = (await queued(tester)).single;
    expect(change.entity, PendingEntity.customerPreference.wireName);
    expect(change.entityId, added.customerPreferenceId);
    await unmount(tester);
  });

  testWidgets('shows why a taken day and start is refused', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Agregar preferencia'));
    await settle(tester);
    await tester.tap(find.text('Agregar horario'));
    await settle(tester);

    expect(
      find.text('El cliente ya tiene una preferencia para ese día y horario.'),
      findsOneWidget,
    );
    expect(await queued(tester), isEmpty);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  testWidgets('edits a preference from the dialog', (tester) async {
    await pumpSection(tester);

    await tester.tap(optionsOf('Jueves'));
    await settle(tester);
    await tester.tap(find.text('Editar'));
    await settle(tester);
    expect(find.text('Editar horario'), findsOneWidget);

    await pickDay(tester, 'Jueves', 'Viernes');
    await tester.tap(find.text('Guardar cambios'));
    await settle(tester);

    expect(find.text('Viernes'), findsOneWidget);
    expect(find.text('Jueves'), findsNothing);
    final edited = await row(tester, 'p-2');
    expect(edited.dayOfWeek, 5);
    expect(edited.timeWindowStart, '14:00');
    expect((await queued(tester)).single.entityId, 'p-2');
    await unmount(tester);
  });

  testWidgets('disables a preference after confirming', (tester) async {
    await pumpSection(tester);

    await tester.tap(optionsOf('Jueves'));
    await settle(tester);
    await tester.tap(find.text('Dar de baja'));
    await settle(tester);
    expect(find.text('¿Dar de baja este horario?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await settle(tester);
    expect((await row(tester, 'p-2')).enabled, isTrue);

    await tester.tap(optionsOf('Jueves'));
    await settle(tester);
    await tester.tap(find.text('Dar de baja'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await settle(tester);

    expect((await row(tester, 'p-2')).enabled, isFalse);
    expect(find.text('Jueves'), findsNothing);
    expect((await queued(tester)).single.entityId, 'p-2');
    await unmount(tester);
  });
}
