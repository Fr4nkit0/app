import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';

abstract class VisitRepository {
  Future<void> recordVisit(Visit visit);
  Stream<List<Visit>> watchVisitsForStop(String routeStopId);
  Stream<List<VisitOutcome>> watchOutcomes();

  /// The visit with [visitId], or null when it does not exist.
  Future<Visit?> findVisit(String visitId);

  /// The outcome with [id], enabled or not, or null when it does not exist.
  Future<VisitOutcome?> findOutcome(int id);

  /// Whether a sale that is not cancelled was recorded at the stop; sales
  /// carry the stop's id.
  Future<bool> stopHasSales(String routeStopId);

  /// Replaces the outcome and notes of the visit (null [observations] clears
  /// them), stamps [modifiedAt] and queues the edit for push.
  Future<void> editVisit(
    String visitId, {
    required int outcomeId,
    String? observations,
    required DateTime modifiedAt,
  });
}
