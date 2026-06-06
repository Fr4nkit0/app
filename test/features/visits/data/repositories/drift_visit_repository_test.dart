import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

void main() {
  late AppDatabase db;
  late VisitRepository sut;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // DriftVisitRepository is declared in drift_visit.repository.dart (GREEN phase).
    // This import will compile once the implementation file exists.
    sut = _buildSut(db);

    // Insert fixture: customer + route + route_stop rows.
    // SQLite does NOT enforce FK constraints in tests — arbitrary IDs are valid.
    await db.into(db.customerTable).insert(
          CustomerTableCompanion.insert(
            customerId: const drift.Value('customer-test-1'),
            name: 'Test Customer',
          ),
        );
    await db.into(db.routeTable).insert(
          RouteTableCompanion.insert(
            routeId: const drift.Value('route-test-1'),
            route_date: '2026-06-06',
          ),
        );
    await db.into(db.routeStopTable).insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('stop-1'),
            routeId: 'route-test-1',
            customerId: 'customer-test-1',
            sequence: 1,
            scheduledAt: DateTime(2026, 6, 6, 9, 0),
          ),
        );
    await db.into(db.routeStopTable).insert(
          RouteStopTableCompanion.insert(
            routeStopId: const drift.Value('stop-2'),
            routeId: 'route-test-1',
            customerId: 'customer-test-1',
            sequence: 2,
            scheduledAt: DateTime(2026, 6, 6, 10, 0),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Visit makeVisit({
    String? visitId,
    String routeStopId = 'stop-1',
    String customerId = 'customer-test-1',
    VisitType visitType = VisitType.sale,
    String outcome = 'successful',
    DateTime? arrivedAt,
    String? observations,
    double amountCollected = 0,
  }) {
    return Visit(
      visitId: visitId ?? const Uuid().v4(),
      routeStopId: routeStopId,
      customerId: customerId,
      visitType: visitType,
      outcome: outcome,
      arrivedAt: arrivedAt ?? DateTime(2026, 6, 6, 9, 30),
      observations: observations,
      amountCollected: amountCollected,
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Scenario B1 — recordVisit success
  // ───────────────────────────────────────────────────────────────

  group('recordVisit', () {
    test('inserts one row in VisitTable and does not throw', () async {
      final visit = makeVisit(visitId: 'visit-b1');

      await expectLater(sut.recordVisit(visit), completes);

      final rows = await db.select(db.visitTable).get();
      expect(rows.length, 1);
      expect(rows.first.visitId, 'visit-b1');
      expect(rows.first.routeStopId, 'stop-1');
      expect(rows.first.customerId, 'customer-test-1');
    });

    test('persists visitType as text (enum name)', () async {
      await sut.recordVisit(makeVisit(
        visitId: 'visit-type-sale',
        visitType: VisitType.sale,
      ));
      await sut.recordVisit(makeVisit(
        visitId: 'visit-type-visit',
        visitType: VisitType.visit,
        routeStopId: 'stop-2',
      ));

      final rows = await db.select(db.visitTable).get();
      final saleRow = rows.firstWhere((r) => r.visitId == 'visit-type-sale');
      final visitRow = rows.firstWhere((r) => r.visitId == 'visit-type-visit');
      expect(saleRow.visitType, 'sale');
      expect(visitRow.visitType, 'visit');
    });

    test('persists observations when provided', () async {
      await sut.recordVisit(makeVisit(
        visitId: 'visit-obs',
        observations: 'Client was happy',
      ));

      final rows = await db.select(db.visitTable).get();
      expect(rows.first.observations, 'Client was happy');
    });

    test('persists null observations when not provided', () async {
      await sut.recordVisit(makeVisit(visitId: 'visit-no-obs'));

      final rows = await db.select(db.visitTable).get();
      expect(rows.first.observations, isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────
  // Scenario B2 — watchVisitsForStop reactive emission
  // ───────────────────────────────────────────────────────────────

  group('watchVisitsForStop', () {
    test('first emission contains 2 visits for stop-1, excludes stop-2',
        () async {
      await sut.recordVisit(makeVisit(
        visitId: 'v1',
        routeStopId: 'stop-1',
        arrivedAt: DateTime(2026, 6, 6, 9, 0),
      ));
      await sut.recordVisit(makeVisit(
        visitId: 'v2',
        routeStopId: 'stop-1',
        arrivedAt: DateTime(2026, 6, 6, 9, 30),
      ));
      await sut.recordVisit(makeVisit(
        visitId: 'v-other',
        routeStopId: 'stop-2',
      ));

      final first = await sut.watchVisitsForStop('stop-1').first;
      expect(first.length, 2);
      expect(first.every((v) => v.routeStopId == 'stop-1'), isTrue);
    });

    test('re-emits with 3 visits after inserting a third for stop-1', () async {
      await sut.recordVisit(makeVisit(
          visitId: 'v1', routeStopId: 'stop-1',
          arrivedAt: DateTime(2026, 6, 6, 9, 0)));
      await sut.recordVisit(makeVisit(
          visitId: 'v2', routeStopId: 'stop-1',
          arrivedAt: DateTime(2026, 6, 6, 9, 30)));

      final emissions = <List<Visit>>[];
      final sub = sut.watchVisitsForStop('stop-1').listen(emissions.add);
      addTearDown(sub.cancel);

      await Future.delayed(const Duration(milliseconds: 30));

      await sut.recordVisit(makeVisit(
          visitId: 'v3', routeStopId: 'stop-1',
          arrivedAt: DateTime(2026, 6, 6, 10, 0)));

      await Future.delayed(const Duration(milliseconds: 30));

      expect(emissions.last.length, 3);
    });

    test('emits empty list when no visits for the stop', () async {
      final first = await sut.watchVisitsForStop('stop-1').first;
      expect(first, isEmpty);
    });

    test('returned Visit objects have correct visitType mapped from text',
        () async {
      await sut.recordVisit(makeVisit(
        visitId: 'v-map',
        visitType: VisitType.visit,
      ));

      final first = await sut.watchVisitsForStop('stop-1').first;
      expect(first.first.visitType, VisitType.visit);
    });
  });
}

VisitRepository _buildSut(AppDatabase db) => DriftVisitRepository(db);
