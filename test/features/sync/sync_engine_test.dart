import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/sync_engine.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../support/fake_http_adapter.dart';

String _today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Map<String, dynamic> _bootstrap() => {
  'data': {
    'route': {'id': 7, 'date': _today(), 'status': 'IN_PROGRESS'},
    'stops': [],
    'truck_inventory': [],
    'customers': [],
    'products': [],
    'container_types': [],
    'payment_methods': [],
    'visit_outcomes': [],
    'server_time': '2026-10-19T12:00:00+00:00',
  },
  'message': null,
};

Map<String, dynamic> _pullPage(Map<String, List<Map<String, dynamic>>> rows) =>
    {
      'data': rows,
      'meta': {
        'page': 1,
        'per_page': 200,
        'is_last_page': true,
        'until': '2026-10-19T13:00:00+00:00',
        'cursor': '2026-10-19T12:59:55+00:00',
      },
      'message': null,
    };

typedef PushAnswer = Map<String, dynamic> Function(Map<String, dynamic> record);

/// In-memory stand-in for the server: remembers customers by client uuid,
/// like the real push does, so a replay answers the same server id.
class _FakeServer {
  final Map<String, int> customersByUuid = {};
  final List<String> calls = [];
  final List<Map<String, dynamic>> pushBodies = [];
  Map<String, List<Map<String, dynamic>>> pullRows = {};
  PushAnswer? answer;
  bool dropNextPushResponse = false;
  Completer<void>? holdPush;
  int _nextId = 500;

  Map<String, dynamic> accept(
    Map<String, dynamic> record, {
    String? reviewReason,
  }) {
    final id = customersByUuid.putIfAbsent(
      record['uuid'] as String,
      () => ++_nextId,
    );
    return {
      'uuid': record['uuid'],
      'status': 'accepted',
      'server_id': id,
      'review_reason': reviewReason,
    };
  }

  Future<ResponseBody> handle(RequestOptions options) async {
    calls.add(options.path);
    switch (options.path) {
      case '/sync/bootstrap':
        return FakeHttpAdapter.json(200, _bootstrap());
      case '/sync/pull':
        return FakeHttpAdapter.json(200, _pullPage(pullRows));
      case '/sync/push':
        final body = Map<String, dynamic>.from(options.data as Map);
        pushBodies.add(body);
        if (holdPush != null) await holdPush!.future;
        final customers = [
          for (final r in (body['customers'] as List? ?? const []))
            (answer ?? accept)(Map<String, dynamic>.from(r as Map)),
        ];
        if (dropNextPushResponse) {
          dropNextPushResponse = false;
          throw DioException.connectionError(
            requestOptions: options,
            reason: 'connection lost',
          );
        }
        return FakeHttpAdapter.json(200, {
          'data': {
            'customers': customers,
            'route_stops': [],
            'visits': [],
            'container_movements': [],
            'sales': [],
            'payments': [],
          },
          'message': null,
        });
    }
    throw StateError('Unexpected request ${options.path}');
  }
}

