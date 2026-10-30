import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
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
  Stream<List<Visit>> watchVisitsForStop(String routeStopId) =>
      const Stream.empty();

  @override
  Future<Visit?> findVisit(String visitId) async => null;

  @override
  Future<VisitOutcome?> findOutcome(int id) async => null;

  @override
  Future<bool> stopHasSales(String routeStopId) async => false;

  @override
  Future<void> editVisit(
    String visitId, {
    required int outcomeId,
    String? observations,
    required DateTime modifiedAt,
  }) async {}
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
    sut = CompleteVisitUseCase(
      routeRepo: routeRepo,
      visitRepo: visitRepo,
      transaction: driftTransactionRunner(db),
    );

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
    test('without an outcome (a sale) it records no outcome', () async {
      await db
          .into(db.visitOutcomeTable)
          .insert(
            VisitOutcomeTableCompanion.insert(
              id: const drift.Value(2),
              name: 'Absent',
              triggersReschedule: const drift.Value(true),
            ),
          );
      await db
          .into(db.visitOutcomeTable)
          .insert(
            VisitOutcomeTableCompanion.insert(
              id: const drift.Value(3),
              name: 'Ausente',
            ),
          );

      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
      );

      expect((await db.select(db.visitTable).getSingle()).outcomeId, isNull);
    });

    test('completes when both steps succeed', () async {
      await expectLater(
        sut.execute(
          stopId: 'stop-test-1',
          customerId: 'mock-customer-1',
          visitType: VisitType.sale,
          nextStatus: StopStatus.done,
          outcomeId: 1,
        ),
        completes,
      );
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
      transaction: driftTransactionRunner(db),
      now: () => clock,
    );

    Future<List<RouteStopTableData>> stops() =>
        db.select(db.routeStopTable).get();

    Future<void> reschedule(DateTime at) => sutAt(now).execute(
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

        await reschedule(at);

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
        expect(
          (await db.select(db.visitTable).getSingle()).routeStopId,
          'stop-test-1',
        );
      },
    );

    test('another day is not allowed and changes nothing', () async {
      await expectLater(
        reschedule(DateTime(2026, 10, 20, 10, 0)),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.message,
            'message',
            'Solo se puede reprogramar para hoy.',
          ),
        ),
      );
      expect((await stops()).length, 1);
      expect((await stops()).single.status, 'pending');
      expect(await db.select(db.visitTable).get(), isEmpty);
    });

    test('a past time is not allowed and changes nothing', () async {
      await expectLater(
        reschedule(DateTime(2026, 10, 19, 7, 30)),
        throwsA(
          isA<ValidationFailure>().having(
            (e) => e.message,
            'message',
            'Elegí una hora posterior a la actual.',
          ),
        ),
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
          transaction: driftTransactionRunner(db),
          now: () => now,
        );

        await expectLater(
          failing.execute(
            stopId: 'stop-test-1',
            customerId: 'mock-customer-1',
            visitType: VisitType.visit,
            nextStatus: StopStatus.absent,
            outcomeId: 2,
            rescheduleAt: DateTime(2026, 10, 19, 15, 30),
          ),
          throwsA(isA<StorageFailure>()),
        );
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
    test('throws a StorageFailure when recordVisit throws', () async {
      final failingVisitRepo = FakeFailingVisitRepository();
      final sutWithFailing = CompleteVisitUseCase(
        routeRepo: routeRepo,
        visitRepo: failingVisitRepo,
        transaction: driftTransactionRunner(db),
      );

      await expectLater(
        sutWithFailing.execute(
          stopId: 'stop-test-1',
          customerId: 'mock-customer-1',
          visitType: VisitType.sale,
          nextStatus: StopStatus.done,
          outcomeId: 1,
        ),
        throwsA(isA<StorageFailure>()),
      );
    });

    test(
      'RouteStopTable status is UNCHANGED when recordVisit fails (F2b)',
      () async {
        final failingVisitRepo = FakeFailingVisitRepository();
        final sutWithFailing = CompleteVisitUseCase(
          routeRepo: routeRepo,
          visitRepo: failingVisitRepo,
          transaction: driftTransactionRunner(db),
        );

        await expectLater(
          sutWithFailing.execute(
            stopId: 'stop-test-1',
            customerId: 'mock-customer-1',
            visitType: VisitType.sale,
            nextStatus: StopStatus.done,
            outcomeId: 1,
          ),
          throwsA(isA<StorageFailure>()),
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
