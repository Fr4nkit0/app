import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/products/presentation/providers/product_list_provider.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../../../support/fake_http_adapter.dart';

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );

    final now = DateTime.now();
    for (final (id, serverId) in [('c-1', 10), ('c-2', 11)]) {
      await db.into(db.customerTable).insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value(id),
              name: id,
              serverId: drift.Value(serverId),
            ),
          );
    }
    for (final (id, name, price, serverId) in [
      ('p-1', 'Agua 20L', 1500.0, 21),
      ('p-2', 'Soda 2L', 400.0, 22),
      ('p-3', 'Sifón 1L', 900.0, 23),
    ]) {
      await db.into(db.productTable).insert(
            ProductTableCompanion.insert(
              productId: drift.Value(id),
              name: name,
              price: price,
              serverId: drift.Value(serverId),
            ),
          );
    }
    Future<void> agreement(
      int serverId,
      String customerId,
      String productId,
      double price,
      String from, [
      String? to,
    ]) => db.into(db.customerAgreementTable).insert(
          CustomerAgreementTableCompanion.insert(
            customerId: customerId,
            productId: productId,
            unitPrice: price,
            validFrom: from,
            validTo: drift.Value(to),
            serverId: drift.Value(serverId),
          ),
        );
    // In force since today, as the server sends it (full timestamp).
    await agreement(31, 'c-1', 'p-1', 1200, '${_day(now)}T00:00:00.000000Z');
    // Expired yesterday.
    final yesterday = _day(now.subtract(const Duration(days: 1)));
    await agreement(32, 'c-1', 'p-2', 300, '2020-01-01', yesterday);
    // Another customer's agreement.
    await agreement(33, 'c-2', 'p-3', 700, '2020-01-01');
  });

  // Riverpod pauses providers nobody listens to, as a screen would.
  Future<List<Product>> pricedFor(String customerId) {
    final provider = customerProductListProvider(customerId);
    container.listen(provider, (_, _) {});
    return container.read(provider.future);
  }

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'each product is priced from the customer agreement in force, or else from the list price',
    () async {
      final products = await pricedFor('c-1');

      final byId = {for (final p in products) p.id: p};
      expect(byId['p-1']!.price, 1200);
      expect(byId['p-1']!.agreementId, 31);
      expect(byId['p-2']!.price, 400);
      expect(byId['p-2']!.agreementId, isNull);
      expect(byId['p-3']!.price, 900);
      expect(byId['p-3']!.agreementId, isNull);
    },
  );

  test(
    'the draft totals at the agreement price and the sale uploads that price unchanged',
    () async {
      final products = await pricedFor('c-1');
      final water = products.firstWhere((p) => p.id == 'p-1');
      final soda = products.firstWhere((p) => p.id == 'p-2');
      final draft = container.read(saleDraftProvider.notifier)
        ..selectCustomer(customer)
        ..setQuantity(SaleItem(product: water, quantity: 0), 2)
        ..setQuantity(SaleItem(product: soda, quantity: 0), 1)
        ..setPaymentMethod(PaymentMethod.credit);

      expect(container.read(saleDraftProvider).total, 2800);

      await draft.commit();

      final bodies = <Map<String, dynamic>>[];
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = FakeHttpAdapter((options) {
          bodies.add(Map<String, dynamic>.from(options.data as Map));
          return FakeHttpAdapter.json(200, {
            'data': {'sales': []},
            'message': null,
          });
        });
      await SyncEngine(dio: dio, db: db, sync: SyncService(dio, db)).push();

      final sale = Map<String, dynamic>.from(
        (bodies.single['sales'] as List).single as Map,
      );
      expect(sale['total'], 2800.0);
      expect(sale['details'], [
        {
          'product_id': 21,
          'customer_agreement_id': 31,
          'quantity': 2,
          'unit_price': 1200.0,
        },
        {
          'product_id': 22,
          'customer_agreement_id': null,
          'quantity': 1,
          'unit_price': 400.0,
        },
      ]);
    },
  );

  test('changing the customer drops the lines priced for the previous one', () async {
    final water = (await pricedFor('c-1')).firstWhere((p) => p.id == 'p-1');
    container.read(saleDraftProvider.notifier)
      ..selectCustomer(customer)
      ..setQuantity(SaleItem(product: water, quantity: 0), 2)
      ..clearCustomer();

    expect(container.read(saleDraftProvider).items, isEmpty);
  });
}
