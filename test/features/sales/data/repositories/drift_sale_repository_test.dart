import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

void main() {
  late AppDatabase db;
  late DriftSaleRepository sut;

  const product = Product(
    id: 'p-1',
    name: 'Agua 20L',
    unitLabel: 'Bidón',
    price: 1500,
  );
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftSaleRepository(db);
    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db
        .into(db.productTable)
        .insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
          ),
        );
  });
  tearDown(() => db.close());

  Sale sale(String id, {String? visitId}) => Sale(
    id: id,
    customer: customer,
    items: const [SaleItem(product: product, quantity: 2)],
    total: 3000,
    paymentMethod: PaymentMethod.cash,
    date: DateTime(2026, 10, 28, 10),
    visitId: visitId,
  );

  group('watchVisitSales', () {
    test('emits only the sales of the visit, with their items', () async {
      await sut.saveSale(sale('sale-1', visitId: 'stop-1'));
      await sut.saveSale(sale('sale-2', visitId: 'stop-2'));
      await sut.saveSale(sale('sale-3'));

      final sales = await sut.watchVisitSales('stop-1').first;

      expect(sales.map((s) => s.id), ['sale-1']);
      expect(sales.single.visitId, 'stop-1');
      expect(sales.single.customer.name, 'Kiosco Norte');
      expect(sales.single.items.single.quantity, 2);
      expect(sales.single.items.single.product.price, 1500);
    });

    test('emits an empty list for a visit without sales', () async {
      await sut.saveSale(sale('sale-1', visitId: 'stop-2'));

      expect(await sut.watchVisitSales('stop-1').first, isEmpty);
    });

    test('emits again when a sale of the visit is saved', () async {
      final emissions = sut.watchVisitSales('stop-1');
      final expectation = expectLater(
        emissions.map((sales) => sales.map((s) => s.id).toList()),
        emitsInOrder([
          isEmpty,
          ['sale-1'],
        ]),
      );
      await Future<void>.delayed(Duration.zero);
      await sut.saveSale(sale('sale-1', visitId: 'stop-1'));
      await expectation;
    });
  });
}
