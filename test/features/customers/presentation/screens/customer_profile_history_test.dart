import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/database/record_status.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
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

  final now = DateTime.now();

  Future<void> pumpProfile(WidgetTester tester, String customerId) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
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

  group('off-route records', () {
    Future<void> seedAccount() async {
      await db
          .into(db.productTable)
          .insert(
            ProductTableCompanion.insert(
              productId: const drift.Value('p-1'),
              name: 'Agua 20L',
              price: 100,
              stock: const drift.Value(10),
            ),
          );
      await db
          .into(db.customerBalanceTable)
          .insert(
            CustomerBalanceTableCompanion.insert(
              customerId: 'cust-1',
              currentBalance: const drift.Value(1000),
            ),
          );
    }

    /// A credit sale of 3 waters from the profile's "Nueva Venta".
    Future<void> sellOffRoute() async {
      await seedAccount();
      await RegisterSaleUseCase(
        saleRepo: DriftSaleRepository(db),
        paymentRepo: DriftPaymentRepository(db),
        inventoryRepo: DriftInventoryRepository(db),
        transaction: driftTransactionRunner(db),
      ).execute(
        Sale(
          id: 'sale-1',
          customer: Customer(
            id: 'cust-1',
            name: 'Sanatorio',
            addresses: const [],
            preferences: const [],
          ),
          items: const [
            SaleItem(
              product: Product(
                id: 'p-1',
                name: 'Agua 20L',
                unitLabel: '',
                price: 100,
              ),
              quantity: 3,
            ),
          ],
          total: 300,
          paymentMethod: PaymentMethod.credit,
          date: now,
        ),
      );
    }

    /// The record may sit below the fold, under the profile's bottom bar.
    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pump();
      await tester.tap(finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    Future<int> stock() async =>
        (await db.select(db.productTable).getSingle()).stock;

    Future<double> balance() async =>
        (await db.select(db.customerBalanceTable).getSingle()).currentBalance;

    Future<List<PendingEntity>> queued() async => [
      for (final c in await DriftPendingChangeRepository(db).getPending())
        c.entity,
    ];

    testWidgets('the driver cancels an off-route sale: it is queued and its '
        'stock and debt come back', (tester) async {
      await tester.runAsync(sellOffRoute);
      expect(await tester.runAsync(stock), 7);
      expect(await tester.runAsync(balance), 1300);
      await pumpProfile(tester, 'cust-1');

      await tapVisible(tester, find.text('Anular venta'));
      expect(find.text('¿Anular la venta?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Anular'));
      await settle(tester);

      final sale = await tester.runAsync(
        () => db.select(db.saleTable).getSingle(),
      );
      expect(sale!.status, RecordStatus.cancelled);
      expect(
        await tester.runAsync(queued),
        contains(PendingEntity.saleCancellation),
      );
      expect(await tester.runAsync(stock), 10);
      expect(await tester.runAsync(balance), 1000);
      expect(find.text('Anular venta'), findsNothing);
      expect(find.text('Anulada'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the driver cancels an off-route payment: it is queued and '
        'its amount goes back on the debt', (tester) async {
      await tester.runAsync(() async {
        await seedAccount();
        await DriftPaymentRepository(db).recordPayment(
          Payment(
            id: 'pay-1',
            customerId: 'cust-1',
            amount: 250,
            type: PaymentType.cash,
            createdAt: now,
          ),
        );
      });
      expect(await tester.runAsync(balance), 750);
      await pumpProfile(tester, 'cust-1');

      await tapVisible(tester, find.text('Anular cobro'));
      expect(find.text('¿Anular el cobro?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Anular'));
      await settle(tester);

      final payment = await tester.runAsync(
        () => db.select(db.paymentTable).getSingle(),
      );
      expect(payment!.status, RecordStatus.cancelled);
      expect(
        await tester.runAsync(queued),
        contains(PendingEntity.paymentCancellation),
      );
      expect(await tester.runAsync(balance), 1000);
      expect(find.text('Anular cobro'), findsNothing);
      expect(find.text('Anulado'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('backing out of the dialog cancels nothing', (tester) async {
      await tester.runAsync(sellOffRoute);
      await pumpProfile(tester, 'cust-1');

      await tapVisible(tester, find.text('Anular venta'));
      await tester.tap(find.text('Volver'));
      await settle(tester);

      final sale = await tester.runAsync(
        () => db.select(db.saleTable).getSingle(),
      );
      expect(sale!.status, RecordStatus.confirmed);
      expect(await tester.runAsync(stock), 7);
      await unmount(tester);
    });
  });

  testWidgets('the Historial tab shows the empty state with no records', (
    tester,
  ) async {
    await pumpProfile(tester, 'cust-2');

    expect(find.text('Sin actividad reciente'), findsOneWidget);
    await unmount(tester);
  });
}
