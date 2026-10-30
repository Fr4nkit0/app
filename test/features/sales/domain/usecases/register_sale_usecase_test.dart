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
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';

void main() {
  late AppDatabase db;
  late DriftSaleRepository saleRepo;
  late DriftPaymentRepository paymentRepo;
  late DriftInventoryRepository inventoryRepo;
  late RegisterSaleUseCase sut;

  const testProduct = Product(
    id: 'prod-test-1',
    name: 'Bidón 20L',
    unitLabel: 'Bidón',
    price: 6500.0,
  );

  final testCustomer = Customer(
    id: 'mock-customer-1',
    name: 'José García',
    addresses: const [],
    preferences: const [],
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    saleRepo = DriftSaleRepository(db);
    paymentRepo = DriftPaymentRepository(db);
    inventoryRepo = DriftInventoryRepository(db);
    sut = RegisterSaleUseCase(
      saleRepo: saleRepo,
      paymentRepo: paymentRepo,
      inventoryRepo: inventoryRepo,
      transaction: driftTransactionRunner(db),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Sale makeSale({
    String id = 'sale-test-1',
    List<SaleItem>? items,
    String? visitId,
    double total = 13000.0,
  }) {
    return Sale(
      id: id,
      customer: testCustomer,
      items: items ?? [const SaleItem(product: testProduct, quantity: 2)],
      total: total,
      paymentMethod: PaymentMethod.cash,
      date: DateTime.now(),
      visitId: visitId,
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Scenario F1a — success
  // ───────────────────────────────────────────────────────────────

  group('execute — success', () {
    test('F1a: completes for a sale with 1 item', () async {
      await expectLater(sut.execute(makeSale()), completes);
    });

    test('F1a: SaleTable has 1 row after execute', () async {
      await sut.execute(makeSale(id: 'sale-f1a'));

      final rows = await db.select(db.saleTable).get();
      expect(rows.length, 1);
      expect(rows.first.saleId, 'sale-f1a');
    });

    test('F1a: SaleItemTable has 1 row after execute', () async {
      await sut.execute(makeSale(id: 'sale-f1a'));

      final rows = await db.select(db.saleItemTable).get();
      expect(rows.length, 1);
      expect(rows.first.saleId, 'sale-f1a');
      expect(rows.first.quantity, 2);
    });

    test('multiple items — all items inserted', () async {
      final sale = makeSale(
        id: 'sale-multi',
        items: [
          const SaleItem(product: testProduct, quantity: 1),
          const SaleItem(
            product: Product(
              id: 'prod-test-2',
              name: 'Sifón 1.5L',
              unitLabel: 'Sifón',
              price: 1500.0,
            ),
            quantity: 3,
          ),
        ],
        total: 11000.0,
      );
      await sut.execute(sale);

      final rows = await db.select(db.saleItemTable).get();
      expect(rows.length, 2);
    });
  });

  group('execute — balance and settling payments', () {
    test('a cash sale is settled by one payment of its total and leaves the balance unchanged', () async {
      await sut.execute(makeSale());

      final payment = await db.select(db.paymentTable).getSingle();
      expect(payment.saleId, 'sale-test-1');
      expect(payment.amount, 13000.0);
      expect(await paymentRepo.watchCustomerBalance(testCustomer.id).first, 0);
    });

    test('a credit sale queues no payment and raises the balance by its total', () async {
      await sut.execute(
        Sale(
          id: 'sale-credit',
          customer: testCustomer,
          items: const [SaleItem(product: testProduct, quantity: 2)],
          total: 13000.0,
          paymentMethod: PaymentMethod.credit,
          date: DateTime.now(),
        ),
      );

      expect(await db.select(db.paymentTable).get(), isEmpty);
      expect(await paymentRepo.watchCustomerBalance(testCustomer.id).first, 13000.0);
    });

    test('a mixed sale is settled by cash first and the transfer right after it', () async {
      final date = DateTime(2026, 10, 28, 9, 30);
      final payments = RegisterSaleUseCase.settlingPayments(
        Sale(
          id: 'sale-mixed',
          customer: testCustomer,
          items: const [SaleItem(product: testProduct, quantity: 2)],
          total: 13000.0,
          paymentMethod: PaymentMethod.mixed,
          date: date,
          cashAmount: 8000,
          transferAmount: 5000,
          visitId: 'v1',
        ),
      );

      expect(payments.map((p) => p.type), [PaymentType.cash, PaymentType.transfer]);
      expect(payments.map((p) => p.amount), [8000, 5000]);
      expect(payments[0].createdAt, date);
      expect(payments[1].createdAt, date.add(const Duration(milliseconds: 10)));
      expect(payments.map((p) => p.saleId), ['sale-mixed', 'sale-mixed']);
      expect(payments.map((p) => p.visitId), ['v1', 'v1']);
      expect(payments[0].id, isNot(payments[1].id));
    });

    test('settling payments are deterministic for the same sale', () {
      Sale sale() => Sale(
            id: 'sale-same',
            customer: testCustomer,
            items: const [SaleItem(product: testProduct, quantity: 2)],
            total: 13000.0,
            paymentMethod: PaymentMethod.mixed,
            date: DateTime(2026),
            cashAmount: 8000,
            transferAmount: 5000,
          );

      expect(
        RegisterSaleUseCase.settlingPayments(sale()).map((p) => p.id),
        RegisterSaleUseCase.settlingPayments(sale()).map((p) => p.id),
      );
    });

    test('a transfer sale is one transfer of its total; credit and route are none', () {
      Sale withMethod(PaymentMethod method) => Sale(
            id: 'sale-$method',
            customer: testCustomer,
            items: const [SaleItem(product: testProduct, quantity: 2)],
            total: 13000.0,
            paymentMethod: method,
            date: DateTime(2026),
          );

      final transfer = RegisterSaleUseCase.settlingPayments(withMethod(PaymentMethod.transfer));
      expect(transfer.single.type, PaymentType.transfer);
      expect(transfer.single.amount, 13000.0);
      expect(transfer.single.createdAt, DateTime(2026));
      expect(RegisterSaleUseCase.settlingPayments(withMethod(PaymentMethod.credit)), isEmpty);
      expect(RegisterSaleUseCase.settlingPayments(withMethod(PaymentMethod.route)), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F1b — empty items rejected
  // ───────────────────────────────────────────────────────────────

  group('execute — total must match the items', () {
    test('throws a ValidationFailure and writes nothing when the total '
        'differs from quantity x unit price', () async {
      await expectLater(
        sut.execute(makeSale(total: 13000.01)),
        throwsA(isA<ValidationFailure>()),
      );

      expect(await db.select(db.saleTable).get(), isEmpty);
      expect(await db.select(db.saleItemTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
      expect(await db.select(db.paymentTable).get(), isEmpty);
    });

    test('accepts a difference within the server tolerance of 0.005',
        () async {
      await expectLater(sut.execute(makeSale(total: 13000.004)), completes);
    });
  });

  group('execute — empty items', () {
    test('F1b: throws a ValidationFailure when items is empty', () async {
      await expectLater(
        sut.execute(makeSale(items: [])),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('F1b: SaleTable stays empty when items is empty', () async {
      await expectLater(sut.execute(makeSale(items: [])), throwsException);

      final rows = await db.select(db.saleTable).get();
      expect(rows, isEmpty);
    });
  });

  group('execute — container movements', () {
    test('movements recorded with the sale carry its id', () async {
      ContainerMovement movement(String id, String type) => ContainerMovement(
            id: id,
            customerId: testCustomer.id,
            containerType: type,
            deliveredQuantity: 2,
            returnedQuantity: 1,
            createdAt: DateTime(2026),
          );

      await sut.execute(
        makeSale(),
        containerMovements: [movement('m-1', 'JUG'), movement('m-2', 'SIPHON')],
      );

      final rows = await db.select(db.containerMovementTable).get();
      expect(
        {for (final r in rows) r.containerMovementId: r.saleId},
        {'m-1': 'sale-test-1', 'm-2': 'sale-test-1'},
      );
      final payloads = [
        for (final c in await db.select(db.pendingChangeTable).get())
          if (c.entity == 'container_movement') c.payload,
      ];
      expect(payloads, hasLength(2));
      for (final p in payloads) {
        expect(p, contains('"saleId":"sale-test-1"'));
      }
    });
  });

  group('execute — atomic', () {
    test('a failing second write leaves no rows and no pending changes', () async {
      ContainerMovement movement() => ContainerMovement(
            id: 'same-movement-id',
            customerId: testCustomer.id,
            containerType: 'JUG',
            deliveredQuantity: 2,
            returnedQuantity: 0,
            createdAt: DateTime(2026),
          );

      // The second movement reuses the id, so it fails after the sale, its
      // payment and the first movement were written.
      await expectLater(
        sut.execute(makeSale(), containerMovements: [movement(), movement()]),
        throwsA(isA<StorageFailure>()),
      );

      expect(await db.select(db.saleTable).get(), isEmpty);
      expect(await db.select(db.saleItemTable).get(), isEmpty);
      expect(await db.select(db.paymentTable).get(), isEmpty);
      expect(await db.select(db.customerAccountEntryTable).get(), isEmpty);
      expect(await db.select(db.customerBalanceTable).get(), isEmpty);
      expect(await db.select(db.containerMovementTable).get(), isEmpty);
      expect(await db.select(db.customerContainerBalanceTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });
  });
}
