import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/route/data/repositories/repositories/drift_route_repository.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
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
  Stream<List<Visit>> watchVisitsForStop(String routeStopId) =>
      const Stream.empty();
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
    await db.into(db.routeTable).insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('route-test-1'),
            route_date: _dateOnly(DateTime.now()),
          ),
        );
    await db.into(db.routeStopTable).insert(
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
    test('returns Resource.success(null) when both steps succeed', () async {
      final result = await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcome: 'successful',
      );

      expect(result, isA<Success<void>>());
    });

    test('VisitTable has 1 row after successful execute', () async {
      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcome: 'successful',
      );

      final visits = await db.select(db.visitTable).get();
      expect(visits.length, 1);
      expect(visits.first.routeStopId, 'stop-test-1');
      expect(visits.first.customerId, 'mock-customer-1');
      expect(visits.first.visitType, 'sale');
      expect(visits.first.outcome, 'successful');
    });

    test('RouteStopTable has status=done and visitedAt set', () async {
      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.sale,
        nextStatus: StopStatus.done,
        outcome: 'successful',
      );

      final row = await (db.select(db.routeStopTable)
            ..where((t) => t.routeStopId.equals('stop-test-1')))
          .getSingle();
      expect(row.status, 'done');
      expect(row.visitedAt, isNotNull);
    });

    test('observations are persisted when provided', () async {
      await sut.execute(
        stopId: 'stop-test-1',
        customerId: 'mock-customer-1',
        visitType: VisitType.visit,
        nextStatus: StopStatus.absent,
        outcome: 'absent',
        observations: 'Client not at home',
      );

      final visits = await db.select(db.visitTable).get();
      expect(visits.first.observations, 'Client not at home');
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
        outcome: 'successful',
      );

      expect(result, isA<Error<void>>());
    });

    test('RouteStopTable status is UNCHANGED when recordVisit fails (F2b)',
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
        outcome: 'successful',
      );

      // markStop must NOT have been called.
      final row = await (db.select(db.routeStopTable)
            ..where((t) => t.routeStopId.equals('stop-test-1')))
          .getSingle();
      expect(row.status, 'pending'); // unchanged
      expect(row.visitedAt, isNull);
    });
  });
}

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// Suppress unused import — Uuid is needed for visitId generation in use case.
const _uuid = Uuid();
