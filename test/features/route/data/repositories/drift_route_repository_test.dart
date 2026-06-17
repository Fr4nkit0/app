import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/repositories/drift_route_repository.dart';
import 'package:app/features/route/data/repositories/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

void main() {
  late AppDatabase db;
  late RouteRepository sut;

  final todayStr = _dateOnly(DateTime.now());
  final yesterdayStr =
      _dateOnly(DateTime.now().subtract(const Duration(days: 1)));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    sut = DriftRouteRepository(db);
    // NativeDatabase.memory() triggers onCreate → seedDatabase inserts:
    //   - mock-customer-1..4 (always in test mode)
    //   - mock-addr-1..4 with isPrimary=true for each customer (always)
    // The !FLUTTER_TEST-gated block (routes, stops, visits, sales…) is SKIPPED.
  });

  tearDown(() async {
    await db.close();
  });

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> insertRoute(String routeId, String dateStr) async {
    await db.into(db.routeTable).insert(
          RouteTableCompanion.insert(
            routeId: drift.Value(routeId),
            route_date: dateStr,
          ),
        );
  }

  Future<void> insertStop({
    required String stopId,
    required String routeId,
    required String customerId,
    int sequence = 1,
    String status = 'pending',
    required DateTime scheduledAt,
  }) async {
    await db.into(db.routeStopTable).insert(
          RouteStopTableCompanion.insert(
            routeStopId: drift.Value(stopId),
            routeId: routeId,
            customerId: customerId,
            sequence: sequence,
            status: drift.Value(status),
            scheduledAt: scheduledAt,
          ),
        );
  }

  Future<void> insertBalance(String customerId, double balance) async {
    await db.into(db.customerBalanceTable).insertOnConflictUpdate(
          CustomerBalanceTableCompanion.insert(
            customerId: customerId,
            currentBalance: drift.Value(balance),
          ),
        );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Scenario A2 — watchDayStops returns today's stops
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — today filter', () {
    test('returns 4 RouteStop objects for today route', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      for (var i = 1; i <= 4; i++) {
        await insertStop(
          stopId: 'stop-t$i',
          routeId: 'route-today',
          customerId: 'mock-customer-$i',
          sequence: i,
          scheduledAt: DateTime(now.year, now.month, now.day, 8 + i, 0),
        );
      }

      final stops = await sut.watchDayStops().first;
      expect(stops.length, 4);
    });

    test('each RouteStop has a non-null customer with the correct name',
        () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer, isNotNull);
      expect(stops.first.customer.name, 'José García');
    });

    test('RouteStop has NO visitType field (compile-time guarantee)', () async {
      // If RouteStop had visitType this test would fail to compile.
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      final stop = stops.first;
      // RouteStop fields: id, customer, status, scheduledAt — NO visitType.
      expect(stop.id, isNotNull);
      expect(stop.customer, isNotNull);
      expect(stop.status, isNotNull);
      expect(stop.scheduledAt, isNotNull);
    });

    test('debtAmount hydrated from CustomerBalanceTable (positive balance)',
        () async {
      await insertRoute('route-today', todayStr);
      await insertBalance('mock-customer-1', 1200.0);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.debtAmount, 1200.0);
    });

    test('debtAmount is 0 when balance is negative (credit)', () async {
      await insertRoute('route-today', todayStr);
      await insertBalance('mock-customer-1', -500.0);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.debtAmount, 0.0);
    });

    test('debtAmount is 0 when no balance row exists', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.debtAmount, 0.0);
    });

    test('primary address is mapped from the seeded customer address', () async {
      // mock-customer-1 has mock-addr-1 ('Av. San Martín 1234') seeded as primary.
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-t1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.customer.addresses.length, 1);
      expect(stops.first.customer.addresses.first.street, 'Av. San Martín 1234');
      expect(stops.first.customer.addresses.first.isPrimary, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Scenario A3 — empty when no route for today
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — date filter', () {
    test('returns empty list when route_date is yesterday', () async {
      await insertRoute('route-yesterday', yesterdayStr);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await insertStop(
        stopId: 'stop-y1',
        routeId: 'route-yesterday',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: yesterday,
      );

      final stops = await sut.watchDayStops().first;
      expect(stops, isEmpty);
    });

    test('returns empty list when no routes exist at all', () async {
      final stops = await sut.watchDayStops().first;
      expect(stops, isEmpty);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Ordering: pending-first, then scheduledAt asc
  // ──────────────────────────────────────────────────────────────────────────

  group('watchDayStops — ordering', () {
    test('pending stops appear before done stops', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      // done stop has earlier scheduledAt; pending has later — pending must still come first.
      await insertStop(
        stopId: 'stop-done',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        status: 'done',
        scheduledAt: DateTime(now.year, now.month, now.day, 8, 0),
      );
      await insertStop(
        stopId: 'stop-pending',
        routeId: 'route-today',
        customerId: 'mock-customer-2',
        sequence: 2,
        status: 'pending',
        scheduledAt: DateTime(now.year, now.month, now.day, 10, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.id, 'stop-pending');
      expect(stops.last.id, 'stop-done');
    });

    test('among pending stops, earlier scheduledAt comes first', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-late',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 11, 0),
      );
      await insertStop(
        stopId: 'stop-early',
        routeId: 'route-today',
        customerId: 'mock-customer-2',
        sequence: 2,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final stops = await sut.watchDayStops().first;
      expect(stops.first.id, 'stop-early');
      expect(stops.last.id, 'stop-late');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Scenario A4 — markStop
  // ──────────────────────────────────────────────────────────────────────────

  group('markStop', () {
    test('sets status to done and non-null visitedAt', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      await sut.markStop('stop-1', StopStatus.done);

      final row = await (db.select(db.routeStopTable)
            ..where((t) => t.routeStopId.equals('stop-1')))
          .getSingle();
      expect(row.status, 'done');
      expect(row.visitedAt, isNotNull);
    });

    test('does not modify VisitTable', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      await sut.markStop('stop-1', StopStatus.done);

      final visits = await db.select(db.visitTable).get();
      expect(visits, isEmpty);
    });

    test('sets absent status correctly', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      await sut.markStop('stop-1', StopStatus.absent);

      final row = await (db.select(db.routeStopTable)
            ..where((t) => t.routeStopId.equals('stop-1')))
          .getSingle();
      expect(row.status, 'absent');
      expect(row.visitedAt, isNotNull);
    });

    test('stream re-emits after markStop with updated status', () async {
      await insertRoute('route-today', todayStr);
      final now = DateTime.now();
      await insertStop(
        stopId: 'stop-1',
        routeId: 'route-today',
        customerId: 'mock-customer-1',
        sequence: 1,
        scheduledAt: DateTime(now.year, now.month, now.day, 9, 0),
      );

      final emissions = <List<RouteStop>>[];
      final sub = sut.watchDayStops().listen(emissions.add);
      addTearDown(sub.cancel);

      await Future.delayed(const Duration(milliseconds: 30));
      expect(emissions.last.first.status, StopStatus.pending);

      await sut.markStop('stop-1', StopStatus.done);
      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.last.first.status, StopStatus.done);
    });
  });
}

// ──────────────────────────────────────────────────────────────────────────
// Utility
// ──────────────────────────────────────────────────────────────────────────

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
