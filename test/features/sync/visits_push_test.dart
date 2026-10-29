import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/data/repositories/inventory.repository.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
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

/// Accepts every record with a fresh server id unless [answer] says
/// otherwise.
class _FakeServer {
  final List<Json> pushBodies = [];
  Json? Function(String entity, Json record)? answer;
  int _nextId = 900;

  Future<ResponseBody> handle(RequestOptions options) async {
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

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;
  late PendingChangeRepository queue;
  late DriftVisitRepository visits;
  late DriftRouteRepository routes;
  late DriftInventoryRepository inventory;

  final arrivedAt = DateTime.utc(2026, 10, 19, 12, 15);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    engine = SyncEngine(dio: dio, db: db, sync: SyncService(dio, db));
    queue = DriftPendingChangeRepository(db);
    visits = DriftVisitRepository(db);
    routes = DriftRouteRepository(db);
    inventory = DriftInventoryRepository(db);

    // A day downloaded from the server: customer 10, route 7, stop 70.
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('c-1'),
            name: 'Kiosco Norte',
            serverId: const drift.Value(10),
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
            scheduledTime: const drift.Value('09:00:00'),
            serverId: const drift.Value(70),
          ),
        );
    await db.into(db.containerTypeTable).insert(
          ContainerTypeTableCompanion.insert(
            id: const drift.Value(3),
            code: 'BIDON_20L',
          ),
        );
    await db.into(db.visitOutcomeTable).insert(
          VisitOutcomeTableCompanion.insert(
            id: const drift.Value(2),
            name: 'Ausente',
            triggersReschedule: const drift.Value(true),
          ),
        );
  });
  tearDown(() => db.close());

  Future<void> recordVisit({
    String id = 'v-1',
    String stopId = 's-1',
    String customerId = 'c-1',
  }) => visits.recordVisit(
    Visit(
      visitId: id,
      routeStopId: stopId,
      customerId: customerId,
      visitType: VisitType.visit,
      outcomeId: 2,
      arrivedAt: arrivedAt,
      observations: 'Dejo agua en el patio',
    ),
  );

  Future<void> recordMovement({int delivered = 2, int returned = 1}) =>
      inventory.recordContainerMovement(
        ContainerMovement(
          id: 'm-1',
          customerId: 'c-1',
          containerType: 'BIDON_20L',
          deliveredQuantity: delivered,
          returnedQuantity: returned,
          createdAt: arrivedAt,
          // The visit screen links movements to the stop being visited.
          visitId: 's-1',
          routeId: 'r-1',
        ),
      );

  List<Json> sent(String entity) => [
    for (final r in (server.pushBodies.single[entity] as List? ?? const []))
      Map<String, dynamic>.from(r as Map),
  ];

  test(
    'visits and container movements travel after customers and stops',
    () async {
      await recordVisit();
      await recordMovement();
      await routes.rescheduleStop('s-1', DateTime.now());
      await DriftCustomerRepository(db).saveCustomer(
        Customer(
          id: 'c-2',
          name: 'Despensa Sur',
          phone: '387-1',
          addresses: const [],
          preferences: const [],
        ),
      );

      await engine.push();

      expect(server.pushBodies.single.keys.toList(), [
        'customers',
        'route_stops',
        'visits',
        'container_movements',
      ]);
    },
  );

  test(
    'a visit travels in the shape the server expects and stores its server id',
    () async {
      await recordVisit();

      await engine.push();

      expect(sent('visits'), [
        {
          'uuid': 'v-1',
          'customer_id': 10,
          'route_stop_id': 70,
          'outcome_id': 2,
          'arrived_at': '2026-10-19T12:15:00.000Z',
          'notes': 'Dejo agua en el patio',
        },
      ]);
      final row = await db.select(db.visitTable).getSingle();
      expect(row.serverId, 901);
      expect(await queue.countPending(), 0);
    },
  );

  test(
    'a visit of a customer created on the street references it by uuid',
    () async {
      await db.into(db.customerTable).insert(
            CustomerTableCompanion.insert(
              customerId: const drift.Value('c-new'),
              name: 'Nuevo',
            ),
          );
      await recordVisit(customerId: 'c-new');

      await engine.push();

      final visit = sent('visits').single;
      expect(visit['customer_uuid'], 'c-new');
      expect(visit.containsKey('customer_id'), isFalse);
    },
  );

  test(
    'a container movement travels as one delivery and one return linked to the visit of its stop and stores its server id',
    () async {
      await recordVisit();
      await recordMovement(delivered: 2, returned: 1);

      await engine.push();

      final movements = sent('container_movements');
      expect(movements.length, 2);
      expect(movements[0], {
        'uuid': 'm-1',
        'customer_id': 10,
        'visit_uuid': 'v-1',
        'container_type_id': 3,
        'movement_type': 'DELIVERED',
        'quantity': 2,
      });
      expect(movements[1]['movement_type'], 'RETURNED');
      expect(movements[1]['quantity'], 1);
      expect(movements[1]['uuid'], isNot('m-1'));
      final row = await db.select(db.containerMovementTable).getSingle();
      expect(row.serverId, isNotNull);
      expect(await queue.countPending(), 0);
    },
  );

  test(
    'a movement whose return the server rejects stays rejected with its reason',
    () async {
      await recordMovement(delivered: 2, returned: 1);
      server.answer = (entity, r) => r['movement_type'] == 'RETURNED'
          ? {
              'uuid': r['uuid'],
              'status': 'rejected',
              'server_id': null,
              'review_reason': null,
              'error': 'The quantity field must be at least 1.',
            }
          : null;

      await engine.push();

      final rejected = await queue.getRejected();
      expect(rejected.single.entityId, 'm-1');
      expect(
        rejected.single.rejectionReason,
        'The quantity field must be at least 1.',
      );
    },
  );

  test(
    'a rescheduled stop travels in the same request as the visit, with its uuid and the original stop, and stores its server id',
    () async {
      await recordVisit();
      final at = DateTime.now();
      final newStopId = await routes.rescheduleStop('s-1', at);

      await engine.push();

      final hhmm =
          '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
      expect(sent('route_stops'), [
        {
          'uuid': newStopId,
          'rescheduled_from_id': 70,
          'scheduled_time': hhmm,
        },
      ]);
      expect(sent('visits').single['route_stop_id'], 70);
      final stop = await (db.select(
        db.routeStopTable,
      )..where((t) => t.routeStopId.equals(newStopId))).getSingle();
      expect(stop.serverId, isNotNull);
      expect(await queue.countPending(), 0);
    },
  );

  test(
    'a stop the server reports as rescheduled is stored as rescheduled, linked to its new stop',
    () async {
      final fresh = AppDatabase(NativeDatabase.memory());
      addTearDown(fresh.close);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(200, {
            'data': {
              'route': {'id': 7, 'date': _today(), 'status': 'IN_PROGRESS'},
              'stops': [
                {
                  'id': 70,
                  'route_id': 7,
                  'customer_id': 10,
                  'address_id': null,
                  'scheduled_time': '09:00:00',
                  'is_rescheduled_from': null,
                  'status': 'RESCHEDULED',
                },
                {
                  'id': 71,
                  'route_id': 7,
                  'customer_id': 10,
                  'address_id': null,
                  'scheduled_time': '16:00:00',
                  'is_rescheduled_from': 70,
                  'status': 'PENDING',
                },
              ],
              'truck_inventory': [],
              'customers': [
                {'id': 10, 'client_uuid': null, 'name': 'Kiosco Norte'},
              ],
              'products': [],
              'container_types': [],
              'payment_methods': [],
              'visit_outcomes': [],
              'server_time': '2026-10-19T12:00:00+00:00',
            },
            'message': null,
          }),
        );

      await SyncService(dio, fresh).bootstrap();

      final stops = await DriftRouteRepository(fresh).watchDayStops().first;
      final original = stops.singleWhere((s) => s.status != StopStatus.pending);
      final created = stops.singleWhere((s) => s.status == StopStatus.pending);
      expect(original.status, StopStatus.rescheduled);
      expect(created.rescheduledFromStopId, original.id);
    },
  );

  test(
    'a stop status change travels only through its visit and leaves nothing pending',
    () async {
      await recordVisit();
      await routes.markStop('s-1', StopStatus.done);

      await engine.push();

      expect(server.pushBodies.single.containsKey('route_stops'), isFalse);
      expect(await queue.countPending(), 0);
      expect(await queue.getRejected(), isEmpty);
    },
  );
}
