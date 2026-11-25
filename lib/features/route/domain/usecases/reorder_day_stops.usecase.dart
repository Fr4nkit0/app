import 'package:app/core/usecases/transaction_runner.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';

/// The driver puts today's stops in the order of the day's pile. The new
/// order is stored and queued in one unit of work, so it works offline and
/// travels with the next sync.
class ReorderDayStopsUseCase {
  const ReorderDayStopsUseCase({
    required RouteRepository routeRepo,
    required TransactionRunner transaction,
  }) : _routeRepo = routeRepo,
       _transaction = transaction;

  final RouteRepository _routeRepo;
  final TransactionRunner _transaction;

  /// [orderedStopIds] lists the stops in the driver's order; stops of the
  /// route left out keep their place after them.
  Future<void> execute(List<String> orderedStopIds) =>
      _transaction(() => _routeRepo.reorderDayStops(orderedStopIds));
}
