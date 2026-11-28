import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';

/// Partial payment (S2, S3, S5): the customer pays part of a 6500 sale on
/// the spot and owes the rest.
void main() {
  late AppDatabase db;
  late DriftSaleRepository saleRepo;
  late DriftPaymentRepository paymentRepo;
  late RegisterSaleUseCase sut;

  const jug = Product(
    id: 'p-jug',
    name: 'Bidón 20L',
    unitLabel: 'Bidón',
    price: 6500,
  );
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // Known locally, so the saved sale can be read back.
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    saleRepo = DriftSaleRepository(db);
    paymentRepo = DriftPaymentRepository(db);
    sut = RegisterSaleUseCase(
      saleRepo: saleRepo,
      paymentRepo: paymentRepo,
      inventoryRepo: DriftInventoryRepository(db),
      transaction: driftTransactionRunner(db),
    );
  });
  tearDown(() => db.close());

  Sale sale(PaymentMethod method, {int? cash, int? transfer}) => Sale(
    id: 'sale-1',
    customer: customer,
    items: const [SaleItem(product: jug, quantity: 1)],
    total: 6500,
    paymentMethod: method,
    date: DateTime(2026, 11, 25, 10),
    cashAmount: cash,
    transferAmount: transfer,
    visitId: 'v-1',
  );

  Future<int> balance() => paymentRepo.watchCustomerBalance('c-1').first;

  Future<List<Map<String, dynamic>>> queued(String entity) async => [
    for (final c in await db.select(db.pendingChangeTable).get())
      if (c.entity == entity) jsonDecode(c.payload!) as Map<String, dynamic>,
  ];

  Future<void> owe(int amount) async {
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: drift.Value(amount),
          ),
        );
  }

  Future<void> expectNothingWritten({int balanceBefore = 0}) async {
    expect(await db.select(db.saleTable).get(), isEmpty);
    expect(await db.select(db.paymentTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    expect(await balance(), balanceBefore);
  }

  group('S2/S5: the collected amount settles the sale', () {
    test('cash 6000 of 6500: one cash payment of 6000 linked to the sale, '
        'the sale keeps its 6500 and the balance rises by 500', () async {
      await sut.execute(sale(PaymentMethod.cash, cash: 6000));

      final payment = (await paymentRepo.getSalePayments('sale-1')).single;
      expect(payment.type, PaymentType.cash);
      expect(payment.amount, 6000);
      final saved = await saleRepo.findSale('sale-1');
      expect(saved!.total, 6500);
      expect(saved.paymentMethod, PaymentMethod.cash);
      expect(await balance(), 500);
    });

    test('transfer 6000 of 6500: one transfer payment of 6000 and the '
        'balance rises by 500', () async {
      await sut.execute(sale(PaymentMethod.transfer, transfer: 6000));

      final payment = (await paymentRepo.getSalePayments('sale-1')).single;
      expect(payment.type, PaymentType.transfer);
      expect(payment.amount, 6000);
      expect(payment.saleId, 'sale-1');
      expect(await balance(), 500);
    });

    test('mixed 4000 + 2000 of 6500: a cash and a transfer payment linked '
        'to the sale and the balance rises by 500', () async {
      await sut.execute(sale(PaymentMethod.mixed, cash: 4000, transfer: 2000));

      final payments = await queued('payment');
      expect(
        payments.map((p) => (p['paymentMethod'], p['amount'], p['saleId'])),
        [('EFECTIVO', 4000, 'sale-1'), ('TRANSFERENCIA', 2000, 'sale-1')],
      );
      for (final p in payments) {
        expect(p.containsKey('transactionUuid'), isFalse);
      }
      expect((await saleRepo.findSale('sale-1'))!.total, 6500);
      expect(await balance(), 500);
    });

    test('the queued sale keeps its total and method; no new key', () async {
      await sut.execute(sale(PaymentMethod.cash, cash: 6000));

      final queuedSale = (await queued('sale')).single;
      expect(queuedSale['total'], 6500);
      expect(queuedSale['paymentMethod'], 'cash');
      expect(queuedSale.keys.toSet(), {
        'saleId',
        'customerId',
        'total',
        'paymentMethod',
        'cashAmount',
        'transferAmount',
        'visitId',
        'date',
        'items',
      });
    });
  });

  group('S2: what cannot be collected', () {
    test('above the sale total is rejected and writes nothing', () async {
      for (final s in [
        sale(PaymentMethod.cash, cash: 7000),
        sale(PaymentMethod.transfer, transfer: 6600),
        sale(PaymentMethod.mixed, cash: 5000, transfer: 2000),
      ]) {
        await expectLater(
          sut.execute(s),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              'Lo cobrado no puede superar el total de la venta.',
            ),
          ),
          reason: s.paymentMethod.name,
        );
      }
      await expectNothingWritten();
    });

    test('0 collected is rejected and writes nothing', () async {
      for (final s in [
        sale(PaymentMethod.cash, cash: 0),
        sale(PaymentMethod.transfer, transfer: 0),
        sale(PaymentMethod.mixed, cash: 0, transfer: 0),
        sale(PaymentMethod.mixed),
      ]) {
        await expectLater(
          sut.execute(s),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              'Ingresá un monto cobrado mayor a \$0.',
            ),
          ),
          reason: '${s.paymentMethod.name} ${s.cashAmount} ${s.transferAmount}',
        );
      }
      await expectNothingWritten();
    });
  });

  group('S3: previous debt needs the sale paid in full', () {
    test('a partial cash or transfer sale cannot also collect debt', () async {
      await owe(7200);

      for (final s in [
        sale(PaymentMethod.cash, cash: 6000),
        sale(PaymentMethod.transfer, transfer: 6000),
      ]) {
        await expectLater(
          sut.execute(s, debtAmount: 1000),
          throwsA(
            isA<ValidationFailure>().having(
              (f) => f.message,
              'message',
              'Para cobrar deuda anterior, cobrá la venta completa.',
            ),
          ),
          reason: s.paymentMethod.name,
        );
      }
      await expectNothingWritten(balanceBefore: 7200);
    });
  });

  group('S6: full payment as before', () {
    test('cash, transfer and exact mixed settle the whole total and leave '
        'the balance where it was', () async {
      for (final (i, s) in [
        sale(PaymentMethod.cash),
        sale(PaymentMethod.transfer),
        sale(PaymentMethod.mixed, cash: 4000, transfer: 2500),
      ].indexed) {
        final local = Sale(
          id: 'sale-full-$i',
          customer: s.customer,
          items: s.items,
          total: s.total,
          paymentMethod: s.paymentMethod,
          date: s.date,
          cashAmount: s.cashAmount,
          transferAmount: s.transferAmount,
        );
        await sut.execute(local);

        final payments = await paymentRepo.getSalePayments(local.id);
        expect(
          payments.fold<int>(0, (sum, p) => sum + p.amount),
          6500,
          reason: s.paymentMethod.name,
        );
        expect(await balance(), 0, reason: s.paymentMethod.name);
      }
    });
  });
}
