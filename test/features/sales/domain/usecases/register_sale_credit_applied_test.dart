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

/// Credit in the customer's favor applied to a sale of 17500 (S2, S9).
void main() {
  late AppDatabase db;
  late DriftSaleRepository saleRepo;
  late DriftPaymentRepository paymentRepo;
  late RegisterSaleUseCase sut;

  const pack = Product(id: 'p-1', name: 'Pack', unitLabel: 'u', price: 17500);
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );

  Future<void> startAt(int balance) async {
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: drift.Value(balance),
          ),
        );
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
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

  Sale sale(
    PaymentMethod method, {
    required int creditApplied,
    int? cash,
    int? transfer,
  }) => Sale(
    id: 'sale-1',
    customer: customer,
    items: const [SaleItem(product: pack, quantity: 1)],
    total: 17500,
    paymentMethod: method,
    date: DateTime(2026, 11, 27, 10),
    cashAmount: cash,
    transferAmount: transfer,
    creditApplied: creditApplied,
  );

  Future<int> balance() => paymentRepo.watchCustomerBalance('c-1').first;

  Future<void> expectNothingWritten(int balanceBefore) async {
    expect(await db.select(db.saleTable).get(), isEmpty);
    expect(await db.select(db.paymentTable).get(), isEmpty);
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    expect(await balance(), balanceBefore);
  }

  Matcher failsWith(String message) => throwsA(
    isA<ValidationFailure>().having((f) => f.message, 'message', message),
  );

  test('S9: 17000 collected with 500 applied: one payment of 17000, the sale '
      'keeps 17500 and its credit applied, the account ends at 0', () async {
    await startAt(-500);

    await sut.execute(sale(PaymentMethod.cash, creditApplied: 500));

    final payment = (await paymentRepo.getSalePayments('sale-1')).single;
    expect((payment.type, payment.amount), (PaymentType.cash, 17000));
    final saved = await saleRepo.findSale('sale-1');
    expect(saved!.total, 17500);
    expect(saved.creditApplied, 500);
    expect(await balance(), 0);
  });

  test('a partial payment with credit leaves the rest owed', () async {
    await startAt(-500);

    await sut.execute(
      sale(PaymentMethod.cash, creditApplied: 500, cash: 10000),
    );

    expect(
      (await paymentRepo.getSalePayments('sale-1')).single.amount,
      10000,
    );
    expect(await balance(), 7000);
  });

  test('credit covering the whole total: no payments and the credit left '
      'stays', () async {
    // Enough credit for both sales.
    await startAt(-40000);

    for (final method in [PaymentMethod.cash, PaymentMethod.mixed]) {
      await sut.execute(
        Sale(
          id: 'sale-${method.name}',
          customer: customer,
          items: const [SaleItem(product: pack, quantity: 1)],
          total: 17500,
          paymentMethod: method,
          date: DateTime(2026, 11, 27, 10),
          creditApplied: 17500,
          cashAmount: method == PaymentMethod.mixed ? 0 : null,
          transferAmount: method == PaymentMethod.mixed ? 0 : null,
        ),
      );
      final saved = await saleRepo.findSale('sale-${method.name}');
      expect(saved!.creditApplied, 17500, reason: method.name);
    }

    expect(await db.select(db.paymentTable).get(), isEmpty);
    expect(await balance(), -40000 + 17500 + 17500);
  });

  test('money beyond the amount due stays as credit', () async {
    await startAt(-500);

    await sut.execute(
      sale(PaymentMethod.cash, creditApplied: 500),
      debtAmount: 1000,
    );

    final payments = await db.select(db.paymentTable).get();
    expect(
      payments.map((p) => (p.saleId, p.amount)).toSet(),
      {('sale-1', 17000), (null, 1000)},
    );
    expect(await balance(), -1000);
  });

  test('fiado with credit books the sale and no payment', () async {
    await startAt(-500);

    await sut.execute(sale(PaymentMethod.credit, creditApplied: 500));

    expect(await db.select(db.paymentTable).get(), isEmpty);
    expect((await saleRepo.findSale('sale-1'))!.creditApplied, 500);
    expect(await balance(), 17000);
  });

  group('rejected and nothing written', () {
    test('credit applied above the total', () async {
      await startAt(-20000);

      await expectLater(
        sut.execute(sale(PaymentMethod.credit, creditApplied: 17501)),
        failsWith(
          'El saldo a favor aplicado supera el total de la venta.',
        ),
      );
      await expectNothingWritten(-20000);
    });

    test('negative credit applied', () async {
      await startAt(-500);

      await expectLater(
        sut.execute(sale(PaymentMethod.cash, creditApplied: -1)),
        failsWith('El saldo a favor aplicado no puede ser negativo.'),
      );
      await expectNothingWritten(-500);
    });

    test('credit applied above the customer credit', () async {
      await startAt(-500);

      await expectLater(
        sut.execute(sale(PaymentMethod.cash, creditApplied: 600)),
        failsWith('El cliente no tiene saldo a favor suficiente.'),
      );
      await expectNothingWritten(-500);
    });

    test('nothing collected while money is due', () async {
      await startAt(-500);

      await expectLater(
        sut.execute(sale(PaymentMethod.cash, creditApplied: 500, cash: 0)),
        failsWith('Ingresá un monto cobrado mayor a \$0.'),
      );
      await expectNothingWritten(-500);
    });

    test('collected above the amount due without debt', () async {
      await startAt(-500);

      await expectLater(
        sut.execute(
          sale(PaymentMethod.cash, creditApplied: 500, cash: 17500),
        ),
        failsWith('Lo cobrado no puede superar el total de la venta.'),
      );
      await expectNothingWritten(-500);
    });
  });
}
