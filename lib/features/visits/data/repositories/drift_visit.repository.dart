import 'package:drift/drift.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

class DriftVisitRepository implements VisitRepository {
  DriftVisitRepository(AppDatabase db)
    : _db = db,
      _queue = DriftPendingChangeRepository(db);

  final AppDatabase _db;
  final PendingChangeRepository _queue;

  @override
  Future<void> recordVisit(Visit v) async {
    await _db.transaction(() async {
      await _db
          .into(_db.visitTable)
          .insert(
            VisitTableCompanion.insert(
              visitId: Value(v.visitId),
              routeStopId: v.routeStopId,
              customerId: v.customerId,
              visitType: v.visitType.name,
              outcomeId: Value(v.outcomeId),
              arrived_at: v.arrivedAt,
              observations: Value(v.observations),
              amountCollected: Value(v.amountCollected),
            ),
          );

      await _queue.enqueue(
        entity: PendingEntity.visit,
        entityId: v.visitId,
        action: PendingAction.insert,
        payload: {
          'visitId': v.visitId,
          'routeStopId': v.routeStopId,
          'customerId': v.customerId,
          'visitType': v.visitType.name,
          'outcomeId': v.outcomeId,
          'arrivedAt': v.arrivedAt.toIso8601String(),
          'observations': v.observations,
          'amountCollected': v.amountCollected,
        },
      );
    });
  }

  @override
  Stream<List<Visit>> watchVisitsForStop(String routeStopId) {
    return (_db.select(_db.visitTable)
          ..where((t) => t.routeStopId.equals(routeStopId))
          ..orderBy([(t) => OrderingTerm.desc(t.arrived_at)]))
        .watch()
        .map((rows) => rows.map(_rowToVisit).toList());
  }

  @override
  Stream<List<VisitOutcome>> watchOutcomes() {
    return (_db.select(_db.visitOutcomeTable)
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map(
          (rows) => [
            for (final r in rows)
              VisitOutcome(
                id: r.id,
                name: r.name,
                triggersReschedule: r.triggersReschedule,
              ),
          ],
        );
  }

  Visit _rowToVisit(VisitTableData row) => Visit(
    visitId: row.visitId,
    routeStopId: row.routeStopId,
    customerId: row.customerId,
    visitType: VisitType.values.firstWhere(
      (e) => e.name == row.visitType,
      orElse: () => VisitType.visit,
    ),
    outcomeId: row.outcomeId,
    arrivedAt: row.arrived_at,
    observations: row.observations,
    amountCollected: row.amountCollected,
  );
}
