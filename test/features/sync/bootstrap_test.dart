import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

Map<String, dynamic> _payload({String date = '2026-10-19'}) => {
  'data': {
    'route': {'id': 7, 'date': date, 'status': 'IN_PROGRESS'},
    'stops': [
      {
        'id': 71,
        'route_id': 7,
        'customer_id': 11,
        'address_id': 111,
        'scheduled_time': '09:30:00',
        'is_rescheduled_from': null,
        'status': 'PENDING',
      },
      {
        'id': 72,
        'route_id': 7,
        'customer_id': 12,
        'address_id': null,
        'scheduled_time': null,
        'is_rescheduled_from': 71,
        'status': 'FINISHED',
      },
    ],
    'truck_inventory': [
      {'id': 900, 'route_id': 7, 'product_id': 21, 'current_quantity': '20.00'},
    ],
    'customers': [
      {
        'id': 11,
        'client_uuid': 'cust-uuid-11',
        'name': 'Ana',
        'phone_number': '111',
        'addresses': [
          {
            'id': 111,
            'customer_id': 11,
            'street': 'Belgrano 340',
            'is_primary': true,
            'neighborhood': 'Centro',
            'latitude': '-24.18',
            'longitude': -65.3,
          },
        ],
        'preferences': [
          {
            'id': 1100,
            'day_of_week': 1,
            'time_window_start': '08:00:00',
            'time_window_end': '12:00:00',
          },
        ],
        'agreements': [
          {
            'id': 1200,
            'product_id': 21,
            'unit_price': '1350.00',
            'valid_from': '2026-10-01',
            'valid_to': null,
            'reason': 'Bulk',
          },
        ],
        'balance': {'current_balance': '1500.50'},
        'container_balances': [
          {'id': 1300, 'container_type_id': 1, 'balance': 3},
        ],
      },
      {'id': 12, 'client_uuid': 'cust-uuid-12', 'name': 'Beto', 'phone_number': null},
    ],
    'products': [
      {'id': 21, 'name': 'Water 20L', 'requires_container': true, 'container_type_id': 1},
      {'id': 22, 'name': 'Soda 2L', 'requires_container': false},
    ],
    'container_types': [
      {'id': 1, 'code': 'BIDON_20L', 'description': '20L'},
    ],
    'payment_methods': [
      {'id': 5, 'code': 'CASH', 'name': 'Cash'},
    ],
    'visit_outcomes': [
      {'id': 3, 'name': 'Absent', 'triggers_reschedule': true},
    ],
    'server_time': '2026-10-19T12:00:00+00:00',
  },
  'message': null,
};

