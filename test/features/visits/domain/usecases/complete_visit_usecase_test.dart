import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/route/data/repositories/repositories/drift_route_repository.dart';
import 'package:app/features/route/data/repositories/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/domain/reschedule_time.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/usecases/complete_visit.usecase.dart';

// ──────────────────────────────────────────────────────────────────────────
// Fake VisitRepository that throws on recordVisit (for Scenario F2b)
// ──────────────────────────────────────────────────────────────────────────

class FakeFailingVisitRepository implements VisitRepository {
  @override
  Future<void> recordVisit(Visit visit) async {
    throw Exception('Simulated recordVisit failure');
  }

  @override
  Stream<List<VisitOutcome>> watchOutcomes() => const Stream.empty();

  @override
  Future<int?> findDeliveredOutcomeId() async => null;

  @override
  Stream<List<Visit>> watchVisitsForStop(String routeStopId) =>
      const Stream.empty();
}

/// Route repository whose reschedule fails after the visit was recorded.
class _FailingRescheduleRouteRepository implements RouteRepository {
  _FailingRescheduleRouteRepository(this._inner);

  final RouteRepository _inner;

  @override
  Stream<List<RouteStop>> watchDayStops() => _inner.watchDayStops();

  @override
  Future<void> markStop(String id, StopStatus status) =>
      _inner.markStop(id, status);

  @override
  Future<String> rescheduleStop(String stopId, DateTime at) async {
    throw Exception('Simulated reschedule failure');
  }
}

