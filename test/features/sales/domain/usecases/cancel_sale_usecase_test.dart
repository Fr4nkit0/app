import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/cancel_sale.usecase.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';

/// Cancels the payment, then fails before the unit of work ends.
class _FailingPaymentRepository extends DriftPaymentRepository {
  _FailingPaymentRepository(super.db);

  @override
  Future<void> cancelPayment(
    Payment payment, {
    required DateTime at,
    String? reason,
    bool queue = true,
  }) async {
    await super.cancelPayment(payment, at: at, reason: reason, queue: queue);
    throw Exception('Simulated failure after the payment cancellation');
  }
}

void main() {
  late AppDatabase db;
  late DriftSaleRepository sales;
  late DriftPaymentRepository payments;
  late PendingChangeRepository queue;

  final now = DateTime(2026, 10, 29, 11);
  final soldAt = DateTime(2026, 10, 29, 10);
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );
  const water = Product(id: 'p-1', name: 'Agua 20L', unitLabel: '', price: 1200);

  CancelSaleUseCase useCase({PaymentRepository? paymentRepo}) =>
      CancelSaleUseCase(
        saleRepo: sales,
        paymentRepo: paymentRepo ?? payments,
        inventoryRepo: DriftInventoryRepository(db),
        transaction: driftTransactionRunner(db),
        now: () => now,
      );

  ContainerMovement movement(
    String id, {
    String type = 'JUG',
    int delivered = 0,
    int returned = 0,
  }) => ContainerMovement(
    id: id,
    customerId: 'c-1',
    containerType: type,
    deliveredQuantity: delivered,
    returnedQuantity: returned,
    createdAt: soldAt,
    visitId: 's-1',
  );

  Future<Sale> sell({
    String id = 'sale-1',
    PaymentMethod method = PaymentMethod.cash,
    DateTime? date,
    double? cash,
    double? transfer,
    List<ContainerMovement>? containers,
  }) async {
    final sale = Sale(
      id: id,
      customer: customer,
      items: const [SaleItem(product: water, quantity: 2)],
      total: 2400,
      paymentMethod: method,
      date: date ?? soldAt,
      visitId: 's-1',
      cashAmount: cash,
      transferAmount: transfer,
    );
    await RegisterSaleUseCase(
      saleRepo: sales,
      paymentRepo: payments,
      inventoryRepo: DriftInventoryRepository(db),
      transaction: driftTransactionRunner(db),
    ).execute(sale, containerMovements: containers);
    return sale;
  }

  Future<Map<String, int>> custody() async => {
    for (final b in await db.select(db.customerContainerBalanceTable).get())
      b.containerType: b.quantity,
  };

  Future<void> payDebt() => payments.recordPayment(
    Payment(
      id: 'pay-debt',
      customerId: 'c-1',
      amount: 500,
      type: PaymentType.cash,
      createdAt: soldAt,
      visitId: 's-1',
    ),
  );

  Future<double> balance() => payments.watchCustomerBalance('c-1').first;

  Future<int> stock() async => (await (db.select(
    db.productTable,
  )..where((t) => t.productId.equals('p-1'))).getSingle()).stock;

  Future<SaleTableData> saleRow([String id = 'sale-1']) => (db.select(
    db.saleTable,
  )..where((t) => t.saleId.equals(id))).getSingle();

  Future<Map<String, String>> paymentStatuses() async => {
    for (final p in await db.select(db.paymentTable).get())
      p.paymentId: p.status,
  };

  Future<List<PendingChange>> queued(PendingEntity entity) async => [
    for (final c in await queue.getPending())
      if (c.entity == entity) c,
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sales = DriftSaleRepository(db);
    payments = DriftPaymentRepository(db);
    queue = DriftPendingChangeRepository(db);
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: const drift.Value(1000),
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1200,
            stock: const drift.Value(10),
          ),
        );
  });
  tearDown(() => db.close());

  test('cancels the sale and the payments that settled it in one unit of '
      'work, leaving the debt payment of the visit untouched', () async {
    final sale = await sell();
    await payDebt();
    expect(await balance(), 500);
    expect(await stock(), 8);
    final settling = RegisterSaleUseCase.settlingPayments(sale).single;

    await useCase().execute('sale-1', reason: '  Cliente devolvió  ');

    final row = await saleRow();
    expect(row.status, 'CANCELLED');
    expect(row.cancelledAt, now);
    expect(row.cancellationReason, 'Cliente devolvió');
    expect(await paymentStatuses(), {
      settling.id: 'CANCELLED',
      'pay-debt': 'CONFIRMED',
    });
    // The balance is where it was before the sale, minus the debt payment.
    expect(await balance(), 500);
    expect(await stock(), 10);

    final entries = await db.select(db.customerAccountEntryTable).get();
    final creditNote = entries.singleWhere((e) => e.entryType == 'CREDIT_NOTE');
    expect(creditNote.saleId, 'sale-1');
    expect(creditNote.amount, 2400);
    expect(creditNote.direction, -1);
    final adjustment = entries.singleWhere((e) => e.entryType == 'ADJUSTMENT');
    expect(adjustment.paymentId, settling.id);
    expect(adjustment.amount, 2400);
    expect(adjustment.direction, 1);

    final saleCancellations = await queued(PendingEntity.saleCancellation);
    expect(saleCancellations.map((c) => c.entityId), ['sale-1']);
    final paymentCancellations = await queued(
      PendingEntity.paymentCancellation,
    );
    expect(paymentCancellations.map((c) => c.entityId), [settling.id]);

    final found = await sales.findSale('sale-1');
    expect(found?.isCancelled, isTrue);
  });

  test('a credit sale returns the balance to where it was before it', () async {
    await sell(method: PaymentMethod.credit);
    expect(await balance(), 3400);

    await useCase().execute('sale-1');

    expect(await balance(), 1000);
    expect((await saleRow()).cancellationReason, isNull);
    expect(await queued(PendingEntity.paymentCancellation), isEmpty);
  });

  test('a mixed sale queues one payment cancellation per settling '
      'payment', () async {
    await sell(method: PaymentMethod.mixed, cash: 1400, transfer: 1000);

    await useCase().execute('sale-1');

    expect(await queued(PendingEntity.paymentCancellation), hasLength(2));
    expect(await balance(), 1000);
  });

  test('a sale of another day cannot be cancelled and nothing changes', () async {
    await sell(date: DateTime(2026, 10, 28, 18));
    final pending = await queue.countPending();

    await expectLater(
      useCase().execute('sale-1'),
      throwsA(
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          'Solo se pueden anular las ventas de hoy.',
        ),
      ),
    );

    expect((await saleRow()).status, 'CONFIRMED');
    expect(await queue.countPending(), pending);
    expect(await balance(), 1000);
    expect(await stock(), 8);
  });

  test('a reason longer than 500 characters is refused', () async {
    await sell();

    await expectLater(
      useCase().execute('sale-1', reason: 'x' * 501),
      throwsA(isA<ValidationFailure>()),
    );
    expect((await saleRow()).status, 'CONFIRMED');
  });

  test('cancelling twice books nothing the second time', () async {
    await sell();
    await useCase().execute('sale-1');
    final pending = await queue.countPending();
    final entries = (await db.select(db.customerAccountEntryTable).get()).length;

    await useCase().execute('sale-1');

    expect(await queue.countPending(), pending);
    expect(
      (await db.select(db.customerAccountEntryTable).get()).length,
      entries,
    );
    expect(await balance(), 1000);
    expect(await stock(), 10);
  });

  test('an unknown sale is a NotFoundFailure', () async {
    await expectLater(
      useCase().execute('missing'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  group('containers delivered and returned with the sale', () {
    test('go back to where they were before it, in custody, while a return '
        'without a sale stays and nothing new is queued', () async {
      await sell(
        containers: [
          movement('m-jug', delivered: 3, returned: 1),
          movement('m-siphon', type: 'SIPHON', returned: 2),
        ],
      );
      await DriftInventoryRepository(
        db,
      ).recordContainerMovement(movement('m-loose', returned: 1));
      expect(await custody(), {'JUG': 3 - 1 - 1, 'SIPHON': -2});
      final movementsQueued = await queued(PendingEntity.containerMovement);

      await useCase().execute('sale-1');

      // Only the standalone return is left in custody.
      expect(await custody(), {'JUG': -1, 'SIPHON': 0});
      expect(
        (await queued(PendingEntity.containerMovement)).map((c) => c.id),
        movementsQueued.map((c) => c.id),
      );
      final reversals = {
        for (final m in await db.select(db.containerMovementTable).get())
          if (m.reversesMovementId != null) m.reversesMovementId!: m,
      };
      expect(reversals.keys, unorderedEquals(['m-jug', 'm-siphon']));
      final jug = reversals['m-jug']!;
      expect((jug.deliveredQuantity, jug.returnedQuantity), (-3, -1));
      expect(jug.saleId, 'sale-1');
      expect(jug.customerId, 'c-1');
      expect(jug.containerType, 'JUG');
      expect(jug.visitId, 's-1');
      expect(jug.createdAt, now);
      expect(jug.serverId, isNull);
      final siphon = reversals['m-siphon']!;
      expect((siphon.deliveredQuantity, siphon.returnedQuantity), (0, -2));
    });

    test('cancelling twice reverses them once', () async {
      await sell(containers: [movement('m-jug', delivered: 2)]);
      await useCase().execute('sale-1');

      await useCase().execute('sale-1');

      expect(await custody(), {'JUG': 0});
      expect(await db.select(db.containerMovementTable).get(), hasLength(2));
    });

    test('a failure inside the unit of work leaves them in custody', () async {
      await sell(containers: [movement('m-jug', delivered: 2, returned: 1)]);

      await expectLater(
        useCase(paymentRepo: _FailingPaymentRepository(db)).execute('sale-1'),
        throwsA(isA<Exception>()),
      );

      expect(await custody(), {'JUG': 1});
      expect(
        (await db.select(
          db.containerMovementTable,
        ).get()).map((m) => m.containerMovementId),
        ['m-jug'],
      );
    });
  });

  test('a failure inside the unit of work changes nothing', () async {
    await sell();
    final pending = await queue.countPending();
    final entries = (await db.select(db.customerAccountEntryTable).get()).length;

    await expectLater(
      useCase(paymentRepo: _FailingPaymentRepository(db)).execute('sale-1'),
      throwsA(isA<Exception>()),
    );

    expect((await saleRow()).status, 'CONFIRMED');
    expect((await paymentStatuses()).values, everyElement('CONFIRMED'));
    expect(await queue.countPending(), pending);
    expect(
      (await db.select(db.customerAccountEntryTable).get()).length,
      entries,
    );
    expect(await balance(), 1000);
    expect(await stock(), 8);
  });
}