void main() {
  late AppDatabase db;
  late SyncService service;
  late Map<String, dynamic> response;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    response = _payload();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(200, response),
      );
    service = SyncService(dio, db, today: () => DateTime(2026, 10, 19));
  });
  tearDown(() => db.close());

  test('stores the full day identified by server ids', () async {
    await service.bootstrap();

    final stops = await (db.select(db.routeStopTable)
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .get();
    expect(stops.map((s) => s.serverId), [71, 72]);
    expect(stops.map((s) => s.sequence), [1, 2]);
    expect(stops.map((s) => s.scheduledTime), ['09:30:00', null]);
    expect(stops[1].rescheduledFromStopId, stops[0].routeStopId);
    expect(stops.map((s) => s.status), ['pending', 'done']);

    final route = await db.select(db.routeTable).getSingle();
    expect(route.route_date, '2026-10-19');
    expect(route.status, 'IN_PROGRESS');

    final ana = await (db.select(db.customerTable)
          ..where((t) => t.serverId.equals(11)))
        .getSingle();
    expect(ana.customerId, 'cust-uuid-11');
    expect(stops[0].customerId, ana.customerId);
    expect(stops[0].customerAddressId, isNotNull);

    final address = await db.select(db.customerAddressTable).getSingle();
    expect(address.street, 'Belgrano 340');
    expect(address.latitude, -24.18);
    final preference = await db.select(db.customerPreferenceTable).getSingle();
    expect(preference.dayOfWeek, 1);
    expect(preference.timeWindowStart, '08:00:00');

    final agreement = await db.select(db.customerAgreementTable).getSingle();
    expect(agreement.unitPrice, 1350.0);
    expect(agreement.serverId, 1200);

    final balance = await db.select(db.customerBalanceTable).getSingle();
    expect(balance.currentBalance, 1500.5);
    final containers = await db.select(db.customerContainerBalanceTable).getSingle();
    expect(containers.containerType, 'BIDON_20L');
    expect(containers.quantity, 3);

    expect((await db.select(db.containerTypeTable).getSingle()).id, 1);
    expect((await db.select(db.paymentMethodTable).getSingle()).id, 5);
    final outcome = await db.select(db.visitOutcomeTable).getSingle();
    expect(outcome.id, 3);
    expect(outcome.triggersReschedule, isTrue);

    final products = await db.select(db.productTable).get();
    final water = products.firstWhere((p) => p.serverId == 21);
    expect(water.stock, 20);
    expect(products.firstWhere((p) => p.serverId == 22).stock, 0);
    final load = await db.select(db.routeInventoryLoadTable).getSingle();
    expect(load.productId, water.productId);
    expect(load.quantity, 20);

    final cursor = await (db.select(db.syncStateTable)
          ..where((t) => t.key.equals('pull_cursor')))
        .getSingle();
    expect(cursor.value, '2026-10-19T12:00:00+00:00');
  });

  test('running twice does not duplicate rows', () async {
    await service.bootstrap();
    await service.bootstrap();

    expect((await db.select(db.customerTable).get()).length, 2);
    expect((await db.select(db.routeStopTable).get()).length, 2);
    expect((await db.select(db.customerAgreementTable).get()).length, 1);
    expect((await db.select(db.routeInventoryLoadTable).get()).length, 1);
    expect((await db.select(db.productTable).get()).length, 2);
  });

  test('keeps pending and rejected changes untouched', () async {
    final queue = DriftPendingChangeRepository(db);
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: 'cust-1',
      action: PendingAction.insert,
    );
    final rejected = (await queue.getPending()).last;
    await queue.markRejected(rejected.id, 'invalid');

    await service.bootstrap();

    expect((await queue.getPending()).map((c) => c.entityId), ['sale-1']);
    expect((await queue.getRejected()).map((c) => c.entityId), ['cust-1']);
  });

  test('needs a bootstrap until a route for today is stored', () async {
    expect(await service.needsBootstrap(), isTrue);

    await service.bootstrap();
    expect(await service.needsBootstrap(), isFalse);

    final tomorrow = SyncService(
      Dio(),
      db,
      today: () => DateTime(2026, 10, 20),
    );
    expect(await tomorrow.needsBootstrap(), isTrue);
  });

  test('a response without a route keeps local stops', () async {
    await service.bootstrap();
    response = {
      'data': {..._payload()['data'] as Map<String, dynamic>, 'route': null, 'stops': []},
    };

    await service.bootstrap();

    expect((await db.select(db.routeStopTable).get()).length, 2);
  });

  test('does not overwrite rows that have unsent local changes', () async {
    await service.bootstrap();
    final queue = DriftPendingChangeRepository(db);

    await (db.update(db.customerTable)
          ..where((t) => t.customerId.equals('cust-uuid-11')))
        .write(const CustomerTableCompanion(name: Value('Ana (edited)')));
    await queue.enqueue(
      entity: PendingEntity.customer,
      entityId: 'cust-uuid-11',
      action: PendingAction.update,
    );

    final stop = await (db.select(db.routeStopTable)
          ..where((t) => t.serverId.equals(71)))
        .getSingle();
    await (db.update(db.routeStopTable)
          ..where((t) => t.routeStopId.equals(stop.routeStopId)))
        .write(const RouteStopTableCompanion(status: Value('done')));
    await db.into(db.visitTable).insert(
          VisitTableCompanion.insert(
            visitId: const Value('visit-1'),
            routeStopId: stop.routeStopId,
            customerId: stop.customerId,
            visitType: 'visit',
            arrived_at: DateTime(2026, 10, 19, 10),
          ),
        );
    await queue.enqueue(
      entity: PendingEntity.visit,
      entityId: 'visit-1',
      action: PendingAction.insert,
    );

    await service.bootstrap();

    final ana = await (db.select(db.customerTable)
          ..where((t) => t.customerId.equals('cust-uuid-11')))
        .getSingle();
    expect(ana.name, 'Ana (edited)');
    final after = await (db.select(db.routeStopTable)
          ..where((t) => t.routeStopId.equals(stop.routeStopId)))
        .getSingle();
    expect(after.status, 'done');
    final beto = await (db.select(db.customerTable)
          ..where((t) => t.customerId.equals('cust-uuid-12')))
        .getSingle();
    expect(beto.name, 'Beto');
  });
}
