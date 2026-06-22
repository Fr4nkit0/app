import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
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
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Sale makeSale({
    String id = 'sale-test-1',
    List<SaleItem>? items,
    String? visitId,
  }) {
    return Sale(
      id: id,
      customer: testCustomer,
      items: items ?? [const SaleItem(product: testProduct, quantity: 2)],
      total: 13000.0,
      paymentMethod: PaymentMethod.cash,
      date: DateTime.now(),
      visitId: visitId,
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Scenario F1a — success
  // ───────────────────────────────────────────────────────────────

  group('execute — success', () {
    test('F1a: returns Resource.success(null) for sale with 1 item', () async {
      final result = await sut.execute(makeSale());

      expect(result, isA<Success<void>>());
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
      );
      await sut.execute(sale);

      final rows = await db.select(db.saleItemTable).get();
      expect(rows.length, 2);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F1b — empty items rejected
  // ───────────────────────────────────────────────────────────────

  group('execute — empty items', () {
    test('F1b: returns Resource.error when items is empty', () async {
      final result = await sut.execute(makeSale(items: []));

      expect(result, isA<Error<void>>());
    });

    test('F1b: SaleTable stays empty when items is empty', () async {
      await sut.execute(makeSale(items: []));

      final rows = await db.select(db.saleTable).get();
      expect(rows, isEmpty);
    });
  });
}
