import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

const _routeId = 'route-today';
final _routeDay = DateTime(2026, 10, 19);

/// Juan's route: 50 stops without a scheduled time, so all of them share
/// the route date as their scheduled time and only the sequence orders them.
const _routeSize = 50;

String _stopId(int sequence) => 'stop-${sequence.toString().padLeft(2, '0')}';

void main() {
  group('route day pagination against a database', () {
    late AppDatabase db;
    late ProviderContainer container;

    Future<void> insertCustomerAndStop(int sequence) async {
      final customerId = 'cust-$sequence';
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: drift.Value(customerId),
              name: 'Cliente $sequence',
            ),
          );
      await db
          .into(db.routeStopTable)
          .insert(
            RouteStopTableCompanion.insert(
              routeStopId: drift.Value(_stopId(sequence)),
              routeId: _routeId,
              customerId: customerId,
              sequence: sequence,
              scheduledAt: _routeDay,
            ),
          );
    }

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db
          .into(db.routeTable)
          .insert(
            RouteTableCompanion.insert(
              routeId: const drift.Value(_routeId),
              route_date: '2026-10-19',
            ),
          );
      // The download does not store the stops in route order.
      final sequences = [for (var i = 1; i <= _routeSize; i++) i]
        ..shuffle(Random(7));
      await db.transaction(() async {
        for (final sequence in sequences) {
          await insertCustomerAndStop(sequence);
        }
      });
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 19, 10)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    /// Lets the database watchers and the providers settle.
    Future<void> settle() async {
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    List<String> ids(List<RouteStop>? stops) => [
      for (final s in stops ?? const <RouteStop>[]) s.id,
    ];

    test('pending stops sharing a scheduled time follow the route '
        'sequence', () async {
      container.listen(routeAllStopsProvider, (_, _) {});
      final stops = await container.read(routeAllStopsProvider.future);

      expect(ids(stops), [for (var i = 1; i <= _routeSize; i++) _stopId(i)]);
    });

    test('scrolling while a sync writes stops loads every stop once, in '
        'route order, from the same snapshot as the total', () async {
      container.listen(routeAllStopsProvider, (_, _) {});
      container.listen(routeDayProvider, (_, _) {});
      await settle();

      final firstPage = ids(container.read(routeDayProvider).value);
      expect(firstPage, [for (var i = 1; i <= 10; i++) _stopId(i)]);

      // The driver scrolls while the sync closes a stop of a later page and
      // downloads two new stops.
      final limit = container.read(routePaginationLimitProvider.notifier);
      limit.increment(10);
      final sync = db.transaction(() async {
        await (db.update(db.routeStopTable)
              ..where((t) => t.routeStopId.equals(_stopId(15))))
            .write(const RouteStopTableCompanion(status: drift.Value('done')));
        await insertCustomerAndStop(_routeSize + 1);
        await insertCustomerAndStop(_routeSize + 2);
      });
      limit.increment(10);
      await sync;
      await settle();

      // The stops already seen keep their place.
      final secondPage = ids(container.read(routeDayProvider).value);
      expect(secondPage.take(10), firstPage);

      // The driver keeps scrolling until the end of the route.
      var guard = 0;
      while (container.read(routeDayProvider).value!.length <
          container.read(routeAllStopsProvider).value!.length) {
        limit.increment(10);
        await settle();
        expect(++guard, lessThan(20), reason: 'pagination never ends');
      }

      final page = ids(container.read(routeDayProvider).value);
      final all = ids(container.read(routeAllStopsProvider).value);
      expect(page.toSet(), hasLength(page.length), reason: 'duplicated stops');
      expect(page, all);
      expect(page, [
        for (var i = 1; i <= _routeSize + 2; i++)
          if (i != 15) _stopId(i),
        _stopId(15),
      ]);
    });
  });

  group('route day screen pagination', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    RouteStop stop(int sequence) => RouteStop(
      id: _stopId(sequence),
      customer: Customer(
        id: 'cust-$sequence',
        name: 'Cliente $sequence',
        addresses: const [],
        preferences: const [],
      ),
      status: StopStatus.pending,
      scheduledAt: _routeDay,
      hasScheduledTime: false,
    );

    Future<_FakeRouteRepository> pumpRoute(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _FakeRouteRepository([
        for (var i = 1; i <= _routeSize; i++) stop(i),
      ]);
      addTearDown(repository.close);
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_SignedIn.new),
          syncStatusProvider.overrideWith(
            (ref) => Stream.value(
              SyncStatus(
                lastCycleAt: DateTime(2026, 10, 19, 9),
                lastResult: SyncCycleResult.success,
              ),
            ),
          ),
          syncRunningProvider.overrideWith((ref) => Stream.value(false)),
          routeRepositoryProvider.overrideWithValue(repository),
          for (var i = 1; i <= _routeSize + 2; i++)
            customerContainerBalancesProvider(
              'cust-$i',
            ).overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              devicePixelRatio: 1,
            ),
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const RouteDayScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return repository;
    }

    Finder loadingMore() => find.text('Cargando más paradas...');

    /// Scrolls down until [name] shows, as a driver flinging to the end.
    Future<void> scrollUntil(WidgetTester tester, String name) async {
      for (var i = 0; i < 30 && find.text(name).evaluate().isEmpty; i++) {
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
        await tester.pump();
        // Loading the next page keeps the list on screen.
        expect(find.byType(CustomScrollView), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.text(name), findsOneWidget);
    }

    testWidgets('loading the next page keeps the list on screen and reaches '
        'the last stop', (tester) async {
      await pumpRoute(tester);
      expect(find.text('Cliente $_routeSize'), findsNothing);

      await scrollUntil(tester, 'Cliente $_routeSize');

      expect(loadingMore(), findsNothing);
    });

    testWidgets('stops a sync adds while the end of the list is on screen '
        'load without another scroll', (tester) async {
      final repository = await pumpRoute(tester);
      await scrollUntil(tester, 'Cliente $_routeSize');
      expect(loadingMore(), findsNothing);

      repository.emit([for (var i = 1; i <= _routeSize + 2; i++) stop(i)]);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(loadingMore(), findsNothing, reason: 'stuck loading more');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pump();
      expect(find.text('Cliente ${_routeSize + 2}'), findsOneWidget);
    });
  });
}

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(isAuthenticated: true, displayName: 'Juan');
}

/// Serves the day stops from memory; [emit] plays a sync changing them.
class _FakeRouteRepository implements RouteRepository {
  _FakeRouteRepository(this._stops);

  List<RouteStop> _stops;
  final _changes = StreamController<List<RouteStop>>.broadcast();

  void emit(List<RouteStop> stops) {
    _stops = stops;
    _changes.add(stops);
  }

  Future<void> close() => _changes.close();

  @override
  Stream<List<RouteStop>> watchDayStops() async* {
    yield _stops;
    yield* _changes.stream;
  }

  @override
  Future<void> markStop(String id, StopStatus status) =>
      throw UnimplementedError();

  @override
  Future<String> rescheduleStop(String stopId, DateTime at) =>
      throw UnimplementedError();
}
