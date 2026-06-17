import 'package:app/features/visits/domain/models/visit.dart';

abstract class VisitRepository {
  Future<void> recordVisit(Visit visit);
  Stream<List<Visit>> watchVisitsForStop(String routeStopId);
}
