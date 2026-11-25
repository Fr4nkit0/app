import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

abstract class RouteRepository {
  Stream<List<RouteStop>> watchDayStops();
  Future<void> markStop(String id, StopStatus status);

  /// Marks [stopId] as rescheduled and adds a new pending stop of the same
  /// customer to the same route at [at], linked to it. Returns the new
  /// stop's id. Callers validate [at] (later the same day).
  Future<String> rescheduleStop(String stopId, DateTime at);

  /// Puts the stops of today's routes in the driver's order: each route
  /// numbers the listed stops of it first, in [orderedStopIds] order, then
  /// the rest in their current order, and queues the route's snapshot.
  /// Writes several rows: callers run it in a unit of work.
  Future<void> reorderDayStops(List<String> orderedStopIds);
}
