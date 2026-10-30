import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/visits/data/repositories/drift_visit.repository.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/usecases/edit_visit.usecase.dart';

/// Writes the edit, then fails before the unit of work ends.
class _FailingAfterEditRepository implements VisitRepository {
  _FailingAfterEditRepository(this._inner);

  final VisitRepository _inner;

  @override
  Future<void> editVisit(
    String visitId, {
    required int outcomeId,
    String? observations,
    required DateTime modifiedAt,
  }) async {
    await _inner.editVisit(
      visitId,
      outcomeId: outcomeId,
      observations: observations,
      modifiedAt: modifiedAt,
    );
    throw Exception('Simulated failure after the edit');
  }

  @override
  Future<Visit?> findVisit(String visitId) => _inner.findVisit(visitId);

  @override
  Future<VisitOutcome?> findOutcome(int id) => _inner.findOutcome(id);

  @override
  Future<bool> stopHasSales(String routeStopId) =>
      _inner.stopHasSales(routeStopId);

  @override
  Future<void> recordVisit(Visit visit) => _inner.recordVisit(visit);

  @override
  Stream<List<Visit>> watchVisitsForStop(String routeStopId) =>
      _inner.watchVisitsForStop(routeStopId);

  @override
  Stream<List<VisitOutcome>> watchOutcomes() => _inner.watchOutcomes();
}

void main() {
  late AppDatabase db;
  late DriftVisitRepository visits;
  late PendingChangeRepository queue;
  late EditVisitUseCase sut;

  final now = DateTime(2026, 10, 29, 11);

  EditVisitUseCase useCase(VisitRepository repo) => EditVisitUseCase(
    visitRepo: repo,
    transaction: driftTransactionRunner(db),
    now: () => now,
  );

  Future<void> outcome(int id, String name, {bool reschedule = false}) => db
      .into(db.visitOutcomeTable)
      .insert(
        VisitOutcomeTableCompanion.insert(
          id: drift.Value(id),
          name: name,
          triggersReschedule: drift.Value(reschedule),
        ),
      );

  Future<void> recordVisit({
    int outcomeId = 2,
    DateTime? arrivedAt,
    VisitType type = VisitType.visit,
  }) => visits.recordVisit(
    Visit(
      visitId: 'v-1',
      routeStopId: 's-1',
      customerId: 'c-1',
      visitType: type,
      outcomeId: outcomeId,
      arrivedAt: arrivedAt ?? DateTime(2026, 10, 29, 10),
      observations: 'Tocar timbre',
    ),
  );

  Future<VisitTableData> row() => db.select(db.visitTable).getSingle();

  Future<List<PendingChange>> updates() async => [
    for (final c in await queue.getPending())
      if (c.entity == PendingEntity.visit && c.action == PendingAction.update)
        c,
  ];

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    visits = DriftVisitRepository(db);
    queue = DriftPendingChangeRepository(db);
    sut = useCase(visits);
    await outcome(1, 'Ausente');
    await outcome(2, 'No quiso');
    await outcome(3, 'Reprogramar', reschedule: true);
  });
  tearDown(() => db.close());

  test('changes the outcome and notes and queues one visit update', () async {
    await recordVisit();

    await sut.execute(visitId: 'v-1', outcomeId: 1, notes: 'No estaba');

    final visit = await row();
    expect(visit.outcomeId, 1);
    expect(visit.observations, 'No estaba');
    expect(visit.lastModifiedDate, now);
    final queued = await updates();
    expect(queued, hasLength(1));
    expect(queued.single.entityId, 'v-1');
  });

  test('null notes clear them', () async {
    await recordVisit();

    await sut.execute(visitId: 'v-1', outcomeId: 2);

    expect((await row()).observations, isNull);
  });

  test('a failure inside the unit of work changes nothing', () async {
    await recordVisit();

    await expectLater(
      useCase(
        _FailingAfterEditRepository(visits),
      ).execute(visitId: 'v-1', outcomeId: 1, notes: 'No estaba'),
      throwsException,
    );

    final visit = await row();
    expect(visit.outcomeId, 2);
    expect(visit.observations, 'Tocar timbre');
    expect(await updates(), isEmpty);
  });

  group('rejects with a ValidationFailure and changes nothing', () {
    Future<void> expectRejected({int outcomeId = 1}) async {
      await expectLater(
        sut.execute(visitId: 'v-1', outcomeId: outcomeId, notes: 'x'),
        throwsA(isA<ValidationFailure>()),
      );
      expect((await row()).observations, 'Tocar timbre');
      expect(await updates(), isEmpty);
    }

    test('a visit with a sale', () async {
      await recordVisit();
      await db
          .into(db.saleTable)
          .insert(
            SaleTableCompanion.insert(
              customerId: 'c-1',
              totalAmount: 100,
              paymentMethod: 'cash',
              quantity: 1,
              shipping_amount: 0,
              visitId: const drift.Value('s-1'),
            ),
          );

      await expectRejected();
    });

    test('a visit of another day', () async {
      await recordVisit(arrivedAt: DateTime(2026, 10, 28, 18));

      await expectRejected();
    });

    test('a rescheduled visit', () async {
      await recordVisit(outcomeId: 3);

      await expectRejected();
    });

    test('a change to the reschedule outcome', () async {
      await recordVisit();

      await expectRejected(outcomeId: 3);
    });
  });

  test('an unknown visit is not found', () async {
    await expectLater(
      sut.execute(visitId: 'nope', outcomeId: 1),
      throwsA(isA<NotFoundFailure>()),
    );
  });
}
