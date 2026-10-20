import 'package:dio/dio.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/customers/data/repositories/drift.customer.repository.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/sync/background/cycle_lease.dart';
import 'package:app/features/sync/background/leased_sync_engine.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/sync_service.dart';

import '../../../support/fake_http_adapter.dart';

String today() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// In-memory server: answers bootstrap, pull and push, and can be told to
/// fail an endpoint or to drop the connection.
class FakeSyncServer {
  final List<String> calls = [];

  /// Path -> HTTP status to answer instead of the normal body.
  final Map<String, int> failWith = {};

  /// When true every request fails as if there was no network.
  bool offline = false;

  int _nextId = 500;

  Future<ResponseBody> handle(RequestOptions options) async {
    calls.add(options.path);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'no network',
      );
    }
    final status = failWith[options.path];
    if (status != null) {
      return FakeHttpAdapter.json(status, {'message': 'boom'});
    }
    switch (options.path) {
      case '/sync/bootstrap':
        return FakeHttpAdapter.json(200, {
          'data': {
            'route': {'id': 7, 'date': today(), 'status': 'IN_PROGRESS'},
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
        });
      case '/sync/pull':
        return FakeHttpAdapter.json(200, {
          'data': <String, dynamic>{},
          'meta': {
            'page': 1,
            'per_page': 200,
            'is_last_page': true,
            'until': '2026-10-19T13:00:00+00:00',
            'cursor': '2026-10-19T12:59:55+00:00',
          },
          'message': null,
        });
      case '/sync/push':
        final body = Map<String, dynamic>.from(options.data as Map);
        return FakeHttpAdapter.json(200, {
          'data': {
            'customers': [
              for (final r in (body['customers'] as List? ?? const []))
                {
                  'uuid': (r as Map)['uuid'],
                  'status': 'accepted',
                  'server_id': ++_nextId,
                },
            ],
          },
          'message': null,
        });
    }
    throw StateError('Unexpected request ${options.path}');
  }
}

/// Builds a lease-aware engine over [db] that talks to [server].
LeasedSyncEngine buildEngine(
  AppDatabase db,
  FakeSyncServer server, {
  String owner = 'background',
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = FakeHttpAdapter(server.handle);
  return LeasedSyncEngine(
    dio: dio,
    db: db,
    sync: SyncService(dio, db),
    lease: CycleLease(db, owner: owner),
  );
}

/// Queue counts and last cycle as the app shows them.
Future<SyncStatus> engineStatus(AppDatabase db) =>
    buildEngine(db, FakeSyncServer(), owner: 'reader').status();

/// Creates a customer locally, which queues one pending change.
Future<void> createCustomer(AppDatabase db, String id) =>
    DriftCustomerRepository(db).saveCustomer(
      Customer(
        id: id,
        name: 'Kiosco Norte',
        phone: '387-$id',
        addresses: [
          CustomerAddress(
            id: 'addr-$id',
            street: 'Av Belgrano 100',
            isPrimary: true,
          ),
        ],
        preferences: const [],
      ),
    );