void main() {
  late AppDatabase db;
  late _FakeServer server;
  late SyncEngine engine;
  late DriftCustomerRepository customers;
  late PendingChangeRepository queue;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    server = _FakeServer();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(server.handle);
    final sync = SyncService(dio, db);
    engine = SyncEngine(dio: dio, db: db, sync: sync);
    customers = DriftCustomerRepository(db);
    queue = DriftPendingChangeRepository(db);
  });
  tearDown(() => db.close());

  Future<void> createCustomer(String id, {String name = 'Kiosco Norte'}) async {
    await customers.saveCustomer(
      Customer(
        id: id,
        name: name,
        phone: '387-$id',
        addresses: [
          CustomerAddress(
            id: 'addr-$id',
            street: 'Av Belgrano 100',
            floor: '2',
            isPrimary: true,
            latitude: -24.785,
            longitude: -65.411,
          ),
        ],
        preferences: const [],
      ),
    );
  }

  Future<CustomerTableData> localCustomer(String id) => (db.select(
    db.customerTable,
  )..where((t) => t.customerId.equals(id))).getSingle();

  test(
    'a cycle pushes the pending changes first and then downloads the day',
    () async {
      await createCustomer('c-1');

      final status = await engine.runCycle();

      expect(server.calls, ['/sync/push', '/sync/bootstrap']);
      expect(status.lastResult, SyncCycleResult.success);
      expect(await queue.countPending(), 0);
    },
  );

  test('once the day is downloaded, a cycle pushes and then pulls', () async {
    await engine.runCycle();
    await createCustomer('c-1');
    server.calls.clear();

    await engine.runCycle();

    expect(server.calls, ['/sync/push', '/sync/pull']);
  });

  test(
    'a cycle triggered while another runs joins it instead of starting a second one',
    () async {
      await createCustomer('c-1');
      server.holdPush = Completer<void>();

      final first = engine.runCycle();
      final second = engine.runCycle();
      expect(engine.isRunning, isTrue);
      await pumpEventQueue();
      server.holdPush!.complete();
      await Future.wait([first, second]);

      expect(server.calls.where((c) => c == '/sync/push').length, 1);
      expect(server.calls.where((c) => c == '/sync/bootstrap').length, 1);
      expect(engine.isRunning, isFalse);
    },
  );

  test('pushes a customer in the shape the server expects', () async {
    await createCustomer('c-1');

    await engine.runCycle();

    final record =
        (server.pushBodies.single['customers'] as List).single as Map;
    expect(record['uuid'], 'c-1');
    expect(record.containsKey('server_id'), isFalse);
    expect(record['name'], 'Kiosco Norte');
    expect(record['phone_number'], '387-c-1');
    expect(DateTime.parse(record['modified_at'] as String).isUtc, isTrue);
    expect(record['address'], {
      'street': 'Av Belgrano 100',
      'apartment': null,
      'floor': 2,
      'visual_reference': null,
      'neighborhood': null,
      'latitude': -24.785,
      'longitude': -65.411,
    });
  });

  test(
    'an accepted customer stores its server id and the server id of its address',
    () async {
      await engine.runCycle();
      await createCustomer('c-1');
      server.pullRows = {
        'customers': [
          {
            'id': 501,
            'client_uuid': 'c-1',
            'name': 'Kiosco Norte',
            'phone_number': '3874001122',
            'enabled': true,
          },
        ],
        'customer_addresses': [
          {
            'id': 601,
            'customer_id': 501,
            'street': 'Av Belgrano 100',
            'is_primary': true,
            'enabled': true,
          },
        ],
      };

      await engine.runCycle();

      expect((await localCustomer('c-1')).serverId, 501);
      final addresses = await db.select(db.customerAddressTable).get();
      expect(addresses.length, 1);
      expect(addresses.single.addressId, 'addr-c-1');
      expect(addresses.single.serverId, 601);
      expect(await queue.countPending(), 0);
    },
  );

  test('an edit of a synced customer travels with its server id', () async {
    await createCustomer('c-1');
    await engine.runCycle();
    await createCustomer('c-1', name: 'Kiosco Norte 2');

    await engine.runCycle();

    final record = (server.pushBodies.last['customers'] as List).single as Map;
    expect(record['server_id'], 501);
    expect(record['name'], 'Kiosco Norte 2');
  });

  test(
    'a rejected customer keeps the reason and is not sent again by later cycles',
    () async {
      await createCustomer('c-1');
      server.answer = (record) => {
        'uuid': record['uuid'],
        'status': 'rejected',
        'server_id': null,
        'review_reason': null,
        'error': 'The address.street field is required.',
      };

      final status = await engine.runCycle();
      server.answer = null;
      await engine.runCycle();

      final rejected = await queue.getRejected();
      expect(rejected.single.entityId, 'c-1');
      expect(
        rejected.single.rejectionReason,
        'The address.street field is required.',
      );
      expect((await localCustomer('c-1')).serverId, isNull);
      expect(server.pushBodies.length, 1);
      expect(status.rejectedCount, 1);
      expect(status.pendingCount, 0);
    },
  );

  test(
    'a customer accepted with a review reason is treated as accepted',
    () async {
      await createCustomer('c-1');
      server.answer = (record) => server.accept(
        record,
        reviewReason: 'Customer is assigned to another driver.',
      );

      await engine.runCycle();

      expect((await localCustomer('c-1')).serverId, 501);
      expect(await queue.countPending(), 0);
      expect(await queue.getRejected(), isEmpty);
    },
  );

  test(
    'a network cut during the push duplicates nothing when the cycle is retried',
    () async {
      await createCustomer('c-1');
      server.dropNextPushResponse = true;

      final failed = await engine.runCycle();

      expect(failed.lastResult, SyncCycleResult.failure);
      expect(failed.pendingCount, 1);
      expect((await localCustomer('c-1')).serverId, isNull);
      expect(server.calls, [
        '/sync/push',
      ], reason: 'no download after a failed push');

      final retried = await engine.runCycle();

      expect(retried.lastResult, SyncCycleResult.success);
      expect(retried.pendingCount, 0);
      expect(server.customersByUuid, {'c-1': 501});
      expect(
        server.pushBodies.map(
          (b) => ((b['customers'] as List).single as Map)['uuid'],
        ),
        ['c-1', 'c-1'],
      );
      expect((await localCustomer('c-1')).serverId, 501);
    },
  );

  test(
    'a change made while the push is in flight stays pending for the next cycle',
    () async {
      await createCustomer('c-1');
      server.holdPush = Completer<void>();

      final cycle = engine.runCycle();
      await pumpEventQueue();
      await createCustomer('c-1', name: 'Edited meanwhile');
      server.holdPush!.complete();
      final status = await cycle;

      expect(status.pendingCount, 1);
      expect((await queue.getPending()).single.entityId, 'c-1');
    },
  );

  test(
    'the status reports when the last cycle ran, its result and the queue counts',
    () async {
      final before = await engine.status();
      expect(before.lastCycleAt, isNull);
      expect(before.lastResult, isNull);

      await createCustomer('c-1');
      await createCustomer('c-2', name: 'Otro');
      server.answer = (record) => record['uuid'] == 'c-2'
          ? {
              'uuid': 'c-2',
              'status': 'rejected',
              'server_id': null,
              'review_reason': null,
              'error': 'Invalid.',
            }
          : server.accept(record);
      await engine.runCycle();
      await createCustomer('c-3', name: 'Nuevo');

      final status = await engine.watchStatus().first;
      expect(status.lastCycleAt, isNotNull);
      expect(status.lastResult, SyncCycleResult.success);
      expect(status.pendingCount, 1);
      expect(status.rejectedCount, 1);
    },
  );

  test(
    'a locally deleted customer is rejected with a reason instead of being sent',
    () async {
      await createCustomer('c-1');
      await customers.deleteCustomer('c-1');

      await engine.runCycle();

      expect(server.pushBodies, isEmpty);
      final rejected = await queue.getRejected();
      expect(rejected.length, 2);
      expect(rejected.every((c) => c.rejectionReason != null), isTrue);
    },
  );

  test('queued changes of entities without a pusher stay pending', () async {
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
      payload: {'saleId': 'sale-1'},
    );

    final status = await engine.runCycle();

    expect(server.pushBodies, isEmpty);
    expect(status.pendingCount, 1);
    expect(status.lastResult, SyncCycleResult.success);
  });
}
