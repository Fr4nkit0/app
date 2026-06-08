import 'package:uuid/uuid.dart';

import 'package:app/core/utils/resource.dart';
import 'package:app/features/route/data/repositories/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';

class CompleteVisitUseCase {
  const CompleteVisitUseCase({
    required RouteRepository routeRepo,
    required VisitRepository visitRepo,
  })  : _routeRepo = routeRepo,
        _visitRepo = visitRepo;

  final RouteRepository _routeRepo;
  final VisitRepository _visitRepo;

  Future<Resource<void>> execute({
    required String stopId,
    required String customerId,
    required VisitType visitType,
    required StopStatus nextStatus,
    required String outcome,
    String? observations,
  }) async {
    try {
      // Step 1: record visit FIRST (spec F2 order).
      await _visitRepo.recordVisit(Visit(
        visitId: const Uuid().v4(),
        routeStopId: stopId,
        customerId: customerId,
        visitType: visitType,
        outcome: outcome,
        arrivedAt: DateTime.now(),
        observations: observations,
      ));

      // Step 2: mark stop ONLY if recordVisit succeeded.
      await _routeRepo.markStop(stopId, nextStatus);

      return const Resource.success(null);
    } on Exception catch (e) {
      return Resource.error(e);
    }
  }
}
