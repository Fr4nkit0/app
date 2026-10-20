import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';

abstract class VisitRepository {
  Future<void> recordVisit(Visit visit);
  Stream<List<Visit>> watchVisitsForStop(String routeStopId);
  Stream<List<VisitOutcome>> watchOutcomes();

  /// Catalog outcome used when a visit ends in a sale (no reschedule).
  Future<int?> findDeliveredOutcomeId();
}
