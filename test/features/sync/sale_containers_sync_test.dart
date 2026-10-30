import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/data/repositories/drift.sale.repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/cancel_sale.usecase.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show dateOnly;
import 'package:app/features/sync/push/container_movement_pusher.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

/// Contract v3: containers delivered and returned with a sale travel with
/// its reference, and cancelling the sale takes them back out of custody.
///
/// The server answers each pushed record with the id in [serverIds] (or a
/// new one), unless [answer] says otherwise; a record [answer] maps to
/// null goes unanswered. The bootstrap answers [day].
class _FakeServer {
  final List<Json> pushBodies = [];
  final Map<String, int> serverIds = {};
  Json? Function(String entity, Json record)? answer;
  Json day = const {};
  int _nextId = 900;

  Future<ResponseBody> handle(RequestOptions options) async {
    if (options.path == '/sync/bootstrap') {
      return FakeHttpAdapter.json(200, day);
    }
    if (options.path != '/sync/push') {
      throw StateError('Unexpected request ${options.path}');
    }
    final body = Map<String, dynamic>.from(options.data as Map);
    pushBodies.add(body);
    return FakeHttpAdapter.json(200, {
      'data': {
        for (final MapEntry(key: entity, value: records) in body.entries)
          entity: [
            for (final r in records as List)
              ?(answer ?? _accept)(entity, Map<String, dynamic>.from(r as Map)),
          ],
      },
      'message': null,
    });
  }

  Json _accept(String entity, Json record) => {
    'uuid': record['uuid'],
    'status': 'accepted',
    'server_id': serverIds[record['uuid']] ?? ++_nextId,
    'review_reason': null,
  };

  Json accept(String entity, Json record) => _accept(entity, record);
}

Json _movement({
  required int id,
  String? clientUuid,
  required String type,
  required int quantity,
  int? saleId = 601,
  int? reverses,
  required String date,
}) => {
  'id': id,
  'client_uuid': clientUuid,
  'customer_id': 12,
  'visit_id': null,
  'sale_id': saleId,
  'container_type_id': 1,
  'movement_type': type,
  'quantity': quantity,
  'direction': type == 'DELIVERED' ? 1 : -1,
  'reverses_movement_id': reverses,
  'created_by': 1,
  'needs_review': false,
  'review_reason': null,
  'created_at': '${date}T13:10:00.000000Z',
  'updated_at': '${date}T13:10:00.000000Z',
};

