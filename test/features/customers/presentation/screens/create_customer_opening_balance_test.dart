import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:app/features/customers/presentation/widgets/opening_balance_section.dart';

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
    for (final (id, code, description) in [
      (1, 'B20', 'Bidón 20L'),
      (2, 'SIFON', 'Sifón'),
    ]) {
      await db
          .into(db.containerTypeTable)
          .insert(
            ContainerTypeTableCompanion.insert(
              id: drift.Value(id),
              code: code,
              description: drift.Value(description),
            ),
          );
    }
  });
  tearDown(() => db.close());

  // Drift schedules a zero-duration timer when a watched query is cancelled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  final debtField = find.byKey(OpeningBalanceSection.debtFieldKey);
  Finder containersField(String code) =>
      find.byKey(OpeningBalanceSection.containersFieldKey(code));
  final save = find.widgetWithText(FilledButton, 'Guardar Cliente');

  /// Opens the wizard from a host that keeps what it returns, and walks it
  /// to the Preferencias step.
  Future<Customer? Function()> openOnPreferences(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    Customer? returned;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  returned = await Navigator.of(context).push<Customer>(
                    MaterialPageRoute(
                      builder: (_) => const CreateCustomerScreen(),
                    ),
                  );
                },
                child: const Text('Clientes'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Clientes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre completo'),
      'Hotel Altos',
    );
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Calle y altura / Manzana'),
      'Belgrano 1200',
    );
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cuándo entregamos?'), findsOneWidget);
    return () => returned;
  }

  Future<void> openSection(WidgetTester tester) async {
    final add = find.text('Cargar saldo inicial');
    await tester.ensureVisible(add);
    await tester.tap(add);
    await settle(tester);
  }

  testWidgets('the opening balance is optional and starts folded', (
    tester,
  ) async {
    await openOnPreferences(tester);

    expect(find.text('Saldo inicial (opcional)'), findsOneWidget);
    expect(debtField, findsNothing);
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
    await unmount(tester);
  });

  testWidgets('the driver loads the opening debt and the containers on loan '
      'of every catalog type; the new customer starts with them', (
    tester,
  ) async {
    final returned = await openOnPreferences(tester);
    await openSection(tester);

    expect(find.text('Bidón 20L'), findsOneWidget);
    expect(find.text('Sifón'), findsOneWidget);
    await tester.enterText(debtField, '1500');
    await tester.enterText(containersField('B20'), '2');
    await tester.pump();
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);

    final customer = returned();
    expect(customer, isNotNull);
    expect(find.byType(CreateCustomerScreen), findsNothing);

    final rows = await tester.runAsync(
      () => (db.select(
        db.balanceCorrectionTable,
      )..orderBy([(t) => drift.OrderingTerm.asc(t.target)])).get(),
    );
    expect(
      [
        for (final r in rows!)
          (
            r.customerId,
            r.target,
            r.containerType,
            r.counted,
            r.seenBalance,
            r.reason,
          ),
      ],
      [
        (
          customer!.id,
          'containers',
          'B20',
          2.0,
          0.0,
          'Saldo inicial al dar de alta',
        ),
        (
          customer.id,
          'debt',
          null,
          1500.0,
          0.0,
          'Saldo inicial al dar de alta',
        ),
      ],
    );
    final queued = await tester.runAsync(
      () => (db.select(
        db.pendingChangeTable,
      )..orderBy([(t) => drift.OrderingTerm.asc(t.pendingChangeId)])).get(),
    );
    expect(queued!.first.entity, 'customer');
    expect(queued.where((c) => c.entity == 'balance_correction'), hasLength(2));
    expect(
      (jsonDecode(queued.first.payload!) as Map<String, dynamic>)['name'],
      'Hotel Altos',
    );

    // Its profile shows the debt and the containers on loan right away.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: CustomerProfileScreen(customerId: customer.id),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Debe \$1.500'), findsOneWidget);
    expect(find.text('Comodatos activos'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a fraction of a container is flagged and blocks the save', (
    tester,
  ) async {
    final returned = await openOnPreferences(tester);
    await openSection(tester);

    await tester.enterText(containersField('B20'), '2,5');
    await tester.pump();

    expect(
      find.text('Ingresá un número entero mayor o igual a cero.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);

    expect(returned(), isNull);
    expect(find.byType(CreateCustomerScreen), findsOneWidget);
    expect(
      await tester.runAsync(() => db.select(db.customerTable).get()),
      isEmpty,
    );
    expect(
      await tester.runAsync(() => db.select(db.pendingChangeTable).get()),
      isEmpty,
    );
    await unmount(tester);
  });

  testWidgets('Quitar folds the section and drops what was typed', (
    tester,
  ) async {
    final returned = await openOnPreferences(tester);
    await openSection(tester);
    await tester.enterText(debtField, '700');
    await tester.pump();

    await tester.tap(find.text('Quitar'));
    await tester.pump();
    expect(debtField, findsNothing);

    await tester.ensureVisible(save);
    await tester.tap(save);
    await settle(tester);

    expect(returned(), isNotNull);
    expect(
      await tester.runAsync(() => db.select(db.balanceCorrectionTable).get()),
      isEmpty,
    );
    await unmount(tester);
  });
}
