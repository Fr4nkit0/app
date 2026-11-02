import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sync/background/background_sync_task.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/sync/pull/pull_applier.dart' show dateOnly;
import 'package:app/features/sync/sync_service.dart';

import '../../../support/fake_http_adapter.dart';

/// A first-login download: today's route with two pending stops.
Map<String, dynamic> _bootstrap(String date) => {
  'data': {
    'route': {'id': 7, 'date': date, 'status': 'IN_PROGRESS'},
    'stops': [
      {'id': 71, 'route_id': 7, 'customer_id': 11, 'status': 'PENDING'},
      {'id': 72, 'route_id': 7, 'customer_id': 12, 'status': 'PENDING'},
    ],
    'truck_inventory': [],
    'customers': [
      {'id': 11, 'client_uuid': 'cust-uuid-11', 'name': 'Ana'},
      {'id': 12, 'client_uuid': 'cust-uuid-12', 'name': 'Beto'},
    ],
    'products': [],
    'visits': [],
    'sales': [],
    'server_time': '${date}T12:00:00+00:00',
  },
  'message': null,
};

void main() {
  // watchDayStops reads the real clock, so the route must be today's.
  final today = dateOnly(DateTime.now());
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(200, _bootstrap(today)),
      );
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        dioProvider.overrideWithValue(dio),
        // The same engine the app runs in the foreground.
        leasedSyncEngineOverride(owner: foregroundLeaseOwner),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// Completes with the first non-empty list [routeAllStopsProvider] emits.
  Future<List<RouteStop>> firstStops() {
    final found = Completer<List<RouteStop>>();
    container.listen(routeAllStopsProvider, (_, next) {
      final stops = next.value;
      if (stops != null && stops.isNotEmpty && !found.isCompleted) {
        found.complete(stops);
      }
    }, fireImmediately: true);
    return found.future.timeout(const Duration(seconds: 2));
  }

  test('a route screen opened before the first bootstrap shows the downloaded '
      'stops without another sync', () async {
    // The route tab is mounted (empty database) before the first sync ends.
    final subscription = container.listen(routeAllStopsProvider, (_, _) {});
    await container.read(routeAllStopsProvider.future);
    expect(container.read(routeAllStopsProvider).value, isEmpty);

    final stops = firstStops();
    await container.read(syncServiceProvider).bootstrap();

    expect((await stops).map((s) => s.customer.name), ['Ana', 'Beto']);
    subscription.close();
  });

  test('the first sync cycle of the app engine shows the stops on a route '
      'screen opened before it', () async {
    final subscription = container.listen(routeAllStopsProvider, (_, _) {});
    await container.read(routeAllStopsProvider.future);

    final stops = firstStops();
    await container.read(syncEngineProvider).runCycle();

    expect((await stops).map((s) => s.customer.name), ['Ana', 'Beto']);
    subscription.close();
  });

  test('control: stops read after the bootstrap are listed', () async {
    await container.read(syncServiceProvider).bootstrap();

    expect(
      (await firstStops()).map((s) => s.customer.name),
      ['Ana', 'Beto'],
    );
  });
}
