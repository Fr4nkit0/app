import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:app/features/sales/data/database/record_status.dart';

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
    for (final (id, name) in [('cust-1', 'Sanatorio'), ('cust-2', 'Nuevo')]) {
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value(id),
              name: name,
              serverId: const drift.Value(10),
            ),
          );
    }
  });
  tearDown(() => db.close());

  /// Today's visit 19 and credit sale 18 (8 × 5200) as the bootstrap stores
  /// them: server ids and no pending changes.
  Future<void> seedBootstrap() async {
    final today = DateTime.now();
    final at = DateTime(today.year, today.month, today.day, 9);
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 5200,
          ),
        );
    await db
        .into(db.containerTypeTable)
        .insert(
          ContainerTypeTableCompanion.insert(
            id: const drift.Value(1),
            code: 'B20',
            description: const drift.Value('Bidón 20L'),
          ),
        );
    await db
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('r-1'),
            route_date: '2026-10-30',
          ),
        );
    await db
        .into(db.routeStopTable)
        .insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('stop-1'),
            routeId: 'r-1',
            customerId: 'cust-1',
            sequence: 1,
            scheduledAt: at,
          ),
        );
    await db
        .into(db.visitOutcomeTable)
        .insert(
          VisitOutcomeTableCompanion.insert(
            id: const drift.Value(1),
            name: 'Entregado',
          ),
        );
    await db
        .into(db.visitTable)
        .insert(
          VisitTableCompanion.insert(
            visitId: const drift.Value('visit-19'),
            routeStopId: 'stop-1',
            customerId: 'cust-1',
            visitType: 'visit',
            outcomeId: const drift.Value(1),
            arrived_at: at,
            serverId: const drift.Value(19),
          ),
        );
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: const drift.Value('sale-18'),
            customerId: 'cust-1',
            totalAmount: 41600,
            paymentMethod: 'credit',
            quantity: 8,
            shipping_amount: 0,
            saleDate: drift.Value(at.add(const Duration(minutes: 5))),
            serverId: const drift.Value(18),
          ),
        );
    await db
        .into(db.saleItemTable)
        .insert(
          SaleItemTableCompanion.insert(
            saleId: 'sale-18',
            productId: 'p-1',
            quantity: 8,
            unitPrice: 5200,
            subtotal: 41600,
          ),
        );
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: const drift.Value('sale-20'),
            customerId: 'cust-1',
            totalAmount: 5200,
            paymentMethod: 'cash',
            quantity: 1,
            shipping_amount: 0,
            saleDate: drift.Value(at.add(const Duration(minutes: 20))),
            status: const drift.Value(RecordStatus.cancelled),
            serverId: const drift.Value(20),
          ),
        );
    await db
        .into(db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            customerId: 'cust-1',
            containerType: 'B20',
            deliveredQuantity: 8,
            returnedQuantity: 3,
            createdAt: drift.Value(at.add(const Duration(minutes: 6))),
            serverId: const drift.Value(30),
          ),
        );
  }

  Future<void> pumpProfile(WidgetTester tester, String customerId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: CustomerProfileScreen(customerId: customerId),
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

  testWidgets('the Historial tab lists the records the bootstrap stored', (
    tester,
  ) async {
    await tester.runAsync(seedBootstrap);
    await pumpProfile(tester, 'cust-1');

    expect(find.text('Sin actividad reciente'), findsNothing);
    expect(find.text('Visita'), findsOneWidget);
    expect(find.textContaining('Entregado'), findsOneWidget);
    expect(find.text('Venta'), findsNWidgets(2));
    expect(find.textContaining('8 × Agua 20L'), findsOneWidget);
    expect(find.textContaining('A crédito'), findsOneWidget);
    expect(find.text(formatMoney(41600)), findsOneWidget);
    expect(find.text('Anulada'), findsOneWidget);
    expect(find.text('Envases'), findsOneWidget);
    expect(
      find.textContaining('Bidón 20L · Entregó 8 · Devolvió 3'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('the Historial tab shows the empty state with no records', (
    tester,
  ) async {
    await pumpProfile(tester, 'cust-2');

    expect(find.text('Sin actividad reciente'), findsOneWidget);
    await unmount(tester);
  });
}
