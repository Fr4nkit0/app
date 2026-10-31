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
            name: 'Kiosco Norte',
            phone: const drift.Value('3874001122'),
            serverId: const drift.Value(501),
          ),
        );
    await db
        .into(db.customerAddressTable)
        .insert(
          CustomerAddressTableCompanion.insert(
            addressId: const drift.Value('addr-1'),
            customerId: const drift.Value('cust-1'),
            street: const drift.Value('Belgrano 1200'),
            neighborhood: const drift.Value('Centro'),
            isPrimary: const drift.Value(true),
            serverId: const drift.Value(601),
          ),
        );
  });
  tearDown(() => db.close());

  testWidgets('the profile edit action saves the new name, phone and street', (
    tester,
  ) async {
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

    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);

    // The form opens with the customer's current data.
    expect(find.text('Editar cliente'), findsOneWidget);
    final name = find.widgetWithText(TextFormField, 'Nombre completo');
    expect(
      find.descendant(of: name, matching: find.text('Kiosco Norte')),
      findsOneWidget,
    );

    await tester.enterText(name, 'Kiosco Sur');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono (opcional)'),
      '3874009988',
    );
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await settle(tester);

    final street = find.widgetWithText(
      TextFormField,
      'Calle y altura / Manzana',
    );
    expect(
      find.descendant(of: street, matching: find.text('Belgrano 1200')),
      findsOneWidget,
    );
    await tester.enterText(street, 'Mitre 50');
    await tester.pump();
    await tester.tap(find.text('Guardar cambios'));
    await settle(tester);

    final customer = await tester.runAsync(
      () => db.select(db.customerTable).getSingle(),
    );
    expect(customer!.name, 'Kiosco Sur');
    expect(customer.phone, '3874009988');
    final address = await tester.runAsync(
      () => db.select(db.customerAddressTable).getSingle(),
    );
    expect(address!.addressId, 'addr-1');
    expect(address.street, 'Mitre 50');
    expect(address.neighborhood, 'Centro');

    // Back on the profile, which shows the new name.
    expect(find.text('Editar cliente'), findsNothing);
    expect(find.text('Kiosco Sur'), findsWidgets);
    expect(find.text('Kiosco Norte'), findsNothing);

    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });

  testWidgets('Enter on the phone moves on to the address step', (
    tester,
  ) async {
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
    await tester.tap(find.byTooltip('Editar'));
    await settle(tester);

    await tester.showKeyboard(
      find.widgetWithText(TextFormField, 'Teléfono (opcional)'),
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await settle(tester);

    expect(
      find.widgetWithText(TextFormField, 'Calle y altura / Manzana'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
