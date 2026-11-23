import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/screens/address_form_screen.dart';

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
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> pumpForm(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AddressFormScreen(customerId: 'cust-1'),
        ),
      ),
    );
    await settle(tester);
  }

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Guardar'),
  );

  testWidgets('saving needs the street', (tester) async {
    await pumpForm(tester);

    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('an address without neighborhood saves with a null one', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calle y altura / Manzana'),
      'Mitre 50',
    );
    await tester.pump();
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await settle(tester);

    final address = await tester.runAsync(
      () => db.select(db.customerAddressTable).getSingle(),
    );
    expect(address!.street, 'Mitre 50');
    expect(address.neighborhood, isNull);

    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  });
}
