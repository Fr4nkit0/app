import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/data/repositories/drift.customer_agreement.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/products/data/repositories/drift.product.repository.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/push/agreement_pusher.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

void main() {
  late AppDatabase db;
  late List<Json> bodies;
  late SyncEngine engine;
  late SyncService sync;
  late DriftCustomerAgreementRepository agreements;
  late int nextId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    bodies = [];
    nextId = 900;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter((options) async {
        if (options.path == '/sync/pull') {
          return FakeHttpAdapter.json(200, {
            'data': {
              'customer_agreements': [
                {
                  'id': 777,
                  'client_uuid': pulledUuid,
                  'customer_id': 10,
                  'product_id': 21,
                  'unit_price': '1250.00',
                  'valid_from': '2026-10-22',
                  'valid_to': null,
                  'reason': 'Acuerdo',
                },
              ],
            },
            'meta': {
              'page': 1,
              'per_page': 200,
              'is_last_page': true,
              'until': '2026-10-22T13:00:00+00:00',
              'cursor': '2026-10-22T12:59:55+00:00',
            },
            'message': null,
          });
        }
        final body = Map<String, dynamic>.from(options.data as Map);
        bodies.add(body);
        return FakeHttpAdapter.json(200, {
          'data': {
            for (final e in body.entries)
              e.key: [
                for (final r in e.value as List)
                  {
                    'uuid': (r as Map)['uuid'],
                    'status': 'accepted',
                    'server_id': ++nextId,
                    'review_reason': null,
                  },
              ],
          },
          'message': null,
        });
      });
    sync = SyncService(dio, db);
    engine = SyncEngine(dio: dio, db: db, sync: sync);
    agreements = DriftCustomerAgreementRepository(db);

    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
          ),
        );
    await db.into(db.productTable).insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-1'),
            name: 'Agua 20L',
            price: 1500,
            serverId: const drift.Value(21),
          ),
        );
  });
  tearDown(() => db.close());

  Future<String> createAgreement({
    String? validTo,
    String? reason,
    double price = 1200,
  }) async {
    final result = await agreements.create(
      customerId: 'c-1',
      productId: 'p-1',
      unitPrice: price,
      validFrom: '2026-10-22',
      validTo: validTo,
      reason: reason,
    );
    return (result as Success<String>).value;
  }

  Future<void> syncCustomer() => (db.update(db.customerTable)
        ..where((t) => t.customerId.equals('c-1')))
      .write(const CustomerTableCompanion(serverId: drift.Value(10)));

  Future<void> sellWithAgreement() async {
    final products =
        await DriftProductRepository(db).watchProductsFor('c-1').first;
    final registerSale = RegisterSaleUseCase(
      saleRepo: DriftSaleRepository(db),
      paymentRepo: DriftPaymentRepository(db),
      inventoryRepo: DriftInventoryRepository(db),
      transaction: driftTransactionRunner(db),
    );
    await registerSale.execute(
      Sale(
        id: 'sale-1',
        customer: Customer(
          id: 'c-1',
          name: 'Kiosco Norte',
          addresses: const [],
          preferences: const [],
        ),
        items: [SaleItem(product: products.single, quantity: 2)],
        total: products.single.price * 2,
        paymentMethod: PaymentMethod.credit,
        date: DateTime.utc(2026, 10, 22, 12),
      ),
    );
  }

  test('an agreement travels after customers and before sales', () async {
    final id = await createAgreement(validTo: '2026-12-31', reason: 'Mayorista');
    await sellWithAgreement();
    await syncCustomer();

    await engine.push();

    final body = bodies.single;
    expect(body.keys.toList(), ['customer_agreements', 'sales']);
    expect(body['customer_agreements'], [
      {
        'uuid': id,
        'customer_id': 10,
        'product_id': 21,
        'unit_price': 1200.0,
        'valid_from': '2026-10-22',
        'valid_to': '2026-12-31',
        'reason': 'Mayorista',
      },
    ]);
  });

  test('an agreement of an unsent customer references it by uuid', () async {
    final id = await createAgreement();

    await engine.push();

    final record = (bodies.single['customer_agreements'] as List).single as Map;
    expect(record['customer_uuid'], 'c-1');
    expect(record.containsKey('customer_id'), isFalse);
    expect(record['uuid'], id);
    expect(record['valid_to'], isNull);
    expect(record['reason'], isNull);
  });

  test('accepted agreements store the server id', () async {
    final id = await createAgreement();

    await engine.push();

    final row = await (db.select(db.customerAgreementTable)
          ..where((t) => t.agreementId.equals(id)))
        .getSingle();
    expect(row.serverId, 901);
    expect(await DriftPendingChangeRepository(db).getPending(), isEmpty);
  });

  test('an agreement whose product has no server id is rejected locally', () async {
    await (db.update(db.productTable)
          ..where((t) => t.productId.equals('p-1')))
        .write(const ProductTableCompanion(serverId: drift.Value(null)));
    await createAgreement();

    await engine.push();

    expect(bodies, isEmpty);
    final rejected = await DriftPendingChangeRepository(db).getRejected();
    expect(rejected.single.rejectionReason, AgreementPusher.unknownProduct('Agua 20L'));
  });

  test('a sale line sends the agreement uuid while it has no server id', () async {
    final id = await createAgreement();
    await sellWithAgreement();

    await engine.push();

    final line = (((bodies.single['sales'] as List).single as Map)['details']
            as List)
        .single as Map;
    expect(line['customer_agreement_uuid'], id);
    expect(line.containsKey('customer_agreement_id'), isFalse);
  });

  test('a sale line sends the agreement server id once the agreement has one', () async {
    final id = await createAgreement();
    await sellWithAgreement();
    await (db.update(db.customerAgreementTable)
          ..where((t) => t.agreementId.equals(id)))
        .write(const CustomerAgreementTableCompanion(serverId: drift.Value(55)));
    // The agreement already reached the server in an earlier cycle.
    await (db.delete(db.pendingChangeTable)
          ..where((t) => t.entity.equals('customer_agreement')))
        .go();

    await engine.push();

    final line = (((bodies.single['sales'] as List).single as Map)['details']
            as List)
        .single as Map;
    expect(line['customer_agreement_id'], 55);
    expect(line.containsKey('customer_agreement_uuid'), isFalse);
  });

  test('a pulled agreement with client_uuid updates the local row', () async {
    final id = await createAgreement();
    pulledUuid = id;
    await syncCustomer();
    await db.into(db.productTable).insert(
          ProductTableCompanion.insert(
            productId: const drift.Value('p-2'),
            name: 'Otro',
            price: 1,
            serverId: const drift.Value(22),
          ),
        );

    await sync.pull();

    final rows = await db.select(db.customerAgreementTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.agreementId, id);
    expect(rows.single.serverId, 777);
    expect(rows.single.unitPrice, 1250);
  });

  test('bootstrap does not duplicate a pushed agreement', () async {
    final id = await createAgreement();
    await syncCustomer();
    await (db.update(db.customerAgreementTable)
          ..where((t) => t.agreementId.equals(id)))
        .write(const CustomerAgreementTableCompanion(serverId: drift.Value(777)));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter((_) async => FakeHttpAdapter.json(200, {
            'data': {
              'customers': [
                {
                  'id': 10,
                  'client_uuid': 'c-1',
                  'name': 'Kiosco Norte',
                  'agreements': [
                    {
                      'id': 777,
                      'client_uuid': id,
                      'customer_id': 10,
                      'product_id': 21,
                      'unit_price': '1250.00',
                      'valid_from': '2026-10-22',
                      'valid_to': null,
                      'reason': null,
                    },
                  ],
                },
              ],
              'products': [
                {'id': 21, 'client_uuid': 'p-1', 'name': 'Agua 20L'},
              ],
              'server_time': '2026-10-22T12:00:00+00:00',
            },
          }));

    await SyncService(dio, db).bootstrap();

    final rows = await db.select(db.customerAgreementTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.agreementId, id);
    expect(rows.single.unitPrice, 1250);
  });
}

String pulledUuid = '';
