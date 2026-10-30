import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/usecases/cancel_payment.usecase.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/cancel_sale.usecase.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show dateOnly;
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

const _entities = [
  'sales',
  'payments',
  'sale_cancellations',
  'payment_cancellations',
];

/// Accepts every pushed record unless [answer] says otherwise; a
/// cancellation answers the id of the record it cancels.
class _FakeServer {
  final List<Json> pushBodies = [];
  Json? Function(String entity, Json record)? answer;
  Map<String, List<Json>> pullRows = {};
  int _nextId = 900;

  Future<ResponseBody> handle(RequestOptions options) async {
    if (options.path == '/sync/pull') {
      return FakeHttpAdapter.json(200, {
        'data': pullRows,
        'meta': {
          'page': 1,
          'per_page': 200,
          'is_last_page': true,
          'until': '2026-10-29T13:00:00+00:00',
          'cursor': '2026-10-29T12:59:55+00:00',
        },
        'message': null,
      });
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
  'error': 'Only today\'s records can be cancelled.',
};

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;
  late SyncService sync;
  late PendingChangeRepository queue;
  late DriftPaymentRepository payments;

  // Whole seconds: the database stores dates at that precision.
  final now = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch ~/ 1000 * 1000,
  );
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );
  const water = Product(id: 'p-1', name: 'Agua 20L', unitLabel: '', price: 1200);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    sync = SyncService(dio, db);
    engine = SyncEngine(dio: dio, db: db, sync: sync);
    queue = DriftPendingChangeRepository(db);
    payments = DriftPaymentRepository(db);

    await db
        .into(db.customerTable)
        .insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
          ),
        );
    await db
        .into(db.customerBalanceTable)
        .insert(
          CustomerBalanceTableCompanion.insert(
            customerId: 'c-1',
            currentBalance: const drift.Value(1000),
            serverId: const drift.Value(500),
          ),
        );
    await db
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('r-1'),
            route_date: dateOnly(now),
            serverId: const drift.Value(7),
          ),
        );
    await db
        .into(db.routeStopTable)
        .insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('s-1'),
            routeId: 'r-1',
            customerId: 'c-1',
            sequence: 1,
            scheduledAt: now,
            serverId: const drift.Value(70),
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
            serverId: const drift.Value(21),
          ),
        );
    await db
        .into(db.paymentMethodTable)
        .insert(
          PaymentMethodTableCompanion.insert(
            id: const drift.Value(5),
            code: 'CASH',
            name: 'Cash',
          ),
        );
  });
  tearDown(() => db.close());

  Future<Sale> sell({
    PaymentMethod method = PaymentMethod.cash,
    String? visitId,
  }) async {
    final sale = Sale(
      id: 'sale-1',
      customer: customer,
      items: const [SaleItem(product: water, quantity: 2)],
      total: 2400,
      paymentMethod: method,
      date: now,
      visitId: visitId,
    );
    await RegisterSaleUseCase(
      saleRepo: DriftSaleRepository(db),
      paymentRepo: payments,
      inventoryRepo: DriftInventoryRepository(db),
      transaction: driftTransactionRunner(db),
    ).execute(sale);
    return sale;
  }

  Future<void> cancelSale({String? reason}) => CancelSaleUseCase(
    saleRepo: DriftSaleRepository(db),
    paymentRepo: payments,
    transaction: driftTransactionRunner(db),
    now: () => now,
  ).execute('sale-1', reason: reason);

  Future<void> payDebt() => payments.recordPayment(
    Payment(
      id: 'pay-debt',
      customerId: 'c-1',
      amount: 500,
      type: PaymentType.cash,
      createdAt: now,
    ),
  );

  Future<void> cancelDebtPayment() => CancelPaymentUseCase(
    paymentRepo: payments,
    transaction: driftTransactionRunner(db),
    now: () => now,
  ).execute('pay-debt', reason: 'Error de carga');

  List<Json> sent(String entity, [int request = -1]) => [
    for (final r
        in (server.pushBodies[request < 0
                    ? server.pushBodies.length + request
                    : request][entity]
                as List? ??
            const []))
      Map<String, dynamic>.from(r as Map),
  ];

  Future<double> balance() => payments.watchCustomerBalance('c-1').first;

  Future<int> stock() async =>
      (await db.select(db.productTable).getSingle()).stock;

  test('cancellations travel after sales and payments, referencing a record '
      'sent in the same request by its uuid', () async {
    final sale = await sell();
    await payDebt();
    await cancelSale(reason: 'Cliente devolvió');
    await cancelDebtPayment();
    final settling = RegisterSaleUseCase.settlingPayments(sale).single;

    await engine.push();

    expect(server.pushBodies.single.keys.toList(), [
      'sales',
      'payments',
      'sale_cancellations',
      'payment_cancellations',
    ]);
    final cancelledAt = now.toUtc().toIso8601String();
    final saleCancellation = sent('sale_cancellations').single;
    expect(saleCancellation['uuid'], isA<String>());
    expect(saleCancellation['uuid'], isNot('sale-1'));
    expect(saleCancellation, {
      'uuid': saleCancellation['uuid'],
      'sale_uuid': 'sale-1',
      'cancelled_at': cancelledAt,
      'reason': 'Cliente devolvió',
    });
    expect(cancelledAt, endsWith('Z'));
    final paymentCancellations = sent('payment_cancellations');
    expect(
      {for (final c in paymentCancellations) c['payment_uuid']: c['reason']},
      {settling.id: 'Cliente devolvió', 'pay-debt': 'Error de carga'},
    );
    for (final c in paymentCancellations) {
      expect(c['cancelled_at'], cancelledAt);
      expect(c.containsKey('payment_id'), isFalse);
    }
    expect(await queue.countPending(), 0);
    expect(await queue.getRejected(), isEmpty);
  });

  test('a record the server already has is referenced by its id', () async {
    await sell();
    await payDebt();
    await engine.push();
    final saleServerId =
        (await db.select(db.saleTable).getSingle()).serverId;
    final debtServerId = (await (db.select(
      db.paymentTable,
    )..where((t) => t.paymentId.equals('pay-debt'))).getSingle()).serverId;

    await cancelSale();
    await cancelDebtPayment();
    await engine.push();

    expect(server.pushBodies.last.keys.toList(), [
      'sale_cancellations',
      'payment_cancellations',
    ]);
    final saleCancellation = sent('sale_cancellations').single;
    expect(saleCancellation['sale_id'], saleServerId);
    expect(saleCancellation.containsKey('sale_uuid'), isFalse);
    expect(saleCancellation['reason'], isNull);
    expect(
      sent('payment_cancellations').map((c) => c['payment_id']),
      contains(debtServerId),
    );
  });

  test('a cancellation of a sale made during an open visit waits with '
      'it', () async {
    await sell(visitId: 's-1');
    await cancelSale();

    await engine.push();

    for (final body in server.pushBodies) {
      expect(body.containsKey('sale_cancellations'), isFalse);
      expect(body.containsKey('payment_cancellations'), isFalse);
    }
    expect(await queue.getRejected(), isEmpty);

    await DriftVisitRepository(db).recordVisit(
      Visit(
        visitId: 'v-1',
        routeStopId: 's-1',
        customerId: 'c-1',
        visitType: VisitType.sale,
        arrivedAt: now,
      ),
    );
    await engine.push();

    expect(sent('sale_cancellations'), hasLength(1));
    expect(sent('payment_cancellations'), hasLength(1));
  });

  test('a rejected cancellation restores the sale, its payments, the '
      'balance and the stock', () async {
    await sell(method: PaymentMethod.cash);
    await engine.push();
    final balanceAfterSale = await balance();
    await cancelSale();
    expect(await stock(), 10);
    server.answer = (entity, r) => _rejected(r);

    await engine.push();

    expect((await queue.getRejected()).length, 2);
    final sale = await db.select(db.saleTable).getSingle();
    expect(sale.status, 'CONFIRMED');
    expect(sale.cancelledAt, isNull);
    expect(
      (await db.select(db.paymentTable).get()).map((p) => p.status),
      everyElement('CONFIRMED'),
    );
    expect(await balance(), balanceAfterSale);
    expect(await stock(), 8);
    final types = (await db.select(
      db.customerAccountEntryTable,
    ).get()).map((e) => e.entryType);
    expect(types, isNot(contains('CREDIT_NOTE')));
    expect(types, isNot(contains('ADJUSTMENT')));
  });

  test('a rejected payment cancellation restores the payment and the '
      'debt', () async {
    await payDebt();
    await engine.push();
    await cancelDebtPayment();
    expect(await balance(), 1000);
    server.answer = (entity, r) => _rejected(r);

    await engine.push();

    final payment = await db.select(db.paymentTable).getSingle();
    expect(payment.status, 'CONFIRMED');
    expect(await balance(), 500);
  });

  test('a download keeps a pending cancellation in the balance and the '
      'truck stock', () async {
    await db
        .into(db.syncStateTable)
        .insert(
          SyncStateTableCompanion.insert(
            key: SyncService.pullCursorKey,
            value: '2026-10-29T12:00:00+00:00',
          ),
        );
    await sell(method: PaymentMethod.credit); // accepted by this push
    await engine.push();
    await cancelSale(); // still pending
    server.pullRows = {
      'customer_balances': [
        {
          'id': 500,
          'customer_id': 10,
          'current_balance': '3400.00',
          'enabled': true,
        },
      ],
      'route_inventories': [
        {
          'id': 900,
          'route_id': 7,
          'product_id': 21,
          'current_quantity': '8.00',
          'enabled': true,
        },
      ],
    };

    await sync.pull();

    expect(await balance(), 1000);
    expect(await stock(), 10);
  });
}
