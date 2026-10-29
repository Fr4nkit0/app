import 'package:uuid/uuid.dart';

import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/route/data/repositories/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/data/repositories/visit.repository.dart';
import 'package:app/features/visits/domain/models/visit.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/domain/reschedule_time.dart';

Future<T> _noTransaction<T>(Future<T> Function() action) => action();

class CompleteVisitUseCase {
  const CompleteVisitUseCase({
    required RouteRepository routeRepo,
    required VisitRepository visitRepo,
    TransactionRunner transaction = _noTransaction,
    DateTime Function() now = DateTime.now,
  }) : _routeRepo = routeRepo,
       _visitRepo = visitRepo,
       _transaction = transaction,
       _now = now;

  final RouteRepository _routeRepo;
  final VisitRepository _visitRepo;
  final TransactionRunner _transaction;
  final DateTime Function() _now;

  /// Records the visit and closes its stop with [nextStatus], or, with
  /// [rescheduleAt], marks the stop rescheduled and adds a new stop at that
  /// time, which must be later the same day ([RescheduleTimeException]).
  Future<Resource<void>> execute({
    required String stopId,
    required String customerId,
    required VisitType visitType,
    required StopStatus nextStatus,
    int? outcomeId,
    String? observations,
    DateTime? rescheduleAt,
  }) async {
    try {
      final now = _now();
      if (rescheduleAt != null) {
        final error = checkRescheduleTime(now: now, at: rescheduleAt);
        if (error != null) throw RescheduleTimeException(error);
      }

      await _transaction(() async {
        // Step 1: record visit FIRST (spec F2 order).
        await _visitRepo.recordVisit(
          Visit(
            visitId: const Uuid().v4(),
            routeStopId: stopId,
            customerId: customerId,
            visitType: visitType,
            // Outcomes explain a visit without sale; a sale carries none.
            outcomeId: outcomeId,
            arrivedAt: now,
            observations: observations,
          ),
        );

        // Step 2: close the stop ONLY if recordVisit succeeded.
        if (rescheduleAt != null) {
          await _routeRepo.rescheduleStop(stopId, rescheduleAt);
        } else {
          await _routeRepo.markStop(stopId, nextStatus);
        }
      });

      return const Resource.success(null);
    } on Exception catch (e) {
      return Resource.error(e);
    }
  }
}