void main() {
  late AppDatabase db;
  late DriftRouteRepository routeRepo;
  late DriftVisitRepository visitRepo;
  late CompleteVisitUseCase sut;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    routeRepo = DriftRouteRepository(db);
    visitRepo = DriftVisitRepository(db);
    sut = CompleteVisitUseCase(routeRepo: routeRepo, visitRepo: visitRepo);

    // Insert a route + stop fixture.
    // Customers mock-customer-1..4 are already seeded.
    await db
        .into(db.routeTable)
        .insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('route-test-1'),
            route_date: _dateOnly(DateTime.now()),
          ),
        );
    await db
        .into(db.routeStopTable)
        .insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('stop-test-1'),
            routeId: 'route-test-1',
            customerId: 'mock-customer-1',
            sequence: 1,
            status: const drift.Value('pending'),
            scheduledAt: DateTime.now(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F2a — success
  // ───────────────────────────────────────────────────────────────

  group('execute — success (F2a)', () {
    test('without an outcome it records the catalog delivered outcome', () async {
      await db.into(db.visitOutcomeTable).insert(
            VisitOutcomeTableCompanion.insert(
              id: const drift.Value(2),
              name: 'Absent',
              triggersReschedule: const drift.Value(true),
            ),
          );
      await db.into(db.visitOutcomeTable).insert(
            VisitOutcomeTableCompanion.insert(
              id: const drift.Value(3),
              name: 'Delivered',
            ),
          );

      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
      );

      expect((await db.select(db.visitTable).getSingle()).outcomeId, 3);
    });

    test('returns Resource.success(null) when both steps succeed', () async {
      final result = await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcomeId: 1,
      );

      expect(result, isA<Success<void>>());
    });

    test('VisitTable has 1 row after successful execute', () async {
      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcomeId: 1,
      );

      final visits = await db.select(db.visitTable).get();
      expect(visits.length, 1);
      expect(visits.first.routeStopId, 'stop-test-1');
      expect(visits.first.customerId, 'mock-customer-1');
      expect(visits.first.visitType, 'sale');
      expect(visits.first.outcomeId, 1);
    });

    test('RouteStopTable has status=done and visitedAt set', () async {
      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcomeId: 1,
      );

      final row = await (db.select(
        db.routeStopTable,
      )..where((t) => t.routeStopId.equals('stop-test-1'))).getSingle();
      expect(row.status, 'done');
      expect(row.visitedAt, isNotNull);
    });

    test('observations are persisted when provided', () async {
      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.visit,
        nextStatus: StopStatus.absent,
        outcomeId: 2,
        observations: 'Client not at home',
      );

      final visits = await db.select(db.visitTable).get();
      expect(visits.first.observations, 'Client not at home');
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Rescheduling later the same day (ADR 0002)
  // ───────────────────────────────────────────────────────────────

  group('execute — reschedule', () {
    final now = DateTime(2026, 10, 19, 8, 0);

    CompleteVisitUseCase sutAt(DateTime clock) => CompleteVisitUseCase(
      routeRepo: routeRepo,
      visitRepo: visitRepo,
      transaction: db.transaction,
      now: () => clock,
    );

    Future<List<RouteStopTableData>> stops() =>
        db.select(db.routeStopTable).get();

    Future<Resource<void>> reschedule(DateTime at) => sutAt(now).execute(
      stopId: 'stop-test-1',
      customerId: 'mock-customer-1',
      visitType: VisitType.visit,
      nextStatus: StopStatus.absent,
      outcomeId: 2,
      rescheduleAt: at,
    );

    test(
      'a later time of the same day creates a linked stop in the same route and marks the original rescheduled',
      () async {
        final at = DateTime(2026, 10, 19, 15, 30);

        final result = await reschedule(at);

        expect(result, isA<Success<void>>());
        final rows = await stops();
        final original = rows.singleWhere(
          (s) => s.routeStopId == 'stop-test-1',
        );
        final created = rows.singleWhere((s) => s.routeStopId != 'stop-test-1');
        expect(original.status, 'rescheduled');
        expect(created.routeId, 'route-test-1');
        expect(created.customerId, 'mock-customer-1');
        expect(created.rescheduledFromStopId, 'stop-test-1');
        expect(created.scheduledAt, at);
        expect(created.status, 'pending');
        expect((await db.select(db.visitTable).getSingle()).routeStopId,
            'stop-test-1');
      },
    );

    test('another day is not allowed and changes nothing', () async {
      final result = await reschedule(DateTime(2026, 10, 20, 10, 0));

      expect(result, isA<Error<void>>());
      expect(
        ((result as Error<void>).error as RescheduleTimeException).reason,
        RescheduleTimeError.otherDay,
      );
      expect((await stops()).length, 1);
      expect((await stops()).single.status, 'pending');
      expect(await db.select(db.visitTable).get(), isEmpty);
    });

    test('a past time is not allowed and changes nothing', () async {
      final result = await reschedule(DateTime(2026, 10, 19, 7, 30));

      expect(result, isA<Error<void>>());
      expect(
        ((result as Error<void>).error as RescheduleTimeException).reason,
        RescheduleTimeError.notLater,
      );
      expect((await stops()).length, 1);
      expect(await db.select(db.visitTable).get(), isEmpty);
    });

    test(
      'when the new stop cannot be saved the visit is not recorded either, so both always travel together',
      () async {
        final failing = CompleteVisitUseCase(
          routeRepo: _FailingRescheduleRouteRepository(routeRepo),
          visitRepo: visitRepo,
          transaction: db.transaction,
          now: () => now,
        );

        final result = await failing.execute(
          stopId: 'stop-test-1',
          customerId: 'mock-customer-1',
          visitType: VisitType.visit,
          nextStatus: StopStatus.absent,
          outcomeId: 2,
          rescheduleAt: DateTime(2026, 10, 19, 15, 30),
        );

        expect(result, isA<Error<void>>());
        expect(await db.select(db.visitTable).get(), isEmpty);
        expect(await db.select(db.pendingChangeTable).get(), isEmpty);
      },
    );

    test('a visit without reschedule creates no new stop', () async {
      await sutAt(now).execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.visit,
        nextStatus: StopStatus.absent,
        outcomeId: 2,
      );

      expect((await stops()).single.status, 'absent');
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario F2b — recordVisit failure → markStop NOT called
  // ───────────────────────────────────────────────────────────────

  group('execute — recordVisit failure (F2b)', () {
    test('returns Resource.error when recordVisit throws', () async {
      final failingVisitRepo = FakeFailingVisitRepository();
      final sutWithFailing = CompleteVisitUseCase(
        routeRepo: routeRepo,
        visitRepo: failingVisitRepo,
      );

      final result = await sutWithFailing.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcomeId: 1,
      );

      expect(result, isA<Error<void>>());
    });

    test(
      'RouteStopTable status is UNCHANGED when recordVisit fails (F2b)',
      () async {
        final failingVisitRepo = FakeFailingVisitRepository();
        final sutWithFailing = CompleteVisitUseCase(
          routeRepo: routeRepo,
          visitRepo: failingVisitRepo,
        );

        await sutWithFailing.execute(
          stopId: 'stop-test-1',
          customerId: 'mock-customer-1',
          visitType: VisitType.sale,
          nextStatus: StopStatus.done,
          outcomeId: 1,
        );

        // markStop must NOT have been called.
        final row = await (db.select(
          db.routeStopTable,
        )..where((t) => t.routeStopId.equals('stop-test-1'))).getSingle();
        expect(row.status, 'pending'); // unchanged
        expect(row.visitedAt, isNull);
      },
    );
  });
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// Suppress unused import — Uuid is needed for visitId generation in use case.
const _uuid = Uuid();
