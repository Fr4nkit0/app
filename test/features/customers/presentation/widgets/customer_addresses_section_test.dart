import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/widgets/customer_addresses_section.dart';
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
    for (final (id, street, primary, enabled) in [
      ('a-1', 'Belgrano 1200', true, true),
      ('a-2', 'Mitre 50', false, true),
      ('a-off', 'Caseros 9', false, false),
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
              enabled: drift.Value(enabled),
            ),
          );
    }
    await db
        .into(db.neighborhoodTable)
        .insert(
          NeighborhoodTableCompanion.insert(
            id: const drift.Value(1),
            name: 'Tres Cerritos',
          ),
        );
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
              child: CustomerAddressesSection(customerId: 'cust-1'),
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

  Future<CustomerAddressTableData> row(WidgetTester tester, String id) async =>
      (await tester.runAsync(
        () => (db.select(
          db.customerAddressTable,
        )..where((t) => t.addressId.equals(id))).getSingle(),
      ))!;

  Finder optionsOf(String street) => find.descendant(
    of: find.ancestor(
      of: find.textContaining(street),
      matching: find.byKey(const ValueKey('address_card')),
    ),
    matching: find.byTooltip('Opciones de dirección'),
  );

  testWidgets('lists the enabled addresses with the primary first and marked', (
    tester,
  ) async {
    await pumpSection(tester);

    expect(find.textContaining('Belgrano 1200'), findsOneWidget);
    expect(find.textContaining('Mitre 50'), findsOneWidget);
    expect(find.textContaining('Caseros 9'), findsNothing);
    expect(find.text('Principal'), findsOneWidget);
    expect(
      tester.getTopLeft(find.textContaining('Belgrano 1200')).dy,
      lessThan(tester.getTopLeft(find.textContaining('Mitre 50')).dy),
    );
    await unmount(tester);
  });

  testWidgets('adds an address from the form', (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Agregar dirección'));
    await settle(tester);
    expect(find.text('Nueva dirección'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calle y altura / Manzana'),
      'Alvarado 300',
    );
    await tester.tap(find.text('Seleccionar barrio...'));
    await settle(tester);
    await tester.tap(find.text('Tres Cerritos'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Piso'), '2');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await settle(tester);

    expect(find.text('Nueva dirección'), findsNothing);
    expect(find.textContaining('Alvarado 300'), findsOneWidget);
    final added = (await tester.runAsync(
      () => (db.select(
        db.customerAddressTable,
      )..where((t) => t.street.equals('Alvarado 300'))).getSingle(),
    ))!;
    expect(added.neighborhood, 'Tres Cerritos');
    expect(added.floor, '2');
    expect(added.isPrimary, isFalse);
    final change = (await tester.runAsync(
      () => db.select(db.pendingChangeTable).getSingle(),
    ))!;
    expect(change.entity, PendingEntity.customerAddress.wireName);
    expect(change.entityId, added.addressId);
    await unmount(tester);
  });

  testWidgets('edits an address from the form', (tester) async {
    await pumpSection(tester);

    await tester.tap(optionsOf('Mitre 50'));
    await settle(tester);
    await tester.tap(find.text('Editar'));
    await settle(tester);
    expect(find.text('Editar dirección'), findsOneWidget);

    final street = find.widgetWithText(
      TextFormField,
      'Calle y altura / Manzana',
    );
    expect(
      find.descendant(of: street, matching: find.text('Mitre 50')),
      findsOneWidget,
    );
    await tester.enterText(street, 'Mitre 52');
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await settle(tester);

    expect(find.textContaining('Mitre 52'), findsOneWidget);
    expect((await row(tester, 'a-2')).street, 'Mitre 52');
    await unmount(tester);
  });

  testWidgets('marks another address as the primary', (tester) async {
    await pumpSection(tester);

    await tester.tap(optionsOf('Mitre 50'));
    await settle(tester);
    await tester.tap(find.text('Marcar como principal'));
    await settle(tester);

    expect((await row(tester, 'a-2')).isPrimary, isTrue);
    expect((await row(tester, 'a-1')).isPrimary, isFalse);
    expect(find.text('Principal'), findsOneWidget);
    expect(
      tester.getTopLeft(find.textContaining('Mitre 50')).dy,
      lessThan(tester.getTopLeft(find.textContaining('Belgrano 1200')).dy),
    );
    await unmount(tester);
  });

  testWidgets('the primary offers neither disable nor mark as primary', (
    tester,
  ) async {
    await pumpSection(tester);

    await tester.tap(optionsOf('Belgrano 1200'));
    await settle(tester);

    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Marcar como principal'), findsNothing);
    expect(find.text('Dar de baja'), findsNothing);
    await unmount(tester);
  });

  testWidgets('disables an address after confirming', (tester) async {
    await pumpSection(tester);

    await tester.tap(optionsOf('Mitre 50'));
    await settle(tester);
    await tester.tap(find.text('Dar de baja'));
    await settle(tester);
    expect(find.text('¿Dar de baja esta dirección?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
    await settle(tester);
    expect((await row(tester, 'a-2')).enabled, isTrue);

    await tester.tap(optionsOf('Mitre 50'));
    await settle(tester);
    await tester.tap(find.text('Dar de baja'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await settle(tester);

    expect((await row(tester, 'a-2')).enabled, isFalse);
    expect(find.textContaining('Mitre 50'), findsNothing);
    await unmount(tester);
  });
}