/// Today's route for customer 12 (`c-1` on the device), who holds
/// [custody] jugs on the server.
Json _day(
  String date, {
  required int custody,
  List<Json> sales = const [],
  List<Json> movements = const [],
}) => {
  'data': {
    'route': {'id': 7, 'date': date, 'status': 'IN_PROGRESS'},
    'stops': [
      {'id': 72, 'route_id': 7, 'customer_id': 12, 'status': 'FINISHED'},
    ],
    'customers': [
      {
        'id': 12,
        'client_uuid': 'c-1',
        'name': 'Kiosco Norte',
        'balance': {'current_balance': '0.00'},
        'container_balances': [
          {'container_type_id': 1, 'balance': custody},
        ],
      },
    ],
    'products': [
      {'id': 21, 'name': 'Agua 20L', 'price': '1200.00'},
    ],
    'container_types': [
      {'id': 1, 'code': 'BIDON_20L', 'description': 'Bidón 20L'},
    ],
    'payment_methods': [
      {'id': 5, 'code': 'CASH', 'name': 'Efectivo'},
    ],
    'visits': const [],
    'sales': sales,
    'payments': const [],
    'container_movements': movements,
    'server_time': '${date}T12:00:00+00:00',
  },
  'message': null,
};

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncService sync;
  late SyncEngine engine;
  late PendingChangeRepository queue;

  // Whole seconds: the database stores dates at that precision.
  final now = DateTime.fromMillisecondsSinceEpoch(
    DateTime.now().millisecondsSinceEpoch ~/ 1000 * 1000,
  );
  final today = dateOnly(now);
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  );
  // Delivers 2 jugs and takes 1 back with the sale.
  const withSale = 'm-sale';
  // A return without a sale.
  const loose = 'm-loose';

  late String stopId;
  late Product water;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    sync = SyncService(dio, db, today: () => now);
    engine = SyncEngine(dio: dio, db: db, sync: sync, now: () => now);
    queue = DriftPendingChangeRepository(db);

    server.day = _day(today, custody: 5);
    await sync.bootstrap();
    stopId = (await db.select(db.routeStopTable).getSingle()).routeStopId;
    final product = await db.select(db.productTable).getSingle();
    water = Product(
      id: product.productId,
      name: product.name,
      unitLabel: '',
      price: 1200,
    );
    server.serverIds.addAll({
      'sale-1': 601,
      withSale: 801,
      ContainerMovementPusher.returnUuid(withSale): 802,
      ContainerMovementPusher.returnUuid(loose): 803,
    });
  });
  tearDown(() => db.close());

  ContainerMovement movement(
    String id, {
    int delivered = 0,
    int returned = 0,
  }) => ContainerMovement(
    id: id,
    customerId: 'c-1',
    containerType: 'BIDON_20L',
    deliveredQuantity: delivered,
    returnedQuantity: returned,
    createdAt: now,
    visitId: stopId,
  );

  Future<void> sell() =>
      RegisterSaleUseCase(
        saleRepo: DriftSaleRepository(db),
        paymentRepo: DriftPaymentRepository(db),
        inventoryRepo: DriftInventoryRepository(db),
        transaction: driftTransactionRunner(db),
      ).execute(
        Sale(
          id: 'sale-1',
          customer: customer,
          items: [SaleItem(product: water, quantity: 2)],
          total: 2400,
          paymentMethod: PaymentMethod.credit,
          date: now,
          visitId: stopId,
        ),
        containerMovements: [movement(withSale, delivered: 2, returned: 1)],
      );

  Future<void> returnLoose() => DriftInventoryRepository(
    db,
  ).recordContainerMovement(movement(loose, returned: 1));

  Future<void> cancelSale() => CancelSaleUseCase(
    saleRepo: DriftSaleRepository(db),
    paymentRepo: DriftPaymentRepository(db),
    inventoryRepo: DriftInventoryRepository(db),
    transaction: driftTransactionRunner(db),
    now: () => now,
  ).execute('sale-1');

  List<Json> sent(String entity) => [
    for (final r in (server.pushBodies.last[entity] as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  Future<int> custody() async =>
      (await db.select(db.customerContainerBalanceTable).getSingle()).quantity;

  /// The server's movements once sale 601 was cancelled: the sale's two
  /// halves, the loose return, and the reversal of each half.
  List<Json> cancelledDay() => [
    _movement(
      id: 801,
      clientUuid: withSale,
      type: 'DELIVERED',
      quantity: 2,
      date: today,
    ),
    _movement(
      id: 802,
      clientUuid: ContainerMovementPusher.returnUuid(withSale),
      type: 'RETURNED',
      quantity: 1,
      date: today,
    ),
    _movement(
      id: 803,
      clientUuid: ContainerMovementPusher.returnUuid(loose),
      type: 'RETURNED',
      quantity: 1,
      saleId: null,
      date: today,
    ),
    _movement(
      id: 804,
      type: 'RETURNED',
      quantity: 2,
      reverses: 801,
      date: today,
    ),
    _movement(
      id: 805,
      type: 'DELIVERED',
      quantity: 1,
      reverses: 802,
      date: today,
    ),
  ];

  Json cancelledSale() => {
    'id': 601,
    'client_uuid': 'sale-1',
    'customer_id': 12,
    'visit_id': null,
    'date': now.toUtc().toIso8601String(),
    'total': '2400.00',
    'status': 'cancelled',
    'is_credit_sale': true,
    'details': const [],
  };

  group('push', () {
    test('sales travel before container movements, in the server order', () {
      expect(
        [for (final p in SyncEngine.defaultPushers(db)) p.wireKey],
        [
          'customers',
          'customer_addresses',
          'customer_preferences',
          'customer_agreements',
          'route_stops',
          'visits',
          'sales',
          'container_movements',
          'payments',
          'sale_cancellations',
          'payment_cancellations',
        ],
      );
    });

    test(
      'both halves of a movement made with a sale reference it by uuid '
      'in the same request; a return without a sale references none',
      () async {
        await sell();
        await returnLoose();

        await engine.push();

        expect(server.pushBodies.single.keys.toList(), [
          'sales',
          'container_movements',
        ]);
        final movements = {
          for (final m in sent('container_movements')) m['uuid']: m,
        };
        for (final uuid in [
          withSale,
          ContainerMovementPusher.returnUuid(withSale),
        ]) {
          expect(movements[uuid]!['sale_uuid'], 'sale-1');
          expect(movements[uuid]!.containsKey('sale_id'), isFalse);
        }
        // A return travels as its return half only.
        final looseReturn =
            movements[ContainerMovementPusher.returnUuid(loose)]!;
        expect(looseReturn.containsKey('sale_uuid'), isFalse);
        expect(looseReturn.containsKey('sale_id'), isFalse);
        expect(await queue.countPending(), 0);
      },
    );

    test('a sale the server already has is referenced by its id', () async {
      await sell();
      // The movements go unanswered the first time.
      server.answer = (entity, r) =>
          entity == 'container_movements' ? null : server.accept(entity, r);
      await engine.push();
      server.answer = null;

      await engine.push();

      expect(server.pushBodies.last.keys.toList(), ['container_movements']);
      for (final m in sent('container_movements')) {
        expect(m['sale_id'], 601);
        expect(m.containsKey('sale_uuid'), isFalse);
      }
    });
  });

  group('cancelling the sale', () {
    test('queues no container movement: the server writes the reversal '
        'itself', () async {
      await sell();
      await returnLoose();
      await engine.push();
      expect(await custody(), 5 + 2 - 1 - 1);

      await cancelSale();

      expect(await custody(), 5 - 1);
      await engine.push();
      expect(server.pushBodies.last.keys.toList(), ['sale_cancellations']);
    });

    test('a download while the cancellation is pending keeps the reversal '
        'in custody', () async {
      await sell();
      await engine.push();
      await cancelSale();

      // The server still counts the sale's containers.
      server.day = _day(today, custody: 5 + 2 - 1);
      await sync.bootstrap();

      expect(await custody(), 5);
    });

    test(
      'a rejected cancellation puts the containers back in custody',
      () async {
        await sell();
        await engine.push();
        await cancelSale();
        expect(await custody(), 5);
        server.answer = (entity, r) => {
          'uuid': r['uuid'],
          'status': 'rejected',
          'server_id': null,
          'review_reason': null,
          'error': 'The cancellation is more than 3 days old.',
        };

        await engine.push();

        expect(await custody(), 5 + 2 - 1);
        final rows = await db.select(db.containerMovementTable).get();
        expect(rows.map((m) => m.containerMovementId), [withSale]);
        // A later download agrees with the server, which kept the sale.
        server.day = _day(today, custody: 5 + 2 - 1);
        await sync.bootstrap();
        expect(await custody(), 5 + 2 - 1);
      },
    );

    test('once accepted, the bootstrap that brings the server reversals '
        'leaves custody at the server value, counted once', () async {
      await sell();
      await returnLoose();
      await engine.push();
      await cancelSale();
      await engine.push();
      expect(await queue.countPending(), 0);

      server.day = _day(
        today,
        custody: 5 - 1,
        sales: [cancelledSale()],
        movements: cancelledDay(),
      );
      await sync.bootstrap();
      // A second bootstrap of the same day changes nothing.
      await sync.bootstrap();

      expect(await custody(), 5 - 1);
      final rows = await db.select(db.containerMovementTable).get();
      final reversals = [
        for (final m in rows)
          if (m.reversesMovementId != null) m,
      ];
      // The device's reversal stands for both of the server's.
      expect(reversals, hasLength(1));
      expect(reversals.single.reversesMovementId, withSale);
      expect(
        (reversals.single.deliveredQuantity, reversals.single.returnedQuantity),
        (-2, -1),
      );
      expect(reversals.single.serverId, isNotNull);
      expect(rows, hasLength(3));
      // The sale's containers net to nothing; the loose return stays.
      expect(rows.fold<int>(0, (sum, m) => sum + m.deliveredQuantity), 0);
      expect(rows.fold<int>(0, (sum, m) => sum + m.returnedQuantity), 1);
      expect(await queue.countPending(), 0);
    });
  });
}
