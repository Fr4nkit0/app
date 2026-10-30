import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show dateOnly;
import 'package:app/features/sync/push/container_movement_pusher.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

Map<String, dynamic> _visit(
  int id,
  String clientUuid,
  int stopId,
  int customerId,
  String date,
) => {
  'id': id,
  'client_uuid': clientUuid,
  'route_stop_id': stopId,
  'customer_id': customerId,
  'driver_id': 1,
  'outcome_id': null,
  'arrived_at': '${date}T13:05:00.000000Z',
  'status': 'CLOSED',
  'notes': null,
};

Map<String, dynamic> _sale(
  int id,
  String clientUuid,
  int customerId,
  int visitId,
  String total,
  String date,
) => {
  'id': id,
  'client_uuid': clientUuid,
  'customer_id': customerId,
  'visit_id': visitId,
  'date': date,
  'total': total,
  'status': 'confirmed',
  'is_credit_sale': false,
  'details': const [],
};

Map<String, dynamic> _payment({
  required int id,
  String? clientUuid,
  int customerId = 12,
  int? visitId = 501,
  int? saleId,
  int methodId = 5,
  required String amount,
  String status = 'CONFIRMED',
  required String date,
}) => {
  'id': id,
  'client_uuid': clientUuid,
  'customer_id': customerId,
  'visit_id': visitId,
  'sale_id': saleId,
  'payment_method_id': methodId,
  'amount': amount,
  'paid_at': '${date}T13:10:00.000000Z',
  'status': status,
  'received_by': 1,
  'transaction_id': null,
  'needs_review': false,
  'review_reason': null,
  'created_at': '${date}T13:10:00.000000Z',
  'updated_at': '${date}T14:00:00.000000Z',
};

Map<String, dynamic> _movement({
  required int id,
  String? clientUuid,
  int customerId = 12,
  int? visitId = 501,
  int? saleId,
  String type = 'DELIVERED',
  required int quantity,
  int direction = 1,
  int? reverses,
  required String date,
}) => {
  'id': id,
  'client_uuid': clientUuid,
  'customer_id': customerId,
  'visit_id': visitId,
  'sale_id': saleId,
  'container_type_id': 1,
  'movement_type': type,
  'quantity': quantity,
  'direction': direction,
  'reverses_movement_id': reverses,
  'created_by': 1,
  'needs_review': false,
  'review_reason': null,
  'created_at': '${date}T13:10:00.000000Z',
  'updated_at': '${date}T13:10:00.000000Z',
};

Map<String, dynamic> _payload(
  String date, {
  List<Map<String, dynamic>> visits = const [],
  List<Map<String, dynamic>> sales = const [],
  List<Map<String, dynamic>> payments = const [],
  List<Map<String, dynamic>> movements = const [],
}) => {
  'data': {
    'route': {'id': 7, 'date': date, 'status': 'IN_PROGRESS'},
    'stops': [
      {'id': 71, 'route_id': 7, 'customer_id': 11, 'status': 'FINISHED'},
      {'id': 72, 'route_id': 7, 'customer_id': 12, 'status': 'FINISHED'},
    ],
    'customers': [
      {
        'id': 11,
        'client_uuid': 'cust-uuid-11',
        'name': 'Ana',
        'balance': {'current_balance': '0.00'},
        'container_balances': [
          {'container_type_id': 1, 'balance': 0},
        ],
      },
      {
        'id': 12,
        'client_uuid': 'cust-uuid-12',
        'name': 'Beto',
        'balance': {'current_balance': '800.00'},
        'container_balances': [
          {'container_type_id': 1, 'balance': 5},
        ],
      },
    ],
    'container_types': [
      {'id': 1, 'code': 'BIDON_20L', 'description': 'Bidón 20L'},
    ],
    'payment_methods': [
      {'id': 5, 'code': 'CASH', 'name': 'Efectivo'},
      {'id': 6, 'code': 'TRANSFER', 'name': 'Transferencia'},
    ],
    'visits': visits,
    'sales': sales,
    'payments': payments,
    'container_movements': movements,
    'server_time': '${date}T12:00:00+00:00',
  },
  'message': null,
};

