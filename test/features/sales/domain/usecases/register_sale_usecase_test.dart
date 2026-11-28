import 'dart:convert';

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
    price: 6500,
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
    int total = 13000,
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

    test('a sale over a zero or negative truck stock is not blocked', () async {
      for (final (id, available) in [('sale-zero', 0), ('sale-neg', -1)]) {
        await sut.execute(
          makeSale(
            id: id,
            items: [
              SaleItem(
                product: Product(
                  id: 'prod-$id',
                  name: 'Bidón 20L',
                  unitLabel: 'Bidón',
                  price: 6500,
                  available: available,
                ),
                quantity: 2,
              ),
            ],
          ),
        );
      }

      expect(await db.select(db.saleTable).get(), hasLength(2));
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
              price: 1500,
            ),
            quantity: 3,
          ),
        ],
        total: 11000,
      );
      await sut.execute(sale);

      final rows = await db.select(db.saleItemTable).get();
      expect(rows.length, 2);
    });
  });

  group('execute — balance and settling payments', () {
    test(
      'a cash sale is settled by one payment of its total and leaves the balance unchanged',
      () async {
        await sut.execute(makeSale());

        final payment = await db.select(db.paymentTable).getSingle();
        expect(payment.saleId, 'sale-test-1');
        expect(payment.amount, 13000.0);
        expect(
          await paymentRepo.watchCustomerBalance(testCustomer.id).first,
          0,
        );
      },
    );

    test(
      'a credit sale queues no payment and raises the balance by its total',
      () async {
        await sut.execute(
          Sale(
            id: 'sale-credit',
            customer: testCustomer,
            items: const [SaleItem(product: testProduct, quantity: 2)],
            total: 13000,
            paymentMethod: PaymentMethod.credit,
            date: DateTime.now(),
          ),
        );

        expect(await db.select(db.paymentTable).get(), isEmpty);
        expect(
          await paymentRepo.watchCustomerBalance(testCustomer.id).first,
          13000.0,
        );
      },
    );

    test(
      'a mixed sale is settled by cash first and the transfer right after it',
      () async {
        final date = DateTime(2026, 10, 28, 9, 30);
        final payments = RegisterSaleUseCase.settlingPayments(
          Sale(
            id: 'sale-mixed',
            customer: testCustomer,
            items: const [SaleItem(product: testProduct, quantity: 2)],
            total: 13000,
            paymentMethod: PaymentMethod.mixed,
            date: date,
            cashAmount: 8000,
            transferAmount: 5000,
            visitId: 'v1',
          ),
        );

        expect(payments.map((p) => p.type), [
          PaymentType.cash,
          PaymentType.transfer,
        ]);
        expect(payments.map((p) => p.amount), [8000, 5000]);
        expect(payments[0].createdAt, date);
        expect(
          payments[1].createdAt,
          date.add(const Duration(milliseconds: 10)),
        );
        expect(payments.map((p) => p.saleId), ['sale-mixed', 'sale-mixed']);
        expect(payments.map((p) => p.visitId), ['v1', 'v1']);
        expect(payments[0].id, isNot(payments[1].id));
      },
    );

    test('settling payments are deterministic for the same sale', () {
      Sale sale() => Sale(
        id: 'sale-same',
        customer: testCustomer,
        items: const [SaleItem(product: testProduct, quantity: 2)],
        total: 13000,
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

    test(
      'a transfer sale is one transfer of its total; credit and route are none',
      () {
        Sale withMethod(PaymentMethod method) => Sale(
          id: 'sale-$method',
          customer: testCustomer,
          items: const [SaleItem(product: testProduct, quantity: 2)],
          total: 13000,
          paymentMethod: method,
          date: DateTime(2026),
        );

        final transfer = RegisterSaleUseCase.settlingPayments(
          withMethod(PaymentMethod.transfer),
        );
        expect(transfer.single.type, PaymentType.transfer);
        expect(transfer.single.amount, 13000.0);
        expect(transfer.single.createdAt, DateTime(2026));
        expect(
          RegisterSaleUseCase.settlingPayments(
            withMethod(PaymentMethod.credit),
          ),
          isEmpty,
        );
        expect(
          RegisterSaleUseCase.settlingPayments(withMethod(PaymentMethod.route)),
          isEmpty,
        );
      },
    );
  });

  group('execute — also paying previous debt (S7, S9, S10)', () {
    Future<void> owe(int amount) async {
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value(testCustomer.id),
              name: testCustomer.name,
            ),
          );
      await db
          .into(db.customerBalanceTable)
          .insert(
            CustomerBalanceTableCompanion.insert(
              customerId: testCustomer.id,
              currentBalance: drift.Value(amount),
            ),
          );
    }

    Sale saleBy(
      PaymentMethod method, {
      String id = 'sale-debt',
      int? cash,
      int? transfer,
    }) => Sale(
      id: id,
      customer: testCustomer,
      items: const [SaleItem(product: testProduct, quantity: 2)],
      total: 13000,
      paymentMethod: method,
      date: DateTime(2026, 11, 16, 9, 30),
      cashAmount: cash,
      transferAmount: transfer,
      visitId: 'v1',
    );

    Future<List<Map<String, dynamic>>> queuedPayments() async => [
      for (final c in await db.select(db.pendingChangeTable).get())
        if (c.entity == 'payment')
          jsonDecode(c.payload!) as Map<String, dynamic>,
    ];

    test('S9: a 13000 sale plus 7200 of debt by one transfer is two payments '
        'sharing one transaction uuid and the account ends at 0', () async {
      await owe(7200);

      await sut.execute(saleBy(PaymentMethod.transfer), debtAmount: 7200);

      final rows = await db.select(db.paymentTable).get();
      expect(
        {for (final r in rows) r.amount: (r.saleId, r.paymentMethod)},
        {
          13000.0: ('sale-debt', 'TRANSFERENCIA'),
          7200.0: (null, 'TRANSFERENCIA'),
        },
      );
      final queued = await queuedPayments();
      expect(queued, hasLength(2));
      final uuids = {for (final p in queued) p['transactionUuid']};
      expect(uuids, hasLength(1));
      expect(uuids.single, isA<String>());
      expect(await paymentRepo.watchCustomerBalance(testCustomer.id).first, 0);
    });

    test('S6: a mixed operation books cash and transfer on the sale first '
        'and the transfer remainder on the debt', () async {
      await owe(7200);

      await sut.execute(
        saleBy(PaymentMethod.mixed, cash: 5000, transfer: 15200),
        debtAmount: 7200,
      );

      final queued = await queuedPayments();
      expect(
        queued.map(
          (p) => (p['saleId'], p['paymentMethod'], p['amount'] as num),
        ),
        [
          ('sale-debt', 'EFECTIVO', 5000),
          ('sale-debt', 'TRANSFERENCIA', 8000),
          (null, 'TRANSFERENCIA', 7200),
        ],
      );
      expect(queued[1]['transactionUuid'], queued[2]['transactionUuid']);
      expect(queued[0]['transactionUuid'], isNotNull);
      expect(queued[0]['transactionUuid'], isNot(queued[1]['transactionUuid']));
      // The sale keeps only its own part (S7).
      final sale = await saleRepo.findSale('sale-debt');
      expect((sale?.cashAmount, sale?.transferAmount), (5000, 8000));
      expect(await paymentRepo.watchCustomerBalance(testCustomer.id).first, 0);
    });

    test('S2: ids and transaction uuids are deterministic for the same '
        'sale', () async {
      Future<List<(Object?, Object?)>> record() async {
        final local = AppDatabase(NativeDatabase.memory());
        addTearDown(local.close);
        await local
            .into(local.customerBalanceTable)
            .insert(
              CustomerBalanceTableCompanion.insert(
                customerId: testCustomer.id,
                currentBalance: const drift.Value(7200),
              ),
            );
        await RegisterSaleUseCase(
          saleRepo: DriftSaleRepository(local),
          paymentRepo: DriftPaymentRepository(local),
          inventoryRepo: DriftInventoryRepository(local),
          transaction: driftTransactionRunner(local),
        ).execute(
          saleBy(PaymentMethod.mixed, cash: 5000, transfer: 15200),
          debtAmount: 7200,
        );
        return [
          for (final c in await local.select(local.pendingChangeTable).get())
            if (c.entity == 'payment')
              (c.entityId, (jsonDecode(c.payload!) as Map)['transactionUuid']),
        ];
      }

      final first = await record();
      expect(first, hasLength(3));
      expect(await record(), first);
      // Sale payments keep the ids they always had.
      expect(
        first.take(2).map((p) => p.$1),
        RegisterSaleUseCase.settlingPayments(
          saleBy(PaymentMethod.mixed, cash: 5000, transfer: 8000),
        ).map((p) => p.id),
      );
    });

    test('without debt the payments and their queued changes are as '
        'before', () async {
      await sut.execute(
        saleBy(PaymentMethod.mixed, cash: 5000, transfer: 8000),
        debtAmount: 0,
      );

      final queued = await queuedPayments();
      expect(queued, hasLength(2));
      for (final p in queued) {
        expect(p.containsKey('transactionUuid'), isFalse);
        expect(p['saleId'], 'sale-debt');
      }
    });

    test('a failing later write leaves neither the sale nor the debt '
        'payment', () async {
      await owe(7200);
      ContainerMovement movement() => ContainerMovement(
        id: 'same-movement-id',
        customerId: testCustomer.id,
        containerType: 'JUG',
        deliveredQuantity: 1,
        returnedQuantity: 0,
        createdAt: DateTime(2026),
      );

      await expectLater(
        sut.execute(
          saleBy(PaymentMethod.cash),
          debtAmount: 7200,
          containerMovements: [movement(), movement()],
        ),
        throwsA(isA<StorageFailure>()),
      );

      expect(await db.select(db.saleTable).get(), isEmpty);
      expect(await db.select(db.paymentTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
      expect(
        await paymentRepo.watchCustomerBalance(testCustomer.id).first,
        7200,
      );
    });

    test('S2: a payment beyond the whole debt is kept unchanged and leaves '
        'the account in favor of the customer', () async {
      await owe(1500);

      await sut.execute(saleBy(PaymentMethod.cash), debtAmount: 3500);

      final queued = await queuedPayments();
      expect(
        queued.map(
          (p) => (p['saleId'], p['paymentMethod'], p['amount'] as num),
        ),
        [('sale-debt', 'EFECTIVO', 13000), (null, 'EFECTIVO', 3500)],
      );
      // bookSale +13000, bookPayment -13000 and -3500: 1500 - 3500.
      expect(
        await paymentRepo.watchCustomerBalance(testCustomer.id).first,
        -2000,
      );
    });

    test('S2: a customer without debt keeps the whole surplus as '
        'credit', () async {
      await sut.execute(saleBy(PaymentMethod.transfer), debtAmount: 100);

      expect(await db.select(db.saleTable).get(), hasLength(1));
      expect(
        await paymentRepo.watchCustomerBalance(testCustomer.id).first,
        -100,
      );
    });

    test('S2: a mixed surplus beyond the debt books the transfer remainder '
        'as one payment', () async {
      await owe(1000);

      await sut.execute(
        saleBy(PaymentMethod.mixed, cash: 10000, transfer: 5000),
        debtAmount: 2000,
      );

      final queued = await queuedPayments();
      expect(
        queued.map(
          (p) => (p['saleId'], p['paymentMethod'], p['amount'] as num),
        ),
        [
          ('sale-debt', 'EFECTIVO', 10000),
          ('sale-debt', 'TRANSFERENCIA', 3000),
          (null, 'TRANSFERENCIA', 2000),
        ],
      );
      expect(
        await paymentRepo.watchCustomerBalance(testCustomer.id).first,
        -1000,
      );
    });

    test('rejects a negative debt, a debt on a credit sale and a mixed '
        'split that does not cover the sale plus the debt', () async {
      for (final (sale, debt) in [
        (saleBy(PaymentMethod.cash), -1),
        (saleBy(PaymentMethod.credit), 7200),
        (saleBy(PaymentMethod.route), 7200),
        (saleBy(PaymentMethod.mixed, cash: 5000, transfer: 8000), 7200),
      ]) {
        await expectLater(
          sut.execute(sale, debtAmount: debt),
          throwsA(isA<ValidationFailure>()),
        );
      }
      expect(await db.select(db.saleTable).get(), isEmpty);
      expect(await db.select(db.paymentTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F1b — empty items rejected
  // ───────────────────────────────────────────────────────────────

  group('execute — total must match the items', () {
    test('throws a ValidationFailure and writes nothing when the total '
        'differs from quantity x unit price', () async {
      await expectLater(
        sut.execute(makeSale(total: 13001)),
        throwsA(isA<ValidationFailure>()),
      );

      expect(await db.select(db.saleTable).get(), isEmpty);
      expect(await db.select(db.saleItemTable).get(), isEmpty);
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
      expect(await db.select(db.paymentTable).get(), isEmpty);
    });

    test('accepts a total equal to its items', () async {
      await expectLater(sut.execute(makeSale(total: 13000)), completes);
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
    test(
      'a failing second write leaves no rows and no pending changes',
      () async {
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
        expect(
          await db.select(db.customerContainerBalanceTable).get(),
          isEmpty,
        );
        expect(await db.select(db.pendingChangeTable).get(), isEmpty);
      },
    );
  });
}
