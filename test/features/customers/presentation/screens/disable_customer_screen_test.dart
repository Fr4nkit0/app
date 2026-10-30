import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/screens/customer_list_screen.dart';

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    for (final (id, name) in [('cust-1', 'Kiosco Norte'), ('cust-2', 'Almacén Sur')]) {
      await db.into(db.customerTable).insert(
        CustomerTableCompanion.insert(customerId: drift.Value(id), name: name),
      );
    }
  });
  tearDown(() => db.close());

  Future<void> openProfileFromList(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: CustomerListScreen()),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Kiosco Norte'));
    await settle(tester);
    expect(find.text('Perfil de Cliente'), findsOneWidget);

    await tester.tap(find.byTooltip('Dar de baja'));
    await settle(tester);
  }

  Future<CustomerTableData> customer() => (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals('cust-1'))).getSingle();

  Future<void> dispose(WidgetTester tester) async {
    // Drift schedules a zero-duration timer when a watched query is cancelled.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(Duration.zero);
  }

  testWidgets('confirming the disable returns to the list without the customer', (
    tester,
  ) async {
    await openProfileFromList(tester);

    expect(find.text('¿Dar de baja a Kiosco Norte?'), findsOneWidget);
    expect(
      find.textContaining('Solo la oficina puede volver a darlo de alta'),
      findsOneWidget,
    );
    expect(find.textContaining('ruta de hoy'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await settle(tester);

    expect((await tester.runAsync(customer))!.enabled, isFalse);
    final queued = await tester.runAsync(
      () => db.select(db.pendingChangeTable).get(),
    );
    expect(queued, hasLength(1));

    // Back on the list, which no longer shows the customer.
    expect(find.text('Perfil de Cliente'), findsNothing);
    expect(find.text('Kiosco Norte'), findsNothing);
    expect(find.text('Almacén Sur'), findsOneWidget);

    await dispose(tester);
  });

  testWidgets('cancelling the dialog changes nothing', (tester) async {
    await openProfileFromList(tester);

    await tester.tap(find.text('Cancelar'));
    await settle(tester);

    expect((await tester.runAsync(customer))!.enabled, isTrue);
    expect(
      await tester.runAsync(() => db.select(db.pendingChangeTable).get()),
      isEmpty,
    );
    expect(find.text('Perfil de Cliente'), findsOneWidget);

    await dispose(tester);
  });

  testWidgets('a customer with a stop today can be disabled and the dialog '
      'says so', (tester) async {
    await db.into(db.routeTable).insert(
      RouteTableCompanion.insert(
        routeId: const drift.Value('r-1'),
        route_date: _today(),
      ),
    );
    await db.into(db.routeStopTable).insert(
      RouteStopTableCompanion.insert(
        routeStopId: const drift.Value('stop-1'),
        routeId: 'r-1',
        customerId: 'cust-1',
        sequence: 1,
        scheduledAt: DateTime.now(),
      ),
    );

    await openProfileFromList(tester);

    expect(find.textContaining('ruta de hoy'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Dar de baja'));
    await settle(tester);

    expect((await tester.runAsync(customer))!.enabled, isFalse);

    await dispose(tester);
  });
}