/// Beto (stop 72) bought by transfer, paid a debt in cash, had a cash
/// payment cancelled and returned containers; Ana (stop 71) paid a sale
/// half cash, half transfer and returned a container that was reversed.
Map<String, dynamic> _day(String date) => _payload(
  date,
  visits: [
    _visit(501, 'visit-uuid-501', 72, 12, date),
    _visit(502, 'visit-uuid-502', 71, 11, date),
  ],
  sales: [
    _sale(601, 'sale-uuid-601', 12, 501, '2700.00', date),
    _sale(602, 'sale-uuid-602', 11, 502, '1000.00', date),
  ],
  payments: [
    _payment(
      id: 701,
      clientUuid: 'pay-uuid-701',
      saleId: 601,
      methodId: 6,
      amount: '2700.00',
      date: date,
    ),
    _payment(
      id: 702,
      clientUuid: 'pay-uuid-702',
      customerId: 11,
      visitId: 502,
      saleId: 602,
      amount: '400.00',
      date: date,
    ),
    _payment(
      id: 703,
      clientUuid: 'pay-uuid-703',
      customerId: 11,
      visitId: 502,
      saleId: 602,
      methodId: 6,
      amount: '600.00',
      date: date,
    ),
    _payment(id: 704, clientUuid: 'pay-uuid-704', amount: '500.00', date: date),
    _payment(
      id: 705,
      clientUuid: 'pay-uuid-705',
      amount: '300.00',
      status: 'CANCELLED',
      date: date,
    ),
  ],
  movements: [
    _movement(
      id: 801,
      clientUuid: 'mov-uuid-801',
      saleId: 601,
      quantity: 2,
      date: date,
    ),
    _movement(
      id: 802,
      clientUuid: 'mov-uuid-802',
      type: 'RETURNED',
      quantity: 3,
      direction: -1,
      date: date,
    ),
    _movement(
      id: 803,
      clientUuid: 'mov-uuid-803',
      customerId: 11,
      visitId: 502,
      type: 'RETURNED',
      quantity: 1,
      direction: -1,
      date: date,
    ),
    // The server's reversal of 803: no client uuid.
    _movement(
      id: 804,
      customerId: 11,
      visitId: 502,
      type: 'RETURNED',
      quantity: 1,
      reverses: 803,
      date: date,
    ),
    // A server-only movement type the app does not model.
    _movement(
      id: 805,
      clientUuid: 'mov-uuid-805',
      type: 'ADJUSTMENT',
      quantity: 4,
      date: date,
    ),
  ],
);

