import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.neighborhood.repository.dart';
import 'package:app/features/customers/domain/models/salta_neighborhoods.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> _bootstrap(List<Map<String, dynamic>> neighborhoods) => {
  'data': {
    'route': null,
    'customers': [],
    'products': [],
    'neighborhoods': neighborhoods,
    'server_time': '2026-10-29T12:00:00+00:00',
  },
  'message': null,
};

Map<String, dynamic> _pullPage(List<Map<String, dynamic>> neighborhoods) => {
  'data': {'neighborhoods': neighborhoods},
  'meta': {
    'page': 1,
    'per_page': 200,
    'is_last_page': true,
    'until': '2026-10-29T13:00:00+00:00',
    'cursor': '2026-10-29T12:59:55+00:00',
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
    bootstrap = _bootstrap(const []);
    pullPage = _pullPage(const []);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (options) => FakeHttpAdapter.json(
          200,
          options.path == '/sync/bootstrap' ? bootstrap : pullPage,
        ),
      );
    service = SyncService(dio, db);
  });
  tearDown(() => db.close());

  Future<List<String>> pickerNames() =>
      DriftNeighborhoodRepository(db).watchNames().first;

  test('the picker lists the bundled Salta neighborhoods until a sync stores the catalog', () async {
    expect(await pickerNames(), saltaNeighborhoods);
  });

  test('the bootstrap stores the enabled catalog by server id, ordered by name', () async {
    bootstrap = _bootstrap([
      {'id': 2, 'name': 'Tres Cerritos', 'enabled': true, 'updated_at': '2026-10-29T10:00:00+00:00'},
      {'id': 1, 'name': 'Centro', 'enabled': true, 'updated_at': '2026-10-29T10:00:00+00:00'},
      {'id': 3, 'name': 'castañares', 'enabled': true, 'updated_at': '2026-10-29T10:00:00+00:00'},
    ]);

    await service.bootstrap();
    await service.bootstrap();

    expect(await pickerNames(), ['castañares', 'Centro', 'Tres Cerritos']);
    final stored = await db.select(db.neighborhoodTable).get();
    expect(stored.map((n) => (n.id, n.name, n.enabled)).toSet(), {
      (1, 'Centro', true),
      (2, 'Tres Cerritos', true),
      (3, 'castañares', true),
    });
  });

  test('a later bootstrap hides stored neighborhoods it no longer lists', () async {
    bootstrap = _bootstrap([
      {'id': 1, 'name': 'Centro', 'enabled': true},
      {'id': 2, 'name': 'Tres Cerritos', 'enabled': true},
    ]);
    await service.bootstrap();

    bootstrap = _bootstrap([
      {'id': 1, 'name': 'Centro', 'enabled': true},
    ]);
    await service.bootstrap();

    expect(await pickerNames(), ['Centro']);
    expect((await db.select(db.neighborhoodTable).get()).length, 2);
  });

  test('a pull renames a neighborhood, hides a disabled one and adds a new one', () async {
    bootstrap = _bootstrap([
      {'id': 1, 'name': 'Centro', 'enabled': true},
      {'id': 2, 'name': 'Tres Cerritos', 'enabled': true},
    ]);
    await service.bootstrap();
    pullPage = _pullPage([
      {'id': 1, 'name': 'Centro Histórico', 'enabled': true, 'created_at': '2026-01-01T00:00:00+00:00', 'updated_at': '2026-10-29T12:30:00+00:00'},
      {'id': 2, 'name': 'Tres Cerritos', 'enabled': false, 'created_at': '2026-01-01T00:00:00+00:00', 'updated_at': '2026-10-29T12:30:00+00:00'},
      {'id': 4, 'name': 'Limache', 'enabled': true, 'created_at': '2026-10-29T12:30:00+00:00', 'updated_at': '2026-10-29T12:30:00+00:00'},
    ]);

    await service.pull();

    expect(await pickerNames(), ['Centro Histórico', 'Limache']);
    final stored = await db.select(db.neighborhoodTable).get();
    expect(stored.length, 3);
    expect(stored.firstWhere((n) => n.id == 2).enabled, isFalse);
  });

  test('a pull without neighborhoods keeps the stored catalog', () async {
    bootstrap = _bootstrap([
      {'id': 1, 'name': 'Centro', 'enabled': true},
    ]);
    await service.bootstrap();

    await service.pull();

    expect(await pickerNames(), ['Centro']);
  });
}
