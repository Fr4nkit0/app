import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/route/data/repositories/repositories/drift_route_repository.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

const _entities = [
  'customers',
  'route_stops',
  'visits',
  'container_movements',
  'sales',
  'payments',
];

const _pullEntities = [
  'routes',
  'route_stops',
  'route_inventories',
  'customers',
  'customer_addresses',
  'customer_preferences',
  'customer_agreements',
  'customer_balances',
  'customer_container_balances',
  'products',
  'container_types',
  'payment_methods',
  'visit_outcomes',
];

/// Accepts every pushed record unless [answer] says otherwise, and answers
/// pulls with [pullRows].
class _FakeServer {
  final List<Json> pushBodies = [];
  Json? Function(String entity, Json record)? answer;
  Map<String, List<Json>> pullRows = {};
  int _nextId = 900;

  Future<ResponseBody> handle(RequestOptions options) async {
    if (options.path == '/sync/pull') {
      return FakeHttpAdapter.json(200, {
        'data': {for (final e in _pullEntities) e: pullRows[e] ?? const []},
        'meta': {
          'page': 1,
          'per_page': 200,
          'is_last_page': true,
          'until': '2026-10-19T13:00:00+00:00',
          'cursor': '2026-10-19T12:59:55+00:00',
        },
        'message': null,
      });
    }
    if (options.path != '/sync/push') {
      throw StateError('Unexpected request ${options.path}');
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    pushBodies.add(body);
    return FakeHttpAdapter.json(200, {
      'data': {
        for (final entity in _entities)
          entity: [
            for (final r in (body[entity] as List? ?? const []))
              answer?.call(entity, Map<String, dynamic>.from(r as Map)) ??
                  {
                    'uuid': (r as Map)['uuid'],
                    'status': 'accepted',
                    'server_id': ++_nextId,
                    'review_reason': null,
                  },
          ],
      },
      'message': null,
    });
  }
}

Json _rejected(Json record) => {
  'uuid': record['uuid'],
  'status': 'rejected',
  'server_id': null,
  'review_reason': null,
  'error': 'Invalid record.',
};

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;
  late SyncService sync;
  late PendingChangeRepository queue;
  late DriftPaymentRepository payments;
  late RegisterSaleUseCase registerSale;

