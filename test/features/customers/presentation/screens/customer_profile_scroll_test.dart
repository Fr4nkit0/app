import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';

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
            name: 'Sanatorio',
            serverId: const drift.Value(10),
          ),
        );
    for (final (id, street, primary) in [
      ('a-1', 'Belgrano 1200', true),
      ('a-2', 'Mitre 50', false),
      ('a-3', 'Caseros 9', false),
      ('a-4', 'Urquiza 300', false),
    ]) {
      await db
          .into(db.customerAddressTable)
          .insert(
            CustomerAddressTableCompanion.insert(
              addressId: drift.Value(id),
              customerId: const drift.Value('cust-1'),
              street: drift.Value(street),
              neighborhood: const drift.Value('Centro'),
              isPrimary: drift.Value(primary),
            ),
          );
    }
    for (final (id, day, start) in [
      ('p-2', 2, '09:00'),
      ('p-3', 3, '09:00'),
      ('p-4', 4, '09:00'),
      ('p-5', 5, '09:00'),
      ('p-6', 3, '14:00'),
      ('p-7', 4, '14:00'),
      ('p-8', 5, '14:00'),
    ]) {
      await db
          .into(db.customerPreferenceTable)
          .insert(
            CustomerPreferenceTableCompanion.insert(
              customerPreferenceId: drift.Value(id),
              customerId: const drift.Value('cust-1'),
              dayOfWeek: drift.Value(day),
              timeWindowStart: start,
            ),
          );
    }
  });
  tearDown(() => db.close());

  Future<void> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CustomerProfileScreen(customerId: 'cust-1'),
        ),
      ),
    );
    await settle(tester);
  }

  /// Renders frame by frame, without real-time gaps, so a one-frame loading
  /// state between the write and the reloaded customer is drawn.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
    await settle(tester);
  }

  // Drift schedules a zero-duration timer when a watched query is cancelled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  ScrollPosition profileScroll(WidgetTester tester) => tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;

  /// Scrolls until [section] sits under the app bar, hiding the header.
  Future<double> scrollTo(WidgetTester tester, String section) async {
    final position = profileScroll(tester);
    position.jumpTo(
      position.pixels + tester.getTopLeft(find.text(section)).dy - 72,
    );
    await tester.pump();
    final offset = profileScroll(tester).pixels;
    expect(offset, greaterThan(0));
    expect(find.text('Sanatorio').hitTestable(), findsNothing);
    return offset;
  }

  Finder addressOptions(String street) => find.descendant(
    of: find.ancestor(
      of: find.textContaining(street),
      matching: find.byKey(const ValueKey('address_card')),
    ),
    matching: find.byTooltip('Opciones de dirección'),
  );

  Finder preferenceOptions(String day) => find.descendant(
    of: find.ancestor(
      of: find.text(day),
      matching: find.byKey(const ValueKey('preference_card')),
    ),
    matching: find.byTooltip('Opciones de horario'),
  );

  Future<CustomerAddressTableData> address(
    WidgetTester tester,
    String id,
  ) async => (await tester.runAsync(
    () => (db.select(
      db.customerAddressTable,
    )..where((t) => t.addressId.equals(id))).getSingle(),
  ))!;

  Future<CustomerPreferenceTableData> preference(
    WidgetTester tester,
    String id,
  ) async => (await tester.runAsync(
    () => (db.select(
      db.customerPreferenceTable,
    )..where((t) => t.customerPreferenceId.equals(id))).getSingle(),
  ))!;

  void expectStillScrolled(WidgetTester tester, double offset) {
    expect(profileScroll(tester).pixels, offset);
    expect(find.text('Sanatorio').hitTestable(), findsNothing);
  }

  testWidgets('marking the primary address keeps the scroll position', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Datos'));
    await settle(tester);
    final offset = await scrollTo(tester, 'Direcciones de entrega');

    await tester.tap(addressOptions('Mitre 50'));
    await settle(tester);
    await tester.tap(find.text('Marcar como principal'));
    await pumpFrames(tester);

    expect((await address(tester, 'a-2')).isPrimary, isTrue);
    expectStillScrolled(tester, offset);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  testWidgets('adding a preference keeps the scroll position', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Preferencias'));
    await settle(tester);
    final offset = await scrollTo(tester, 'Horarios de Visita Preferidos');

    await tester.tap(find.text('Agregar preferencia'));
    await settle(tester);
    await tester.tap(find.text('Agregar horario'));
    await pumpFrames(tester);

    final added = await tester.runAsync(
      () => (db.select(
        db.customerPreferenceTable,
      )..where((t) => t.dayOfWeek.equals(1))).get(),
    );
    expect(added, hasLength(1));
    expectStillScrolled(tester, offset);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  testWidgets('disabling an address keeps the scroll position', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Datos'));
    await settle(tester);
    final offset = await scrollTo(tester, 'Direcciones de entrega');

    await tester.tap(addressOptions('Mitre 50'));
    await settle(tester);
    await tester.tap(find.text('Dar de baja'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await pumpFrames(tester);

    expect((await address(tester, 'a-2')).enabled, isFalse);
    expectStillScrolled(tester, offset);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  testWidgets('editing a preference keeps the scroll position', (tester) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Preferencias'));
    await settle(tester);
    final offset = await scrollTo(tester, 'Horarios de Visita Preferidos');

    await tester.tap(preferenceOptions('Martes'));
    await settle(tester);
    await tester.tap(find.text('Editar'));
    await settle(tester);
    await tester.tap(find.text('Martes').last);
    await settle(tester);
    await tester.tap(find.text('Sábado').last);
    await settle(tester);
    await tester.tap(find.text('Guardar cambios'));
    await pumpFrames(tester);

    expect((await preference(tester, 'p-2')).dayOfWeek, 6);
    expectStillScrolled(tester, offset);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  testWidgets('disabling a preference keeps the scroll position', (
    tester,
  ) async {
    await pumpProfile(tester);
    await tester.tap(find.text('Preferencias'));
    await settle(tester);
    final offset = await scrollTo(tester, 'Horarios de Visita Preferidos');

    await tester.tap(preferenceOptions('Martes'));
    await settle(tester);
    await tester.tap(find.text('Dar de baja'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await pumpFrames(tester);

    expect((await preference(tester, 'p-2')).enabled, isFalse);
    expectStillScrolled(tester, offset);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  group(
    'scrolled to the end, the Nueva Venta button leaves the last options menu reachable',
    () {
      for (final (tab, tooltip) in [
        ('Datos', 'Opciones de dirección'),
        ('Preferencias', 'Opciones de horario'),
      ]) {
        testWidgets('$tooltip in $tab', (tester) async {
          await pumpProfile(tester);
          await tester.tap(find.text(tab));
          await settle(tester);

          // Scrolled to the end, the last menu sits above the button.
          final position = profileScroll(tester);
          position.jumpTo(position.maxScrollExtent);
          await tester.pump();

          final fab = tester.getRect(find.byType(FloatingActionButton));
          final menus = find.byTooltip(tooltip);
          expect(menus, findsWidgets);
          final last = menus.last;
          expect(tester.getRect(last).overlaps(fab), isFalse);
          expect(last.hitTestable(), findsOneWidget);

          await tester.tap(last);
          await settle(tester);
          expect(find.text('Dar de baja'), findsWidgets);

          await tester.pump(const Duration(seconds: 5));
          await unmount(tester);
        });
      }
    },
  );
}
