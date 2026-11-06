import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _route() => {
  'id': 8,
  'date': _today(),
  'status': 'IN_PROGRESS',
  'enabled': true,
  'dispatched_at': '2026-10-19T11:00:00+00:00',
  'dispatched_by': 3,
};

Map<String, dynamic> _stop() => {
  'id': 81,
  'route_id': 8,
  'customer_id': 11,
  'address_id': 111,
  'scheduled_time': '09:30:00',
  'is_rescheduled_from': null,
  'status': 'PENDING',
  'enabled': true,
};

Map<String, dynamic> _load() => {
  'id': 901,
  'route_id': 8,
  'product_id': 21,
  'current_quantity': '20.00',
  'enabled': true,
};

/// The bootstrap of a driver whose route was not dispatched yet carries no
/// route, stops or truck inventory; [dispatched] adds them.
Map<String, dynamic> _bootstrap({required bool dispatched}) => {
  'data': {
    'route': dispatched ? _route() : null,
    'stops': dispatched ? [_stop()] : [],
    'truck_inventory': dispatched ? [_load()] : [],
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
          },
        ],
        'preferences': [],
        'agreements': [],
        'balance': {'current_balance': '0.00'},
        'container_balances': [],
      },
    ],
    'products': [
      {'id': 21, 'name': 'Water 20L'},
    ],
    'container_types': [],
    'payment_methods': [],
    'visit_outcomes': [],
    'server_time': '2026-10-19T08:00:00+00:00',
  },
  'message': null,
};

Map<String, dynamic> _dispatchPage() => {
  'data': {
    'routes': [_route()],
    'route_stops': [_stop()],
    'route_inventories': [_load()],
  },
  'meta': {
    'page': 1,
    'per_page': 200,
    'is_last_page': true,
    'until': '2026-10-19T11:05:00+00:00',
    'cursor': '2026-10-19T11:04:55+00:00',
  },
  'message': null,
};

void main() {
  late AppDatabase db;
  late SyncService service;
  late bool dispatched;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dispatched = false;
    final adapter = FakeHttpAdapter((options) {
      if (options.path == '/sync/bootstrap') {
        return FakeHttpAdapter.json(200, _bootstrap(dispatched: dispatched));
      }
      return FakeHttpAdapter.json(200, _dispatchPage());
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    service = SyncService(dio, db);
    await service.bootstrap();
  });
  tearDown(() => db.close());

  Future<void> expectTodaysRouteBuilt() async {
    final stops = await DriftRouteRepository(db).watchDayStops().first;
    expect(stops, hasLength(1));
    expect(stops.single.customer.name, 'Ana');

    final routes = await db.select(db.routeTable).get();
    expect(routes, hasLength(1));
    expect(routes.single.serverId, 8);

    final loads = await db.select(db.routeInventoryLoadTable).get();
    expect(loads, hasLength(1));
    expect(loads.single.routeId, routes.single.routeId);
    expect(loads.single.quantity, 20);
  }

  test(
    'a bootstrap before dispatch stores no route and keeps asking for one',
    () async {
      expect(await db.select(db.routeTable).get(), isEmpty);
      expect(await db.select(db.routeStopTable).get(), isEmpty);
      expect(await db.select(db.routeInventoryLoadTable).get(), isEmpty);
      expect(await DriftRouteRepository(db).watchDayStops().first, isEmpty);
      expect(await service.needsBootstrap(), isTrue);
    },
  );

  test('the next bootstrap after dispatch builds today\'s route', () async {
    dispatched = true;

    await service.bootstrap();

    await expectTodaysRouteBuilt();
    expect(await service.needsBootstrap(), isFalse);
  });

  test('an incremental pull with a newly dispatched route builds today\'s '
      'route with no route stored before', () async {
    await service.pull();

    await expectTodaysRouteBuilt();
  });
}
