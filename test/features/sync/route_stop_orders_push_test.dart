import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

typedef Json = Map<String, dynamic>;

/// Accepts every record unless [answer] says otherwise; a route order is
/// accepted with the route's server id.
class _FakeServer {
  final List<Json> pushBodies = [];
  Json? Function(String entity, Json record)? answer;
  bool silent = false;
  int _nextId = 900;

  Future<ResponseBody> handle(RequestOptions options) async {
    final body = Map<String, dynamic>.from(options.data as Map);
    pushBodies.add(body);
    if (silent) {
      return FakeHttpAdapter.json(200, {'data': <String, dynamic>{}});
    }
    return FakeHttpAdapter.json(200, {
      'data': {
        for (final entity in ['route_stops', 'route_stop_orders'])
          entity: [
            for (final r in (body[entity] as List? ?? const []))
              answer?.call(entity, Map<String, dynamic>.from(r as Map)) ??
                  {
                    'uuid': (r as Map)['uuid'],
                    'status': 'accepted',
                    'server_id': entity == 'route_stop_orders'
                        ? r['route_id']
                        : ++_nextId,
                  },
          ],
      },
      'message': null,
    });
  }
}

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;
  late DriftRouteRepository routes;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    engine = SyncEngine(dio: dio, db: db, sync: SyncService(dio, db));
    routes = DriftRouteRepository(db);

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
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('r-1'),
            route_date: _today(),
            serverId: const drift.Value(7),
          ),
        );
    for (final (id, serverId, sequence) in [
      ('s-1', 70, 1),
      ('s-2', 71, 2),
      ('s-3', 72, 3),
    ]) {
      await db
          .into(db.routeStopTable)
          .insert(
            RouteStopTableCompanion.insert(
              routeStopId: drift.Value(id),
              routeId: 'r-1',
              customerId: 'c-1',
              sequence: sequence,
              position: drift.Value(sequence),
              scheduledAt: DateTime.now(),
              serverId: drift.Value(serverId),
            ),
          );
    }
  });

  tearDown(() => db.close());

  Future<List<PendingChangeTableData>> orderChanges() =>
      (db.select(db.pendingChangeTable)..where(
            (t) => t.entity.equals(PendingEntity.routeStopOrder.wireName),
          ))
          .get();

  test('sends only the latest reorder of a route, with server ids and the '
      'uuid of a stop the server does not know yet', () async {
    // A reschedule the server has not received: it travels by uuid.
    final rescheduled = await routes.rescheduleStop(
      's-3',
      DateTime.now().add(const Duration(minutes: 1)),
    );
    await routes.reorderDayStops(['s-2', 's-1', rescheduled]);
    await routes.reorderDayStops([rescheduled, 's-2', 's-1']);
    final latestUuid = (await orderChanges()).last.payload;

    await engine.push();

    final orders = server.pushBodies.single['route_stop_orders'] as List;
    expect(orders, hasLength(1));
    final order = orders.single as Map;
    expect(latestUuid, contains(order['uuid'] as String));
    expect(order['route_id'], 7);
    expect(order['stops'], [
      {'uuid': rescheduled},
      {'id': 71},
      {'id': 70},
      // Listed after the driver's ones: it is not on screen any more.
      {'id': 72},
    ]);
    expect((await orderChanges()).map((c) => c.status), ['sent', 'sent']);
  });

  test(
    'a reorder the server did not answer is resent with the same uuid',
    () async {
      await routes.reorderDayStops(['s-3', 's-1', 's-2']);

      server.silent = true;
      await engine.push();
      expect((await orderChanges()).single.status, 'pending');

      server.silent = false;
      await engine.push();

      final first = (server.pushBodies[0]['route_stop_orders'] as List).single;
      final second = (server.pushBodies[1]['route_stop_orders'] as List).single;
      expect((second as Map)['uuid'], (first as Map)['uuid']);
      expect((await orderChanges()).single.status, 'sent');
    },
  );

  test('a rejected reorder keeps the server reason', () async {
    await routes.reorderDayStops(['s-3', 's-1', 's-2']);
    server.answer = (entity, record) => entity == 'route_stop_orders'
        ? {
            'uuid': record['uuid'],
            'status': 'rejected',
            'error': 'La ruta no es la de hoy.',
          }
        : null;

    await engine.push();

    final change = (await orderChanges()).single;
    expect(change.status, 'rejected');
    expect(change.rejectionReason, 'La ruta no es la de hoy.');
  });

  test(
    'sends whether the order also applies to the coming same weekdays',
    () async {
      await routes.reorderDayStops([
        's-3',
        's-1',
        's-2',
      ], applyToTemplate: true);

      await engine.push();

      final order =
          (server.pushBodies.single['route_stop_orders'] as List).single as Map;
      expect(order['apply_to_template'], true);
    },
  );

  test(
    'an order for today only is sent with apply_to_template false',
    () async {
      await routes.reorderDayStops(['s-3', 's-1', 's-2']);

      await engine.push();

      final order =
          (server.pushBodies.single['route_stop_orders'] as List).single as Map;
      expect(order['apply_to_template'], false);
    },
  );

  test('a later today-only reorder does not drop an unsent one for the '
      'coming weekdays: both travel, in order', () async {
    await routes.reorderDayStops(['s-2', 's-1', 's-3']);
    await routes.reorderDayStops(['s-3', 's-1', 's-2'], applyToTemplate: true);
    await routes.reorderDayStops(['s-1', 's-3', 's-2']);

    await engine.push();

    final orders = [
      for (final o in server.pushBodies.single['route_stop_orders'] as List)
        o as Map,
    ];
    expect(orders.map((o) => o['apply_to_template']), [true, false]);
    expect(orders.map((o) => o['stops']), [
      [
        {'id': 72},
        {'id': 70},
        {'id': 71},
      ],
      [
        {'id': 70},
        {'id': 72},
        {'id': 71},
      ],
    ]);
    expect((await orderChanges()).map((c) => c.status), [
      'sent',
      'sent',
      'sent',
    ]);
  });
}
