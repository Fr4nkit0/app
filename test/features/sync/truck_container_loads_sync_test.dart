import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

const _today = '2026-11-25';

Map<String, dynamic> _route() => {
  'id': 8,
  'date': _today,
  'status': 'IN_PROGRESS',
  'enabled': true,
};

Map<String, dynamic> _load({
  int id = 501,
  int routeId = 8,
  int containerTypeId = 9,
  int quantity = 6,
  String type = 'load',
  String? reason,
  String loadedAt = '2026-11-25T10:00:00+00:00',
}) => {
  'id': id,
  'route_id': routeId,
  'container_type_id': containerTypeId,
  'quantity': quantity,
  'type': type,
  'reason': reason,
  'loaded_at': loadedAt,
  'created_by': 3,
  'created_at': loadedAt,
  'updated_at': loadedAt,
};

Map<String, dynamic> _bootstrap({
  bool withRoute = true,
  List<Map<String, dynamic>>? loads,
}) => {
  'data': {
    'route': withRoute ? _route() : null,
    'stops': [],
    'truck_inventory': [],
    'truck_container_loads': loads ?? (withRoute ? [_load()] : []),
    'customers': [],
    'products': [],
    'container_types': [
      {'id': 1, 'code': 'BIDON_20L', 'description': '20L'},
      {'id': 9, 'code': 'ESQUELETO', 'description': 'Esqueleto'},
    ],
    'payment_methods': [],
    'visit_outcomes': [],
    'server_time': '2026-11-25T08:00:00+00:00',
  },
  'message': null,
};

Map<String, dynamic> _pullPage(List<Map<String, dynamic>> loads) => {
  'data': {
    'routes': [_route()],
    'route_container_loads': loads,
  },
  'meta': {
    'page': 1,
    'per_page': 200,
    'is_last_page': true,
    'until': '2026-11-25T11:05:00+00:00',
    'cursor': '2026-11-25T11:04:55+00:00',
  },
  'message': null,
};

void main() {
  late AppDatabase db;
  late SyncService service;
  late Map<String, dynamic> bootstrap;
  late Map<String, dynamic> pullPage;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    bootstrap = _bootstrap();
    pullPage = _pullPage(const []);
    final adapter = FakeHttpAdapter((options) {
      if (options.path == '/sync/bootstrap') {
        return FakeHttpAdapter.json(200, bootstrap);
      }
      return FakeHttpAdapter.json(200, pullPage);
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter;
    service = SyncService(dio, db, today: () => DateTime(2026, 11, 25, 9));
  });
  tearDown(() => db.close());

  Future<List<RouteContainerLoadTableData>> loads() => (db.select(
    db.routeContainerLoadTable,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();

  Future<String> routeId() async =>
      (await db.select(db.routeTable).getSingle()).routeId;

  group('bootstrap', () {
    test('stores the truck container loads of the route with the type '
        'code', () async {
      bootstrap = _bootstrap(
        loads: [
          _load(),
          _load(
            id: 502,
            quantity: -1,
            type: 'correction',
            reason: 'Contado mal',
            loadedAt: '2026-11-25T11:30:00+00:00',
          ),
        ],
      );

      await service.bootstrap();

      final rows = await loads();
      expect(
        rows.map((l) => (l.id, l.containerType, l.quantity, l.type, l.reason)),
        [
          (501, 'ESQUELETO', 6, 'load', null),
          (502, 'ESQUELETO', -1, 'correction', 'Contado mal'),
        ],
      );
      expect(rows.map((l) => l.routeId).toSet(), {await routeId()});
      expect(
        rows.first.loadedAt,
        DateTime.parse('2026-11-25T10:00:00+00:00').toLocal(),
      );
    });

    test('running twice keeps one row per server id', () async {
      await service.bootstrap();
      await service.bootstrap();

      expect((await loads()).map((l) => l.id), [501]);
    });

    test('a repeated row in the same download is stored once', () async {
      bootstrap = _bootstrap(loads: [_load(), _load(quantity: 7)]);

      await service.bootstrap();

      expect((await loads()).map((l) => (l.id, l.quantity)), [(501, 7)]);
    });

    test('without a route there are no loads', () async {
      bootstrap = _bootstrap(withRoute: false);

      await service.bootstrap();

      expect(await loads(), isEmpty);
    });

    test('a load of a container type missing from the catalog is '
        'skipped', () async {
      bootstrap = _bootstrap(loads: [_load(containerTypeId: 99)]);

      await service.bootstrap();

      expect(await loads(), isEmpty);
    });
  });

  group('pull', () {
    test('stores new loads and updates a repeated one by server id', () async {
      await service.bootstrap();
      pullPage = _pullPage([
        _load(quantity: 8),
        _load(id: 503, containerTypeId: 1, quantity: 2),
        _load(id: 503, containerTypeId: 1, quantity: 2),
      ]);

      await service.pull();

      final rows = await loads();
      expect(rows.map((l) => (l.id, l.containerType, l.quantity)), [
        (501, 'ESQUELETO', 8),
        (503, 'BIDON_20L', 2),
      ]);
      expect(rows.map((l) => l.routeId).toSet(), {await routeId()});
    });

    test('a pull repeating the same window does not duplicate', () async {
      await service.bootstrap();
      pullPage = _pullPage([_load(id: 504, quantity: 3)]);

      await service.pull();
      await service.pull();

      expect((await loads()).map((l) => (l.id, l.quantity)), [
        (501, 6),
        (504, 3),
      ]);
    });

    test('a load of an unknown route is skipped', () async {
      await service.bootstrap();
      pullPage = _pullPage([_load(id: 505, routeId: 77)]);

      await service.pull();

      expect((await loads()).map((l) => l.id), [501]);
    });
  });
}