void main() {
  late AppDatabase db;
  late Map<String, dynamic> response;
  final now = DateTime.now();
  final today = dateOnly(now);

  SyncService service() => SyncService(
    Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(200, response),
      ),
    db,
    today: () => now,
  );

  Future<Map<int, RouteStopTableData>> stopsByServerId() async => {
    for (final s in await db.select(db.routeStopTable).get()) s.serverId!: s,
  };

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
    'stores today\'s payments and container movements linked by server '
    'ids, queues nothing and leaves balances and custody as downloaded',
    () async {
      response = _day(today);

      await service().bootstrap();

      final stops = await stopsByServerId();
      final payments = {
        for (final p in await db.select(db.paymentTable).get()) p.serverId: p,
      };
      expect(payments.keys, unorderedEquals([701, 702, 703, 704, 705]));
      final transfer = payments[701]!;
      expect(transfer.paymentId, 'pay-uuid-701');
      expect(transfer.customerId, 'cust-uuid-12');
      expect(transfer.amount, 2700);
      expect(transfer.paymentMethod, 'TRANSFERENCIA');
      expect(transfer.saleId, 'sale-uuid-601');
      // Payments of a visit carry its stop's id, like the sales.
      expect(transfer.visitId, stops[72]!.routeStopId);
      expect(transfer.status, 'CONFIRMED');
      expect(
        transfer.createdAt,
        DateTime.utc(_y(today), _m(today), _d(today), 13, 10).toLocal(),
      );
      expect(payments[702]!.paymentMethod, 'EFECTIVO');
      expect(payments[702]!.visitId, stops[71]!.routeStopId);
      final debt = payments[704]!;
      expect(debt.saleId, isNull);
      expect(debt.amount, 500);
      expect(
        [
          for (final e in await (db.select(
            db.customerAccountEntryTable,
          )..where((t) => t.paymentId.equals('pay-uuid-704'))).get())
            (e.entryType, e.amount, e.direction),
        ],
        [('PAYMENT', 500.0, -1)],
      );

      final movements = {
        for (final m in await db.select(db.containerMovementTable).get())
          m.serverId: m,
      };
      // The server-only movement type is skipped.
      expect(movements.keys, unorderedEquals([801, 802, 803, 804]));
      final delivered = movements[801]!;
      expect(delivered.containerMovementId, 'mov-uuid-801');
      expect(delivered.customerId, 'cust-uuid-12');
      expect(delivered.containerType, 'BIDON_20L');
      expect(delivered.deliveredQuantity, 2);
      expect(delivered.returnedQuantity, 0);
      expect(delivered.saleId, 'sale-uuid-601');
      expect(delivered.visitId, stops[72]!.routeStopId);
      expect(delivered.routeId, stops[72]!.routeId);
      expect(delivered.reversesMovementId, isNull);
      final returned = movements[802]!;
      expect(returned.deliveredQuantity, 0);
      expect(returned.returnedQuantity, 3);
      expect(returned.saleId, isNull);
      // A reversal is its own movement that takes the original back out.
      final reversal = movements[804]!;
      expect(reversal.reversesMovementId, 'mov-uuid-803');
      expect(reversal.customerId, 'cust-uuid-11');
      expect(reversal.deliveredQuantity, 0);
      expect(reversal.returnedQuantity, -1);

      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
      final balances = {
        for (final b in await db.select(db.customerBalanceTable).get())
          b.customerId: b.currentBalance,
      };
      expect(balances, {'cust-uuid-11': 0, 'cust-uuid-12': 800});
      final custody = {
        for (final c in await db.select(db.customerContainerBalanceTable).get())
          c.customerId: c.quantity,
      };
      expect(custody, {'cust-uuid-11': 0, 'cust-uuid-12': 5});

      // A second bootstrap of the same day duplicates nothing.
      await service().bootstrap();
      expect(await db.select(db.paymentTable).get(), hasLength(5));
      expect(await db.select(db.containerMovementTable).get(), hasLength(4));
      expect(
        await db.select(db.customerAccountEntryTable).get(),
        hasLength(_ledgerLines),
      );
    },
  );

  test(
    'a cancelled payment is stored as cancelled, with its adjustment',
    () async {
      response = _day(today);

      await service().bootstrap();

      final cancelled = await (db.select(
        db.paymentTable,
      )..where((t) => t.serverId.equals(705))).getSingle();
      expect(cancelled.paymentId, 'pay-uuid-705');
      expect(cancelled.status, 'CANCELLED');
      expect(
        cancelled.cancelledAt,
        DateTime.utc(_y(today), _m(today), _d(today), 14).toLocal(),
      );
      expect([
        for (final e in await (db.select(
          db.customerAccountEntryTable,
        )..where((t) => t.paymentId.equals('pay-uuid-705'))).get())
          (e.entryType, e.amount, e.direction),
      ], unorderedEquals([('PAYMENT', 300.0, -1), ('ADJUSTMENT', 300.0, 1)]));
    },
  );

  test('a bootstrapped sale takes its method from its payments and the '
      'route shows the collected debt and the returned containers', () async {
    response = _day(today);

    await service().bootstrap();

    final sales = {
      for (final s in await db.select(db.saleTable).get()) s.serverId: s,
    };
    expect(sales[601]!.paymentMethod, PaymentMethod.transfer.name);
    expect(sales[601]!.cashAmount, isNull);
    expect(sales[601]!.transferAmount, isNull);
    expect(sales[602]!.paymentMethod, PaymentMethod.mixed.name);
    expect(sales[602]!.cashAmount, 400);
    expect(sales[602]!.transferAmount, 600);

    final stops = await DriftRouteRepository(db).watchDayStops().first;
    final beto = stops.firstWhere((s) => s.customer.id == 'cust-uuid-12');
    expect(beto.visit?.saleMethods, [PaymentMethod.transfer]);
    expect(beto.visit?.salesTotal, 2700);
    // Only the confirmed debt payment counts.
    expect(beto.visit?.collected, 500);
    expect(beto.visit?.returned, 3);
    final ana = stops.firstWhere((s) => s.customer.id == 'cust-uuid-11');
    expect(ana.visit?.saleMethods, [PaymentMethod.mixed]);
    expect(ana.visit?.collected, 0);
    // The return was reversed on the server.
    expect(ana.visit?.returned, 0);
  });

  test('a sale with no confirmed payment is on credit', () async {
    response = _payload(
      today,
      visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
      sales: [_sale(601, 'sale-uuid-601', 12, 501, '2700.00', today)],
      payments: [
        _payment(
          id: 701,
          clientUuid: 'pay-uuid-701',
          saleId: 601,
          amount: '2700.00',
          status: 'CANCELLED',
          date: today,
        ),
      ],
    );

    await service().bootstrap();

    final sale = await db.select(db.saleTable).getSingle();
    expect(sale.paymentMethod, PaymentMethod.credit.name);
  });

  test(
    'a download without payments keeps the method its sales imply',
    () async {
      response = _payload(
        today,
        visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
        sales: [_sale(601, 'sale-uuid-601', 12, 501, '2700.00', today)],
      );
      (response['data'] as Map).remove('payments');

      await service().bootstrap();

      final sale = await db.select(db.saleTable).getSingle();
      expect(sale.paymentMethod, PaymentMethod.cash.name);
    },
  );

  test('links payments and movements already on the device, keeping unsent '
      'local values and never duplicating', () async {
    response = _payload(today);
    await service().bootstrap();
    final stops = await stopsByServerId();
    final stopId = stops[72]!.routeStopId;
    await db
        .into(db.saleTable)
        .insert(
          SaleTableCompanion.insert(
            saleId: const Value('sale-uuid-601'),
            customerId: 'cust-uuid-12',
            totalAmount: 2700,
            paymentMethod: PaymentMethod.cash.name,
            quantity: 0,
            shipping_amount: 0,
            visitId: Value(stopId),
          ),
        );
    await db
        .into(db.paymentTable)
        .insert(
          PaymentTableCompanion.insert(
            paymentId: const Value('pay-uuid-704'),
            customerId: 'cust-uuid-12',
            amount: 450,
            paymentMethod: 'EFECTIVO',
            visitId: Value(stopId),
          ),
        );
    // One local movement holds both halves the server stores apart.
    await db
        .into(db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            containerMovementId: const Value('mov-uuid-801'),
            customerId: 'cust-uuid-12',
            containerType: 'BIDON_20L',
            deliveredQuantity: 2,
            returnedQuantity: 3,
            visitId: Value(stopId),
          ),
        );
    final queue = DriftPendingChangeRepository(db);
    for (final (entity, id) in [
      (PendingEntity.sale, 'sale-uuid-601'),
      (PendingEntity.payment, 'pay-uuid-704'),
      (PendingEntity.containerMovement, 'mov-uuid-801'),
    ]) {
      await queue.enqueue(
        entity: entity,
        entityId: id,
        action: PendingAction.insert,
      );
    }
    final ledger = await db.select(db.customerAccountEntryTable).get();

    Map<String, dynamic> day({required bool withUuids}) => _payload(
      today,
      visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
      sales: [_sale(601, 'sale-uuid-601', 12, 501, '2700.00', today)],
      payments: [
        _payment(
          id: 701,
          clientUuid: 'pay-uuid-701',
          saleId: 601,
          methodId: 6,
          amount: '2700.00',
          date: today,
        ),
        _payment(
          id: 704,
          clientUuid: withUuids ? 'pay-uuid-704' : null,
          amount: '500.00',
          date: today,
        ),
      ],
      movements: [
        _movement(
          id: 801,
          clientUuid: withUuids ? 'mov-uuid-801' : null,
          saleId: 601,
          quantity: 2,
          date: today,
        ),
        _movement(
          id: 802,
          clientUuid: ContainerMovementPusher.returnUuid('mov-uuid-801'),
          type: 'RETURNED',
          quantity: 3,
          direction: -1,
          date: today,
        ),
      ],
    );
    response = day(withUuids: true);
    await service().bootstrap();
    // Matched by server id the second time.
    response = day(withUuids: false);
    await service().bootstrap();

    final payments = {
      for (final p in await db.select(db.paymentTable).get()) p.paymentId: p,
    };
    expect(payments.keys, unorderedEquals(['pay-uuid-701', 'pay-uuid-704']));
    expect(payments['pay-uuid-704']!.serverId, 704);
    expect(payments['pay-uuid-704']!.amount, 450);
    final movement = await db.select(db.containerMovementTable).getSingle();
    expect(movement.containerMovementId, 'mov-uuid-801');
    expect(movement.serverId, 801);
    expect(movement.deliveredQuantity, 2);
    expect(movement.returnedQuantity, 3);
    expect(movement.saleId, 'sale-uuid-601');
    // A sale made on the device keeps its own method.
    final sale = await db.select(db.saleTable).getSingle();
    expect(sale.paymentMethod, PaymentMethod.cash.name);
    expect((await queue.getPending()).map((c) => c.entityId), [
      'sale-uuid-601',
      'pay-uuid-704',
      'mov-uuid-801',
    ]);
    // Only the payment new to the device adds a ledger line.
    expect(
      (await db.select(db.customerAccountEntryTable).get()).length,
      ledger.length + 1,
    );
    // Custody is the server's plus the unsent movement (2 out, 3 back);
    // the linked movement does not move it again.
    expect(
      (await db.select(db.customerContainerBalanceTable).get()).map(
        (c) => (c.customerId, c.quantity),
      ),
      unorderedEquals([('cust-uuid-11', 0), ('cust-uuid-12', 5 + 2 - 3)]),
    );
  });

  for (final returnFirst in [false, true]) {
    test('a reinstalled device rebuilds both halves of one local movement '
        '(return first: $returnFirst)', () async {
      const x = 'mov-local-x';
      final halves = [
        _movement(id: 801, clientUuid: x, quantity: 2, date: today),
        _movement(
          id: 802,
          clientUuid: ContainerMovementPusher.returnUuid(x),
          type: 'RETURNED',
          quantity: 3,
          direction: -1,
          date: today,
        ),
      ];
      response = _payload(
        today,
        visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
        movements: returnFirst ? halves.reversed.toList() : halves,
      );

      await service().bootstrap();
      await service().bootstrap();

      final rows = await db.select(db.containerMovementTable).get();
      expect(rows.fold<int>(0, (s, m) => s + m.deliveredQuantity), 2);
      expect(rows.fold<int>(0, (s, m) => s + m.returnedQuantity), 3);
      // The row keeps its delivery's server id.
      expect(rows.firstWhere((m) => m.containerMovementId == x).serverId, 801);
      final stops = await DriftRouteRepository(db).watchDayStops().first;
      expect(
        stops
            .firstWhere((s) => s.customer.id == 'cust-uuid-12')
            .visit
            ?.returned,
        3,
      );
      expect(await db.select(db.pendingChangeTable).get(), isEmpty);
    });
  }

  test(
    'both reversals of a rebuilt movement take back each half once',
    () async {
      const x = 'mov-local-x';
      response = _payload(
        today,
        visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
        movements: [
          _movement(id: 801, clientUuid: x, quantity: 2, date: today),
          _movement(
            id: 802,
            clientUuid: ContainerMovementPusher.returnUuid(x),
            type: 'RETURNED',
            quantity: 3,
            direction: -1,
            date: today,
          ),
          // The server reverses each half with the opposite type.
          _movement(
            id: 803,
            type: 'RETURNED',
            quantity: 2,
            direction: -1,
            reverses: 801,
            date: today,
          ),
          _movement(id: 804, quantity: 3, reverses: 802, date: today),
        ],
      );

      await service().bootstrap();
      await service().bootstrap();

      final rows = {
        for (final m in await db.select(db.containerMovementTable).get())
          m.serverId: (
            m.containerMovementId,
            m.deliveredQuantity,
            m.returnedQuantity,
            m.reversesMovementId,
          ),
      };
      // The RETURNED reversal is never merged into its original as a return.
      expect(rows.keys, unorderedEquals([801, 803, 804]));
      expect(rows[801], (x, 2, 3, null));
      expect((rows[803]!.$2, rows[803]!.$3, rows[803]!.$4), (-2, 0, x));
      expect((rows[804]!.$2, rows[804]!.$3, rows[804]!.$4), (0, -3, x));
      final stops = await DriftRouteRepository(db).watchDayStops().first;
      expect(
        stops
            .firstWhere((s) => s.customer.id == 'cust-uuid-12')
            .visit
            ?.returned,
        0,
      );
    },
  );

  test('a movement the device recorded and already sent keeps its halves '
      'when the bootstrap brings both', () async {
    response = _payload(today);
    await service().bootstrap();
    final stopId = (await stopsByServerId())[72]!.routeStopId;
    const x = 'mov-local-x';
    // Sent before: no pending change, no server id recorded yet.
    await db
        .into(db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            containerMovementId: const Value(x),
            customerId: 'cust-uuid-12',
            containerType: 'BIDON_20L',
            deliveredQuantity: 2,
            returnedQuantity: 3,
            visitId: Value(stopId),
          ),
        );
    response = _payload(
      today,
      visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
      movements: [
        _movement(
          id: 802,
          clientUuid: ContainerMovementPusher.returnUuid(x),
          type: 'RETURNED',
          quantity: 3,
          direction: -1,
          date: today,
        ),
        _movement(id: 801, clientUuid: x, quantity: 2, date: today),
      ],
    );

    await service().bootstrap();
    await service().bootstrap();

    final movement = await db.select(db.containerMovementTable).getSingle();
    expect(
      (
        movement.containerMovementId,
        movement.serverId,
        movement.deliveredQuantity,
        movement.returnedQuantity,
      ),
      (x, 801, 2, 3),
    );
    expect(await db.select(db.pendingChangeTable).get(), isEmpty);
  });

  test('a movement with an unsent change keeps its local quantities', () async {
    response = _payload(today);
    await service().bootstrap();
    final stopId = (await stopsByServerId())[72]!.routeStopId;
    const x = 'mov-local-x';
    // Recorded as a delivery only; its return half is not on the device.
    await db
        .into(db.containerMovementTable)
        .insert(
          ContainerMovementTableCompanion.insert(
            containerMovementId: const Value(x),
            customerId: 'cust-uuid-12',
            containerType: 'BIDON_20L',
            deliveredQuantity: 2,
            returnedQuantity: 0,
            visitId: Value(stopId),
          ),
        );
    await DriftPendingChangeRepository(db).enqueue(
      entity: PendingEntity.containerMovement,
      entityId: x,
      action: PendingAction.update,
    );
    response = _payload(
      today,
      visits: [_visit(501, 'visit-uuid-501', 72, 12, today)],
      movements: [
        _movement(id: 801, clientUuid: x, quantity: 2, date: today),
        _movement(
          id: 802,
          clientUuid: ContainerMovementPusher.returnUuid(x),
          type: 'RETURNED',
          quantity: 3,
          direction: -1,
          date: today,
        ),
      ],
    );

    await service().bootstrap();

    final movement = await db.select(db.containerMovementTable).getSingle();
    expect(
      (
        movement.serverId,
        movement.deliveredQuantity,
        movement.returnedQuantity,
      ),
      (801, 2, 0),
    );
  });
}

/// Two sale lines, five payment lines and one adjustment.
const _ledgerLines = 2 + 5 + 1;

int _y(String date) => int.parse(date.substring(0, 4));
int _m(String date) => int.parse(date.substring(5, 7));
int _d(String date) => int.parse(date.substring(8, 10));