  final soldAt = DateTime.utc(2026, 10, 19, 12, 30);
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );
  // The draft priced it from agreement 31 instead of the list price 1500.
  const water = Product(
    id: 'p-1',
    name: 'Agua 20L',
    unitLabel: '',
    price: 1200,
    agreementId: 31,
  );
  const soda = Product(id: 'p-2', name: 'Soda 2L', unitLabel: '', price: 400.5);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    sync = SyncService(dio, db);
    engine = SyncEngine(dio: dio, db: db, sync: sync);
    queue = DriftPendingChangeRepository(db);
    payments = DriftPaymentRepository(db);
    registerSale = RegisterSaleUseCase(
      saleRepo: DriftSaleRepository(db),
      paymentRepo: payments,
      inventoryRepo: DriftInventoryRepository(db),
      db: db,
    );

    // A day downloaded from the server: customer 10 owing 1000, stop 70.
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
          ),
        );
    await db.into(db.customerBalanceTable).insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: const drift.Value(1000),
            serverId: const drift.Value(500),
          ),
        );
    await db.into(db.routeTable).insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('r-1'),
            route_date: _today(),
            serverId: const drift.Value(7),
          ),
        );
    await db.into(db.routeStopTable).insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('s-1'),
            routeId: 'r-1',
            customerId: 'c-1',
            sequence: 1,
            scheduledAt: DateTime.now(),
            serverId: const drift.Value(70),
          ),
        );
    for (final (id, name, serverId) in [
      ('p-1', 'Agua 20L', 21),
      ('p-2', 'Soda 2L', 22),
    ]) {
      await db.into(db.productTable).insert(
            ProductTableCompanion.insert(
              productId: drift.Value(id),
              name: name,
              price: 1500,
              serverId: drift.Value(serverId),
            ),
          );
    }
    await db.into(db.containerTypeTable).insert(
          ContainerTypeTableCompanion.insert(
            id: const drift.Value(3),
            code: 'BIDON_20L',
          ),
        );
    for (final (id, code) in [(5, 'CASH'), (6, 'TRANSFER')]) {
      await db.into(db.paymentMethodTable).insert(
            PaymentMethodTableCompanion.insert(
              id: drift.Value(id),
              code: code,
              name: code,
            ),
          );
    }
  });
  tearDown(() => db.close());

  Future<void> sell({
    String id = 'sale-1',
    PaymentMethod method = PaymentMethod.credit,
    List<SaleItem> items = const [SaleItem(product: water, quantity: 2)],
    String? visitId,
    double? cash,
    double? transfer,
  }) async {
    final result = await registerSale.execute(
      Sale(
        id: id,
        customer: customer,
        items: items,
        total: items.fold(0.0, (sum, i) => sum + i.subtotal),
        paymentMethod: method,
        date: soldAt,
        visitId: visitId,
        cashAmount: cash,
        transferAmount: transfer,
      ),
    );
    expect(result, isA<Success<void>>());
  }

  Future<void> pay({
    String id = 'pay-1',
    double amount = 500,
    PaymentType type = PaymentType.cash,
    String? visitId,
  }) => payments.recordPayment(
    Payment(
      id: id,
      customerId: 'c-1',
      amount: amount,
      type: type,
      createdAt: soldAt,
      visitId: visitId,
    ),
  );

  Future<void> recordVisit() => DriftVisitRepository(db).recordVisit(
    Visit(
      visitId: 'v-1',
      routeStopId: 's-1',
      customerId: 'c-1',
      visitType: VisitType.visit,
      arrivedAt: soldAt,
    ),
  );

  List<Json> sent(String entity) => [
    for (final r in (server.pushBodies.last[entity] as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  Future<double> displayedBalance() =>
      payments.watchCustomerBalance('c-1').first;

  test('sales and payments travel after visits and container movements', () async {
    await pay();
    await sell();
    await recordVisit();
    await DriftInventoryRepository(db).recordContainerMovement(
      ContainerMovement(
        id: 'm-1',
        customerId: 'c-1',
        containerType: 'BIDON_20L',
        deliveredQuantity: 2,
        returnedQuantity: 0,
        createdAt: soldAt,
      ),
    );

    await engine.push();

    expect(server.pushBodies.single.keys.toList(), [
      'visits',
      'container_movements',
      'sales',
      'payments',
    ]);
  });

  test(
    'a sale travels with its details and the unit prices the draft computed, linked to the visit of its stop, and stores its server id',
    () async {
      await recordVisit();
      await sell(
        items: const [
          SaleItem(product: water, quantity: 2),
          SaleItem(product: soda, quantity: 1),
        ],
        // The visit screen links a sale to the stop being visited.
        visitId: 's-1',
      );

      await engine.push();

      expect(sent('sales'), [
        {
          'uuid': 'sale-1',
          'customer_id': 10,
          'visit_uuid': 'v-1',
          'date': '2026-10-19T12:30:00.000Z',
          'total': 2800.5,
          'is_credit_sale': true,
          'notes': null,
          'details': [
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
              'unit_price': 400.5,
            },
          ],
        },
      ]);
      expect(sent('payments'), isEmpty);
      final row = await db.select(db.saleTable).getSingle();
      expect(row.serverId, isNotNull);
      expect(await queue.countPending(), 0);
    },
  );

  test(
    'a sale paid on the spot is settled by payments linked to it',
    () async {
      await sell(method: PaymentMethod.mixed, cash: 1000, transfer: 1400);

      await engine.push();

      expect(sent('sales').single['is_credit_sale'], false);
      final settled = sent('payments');
      expect(settled.map((p) => p['sale_uuid']), ['sale-1', 'sale-1']);
      expect(settled.map((p) => p['payment_method_id']), [5, 6]);
      expect(settled.map((p) => p['amount']), [1000.0, 1400.0]);
      expect(await displayedBalance(), 1000);
    },
  );

  test(
    'a payment travels with or without a visit and stores its server id',
    () async {
      await recordVisit();
      // From the customer profile: no visit, no sale.
      await pay(id: 'pay-1', amount: 500);
      // From the visit screen, linked to the stop being visited.
      await pay(
        id: 'pay-2',
        amount: 250,
        type: PaymentType.transfer,
        visitId: 's-1',
      );

      await engine.push();

      expect(sent('payments'), [
        {
          'uuid': 'pay-1',
          'customer_id': 10,
          'payment_method_id': 5,
          'amount': 500.0,
          'paid_at': '2026-10-19T12:30:00.000Z',
        },
        {
          'uuid': 'pay-2',
          'customer_id': 10,
          'visit_uuid': 'v-1',
          'payment_method_id': 6,
          'amount': 250.0,
          'paid_at': '2026-10-19T12:30:00.000Z',
        },
      ]);
      final rows = await db.select(db.paymentTable).get();
      expect(rows.map((r) => r.serverId), everyElement(isNotNull));
      expect(await queue.countPending(), 0);
    },
  );

  test(
    'a sale of a product the server does not know is rejected on the device',
    () async {
      await db.into(db.productTable).insert(
            ProductTableCompanion.insert(
              productId: const drift.Value('p-local'),
              name: 'Local',
              price: 10,
            ),
          );
      await sell(
        items: const [
          SaleItem(
            product: Product(id: 'p-local', name: 'Local', unitLabel: '', price: 10),
            quantity: 1,
          ),
        ],
      );

      await engine.push();

      expect(server.pushBodies, isEmpty);
      final rejected = await queue.getRejected();
      expect(rejected.single.entityId, 'sale-1');
      expect(await displayedBalance(), 1000);
    },
  );

  test(
    'the balance shown in the profile and on the stop includes pending sales and payments',
    () async {
      await sell(); // credit 2400
      await pay(amount: 500);

      expect(await displayedBalance(), 2900);
      final stop = (await DriftRouteRepository(db).watchDayStops().first).single;
      expect(stop.customer.debtAmount, 2900);
    },
  );

  test(
    'a download replaces the balance with the server one plus what is still pending',
    () async {
      await db.into(db.syncStateTable).insert(
            SyncStateTableCompanion.insert(
              key: SyncService.pullCursorKey,
              value: '2026-10-19T12:00:00+00:00',
            ),
          );
      await sell(); // credit 2400, accepted by this push
      await engine.push();
      await pay(amount: 500); // still pending
      server.pullRows = {
        'customer_balances': [
          {'id': 500, 'customer_id': 10, 'current_balance': '3300.00', 'enabled': true},
        ],
      };

      await sync.pull();

      expect(await displayedBalance(), 2800);
      final stop = (await DriftRouteRepository(db).watchDayStops().first).single;
      expect(stop.customer.debtAmount, 2800);
    },
  );

  test(
    'a sale or payment the server rejects no longer counts in the balance',
    () async {
      await sell(); // credit 2400
      await pay(amount: 300);
      server.answer = (entity, r) => _rejected(r);

      await engine.push();

      expect((await queue.getRejected()).length, 2);
      expect(await displayedBalance(), 1000);
    },
  );
}
