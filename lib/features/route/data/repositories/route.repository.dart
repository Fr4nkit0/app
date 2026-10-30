import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

abstract class RouteRepository {
  Stream<List<RouteStop>> watchDayStops();
  Future<void> markStop(String id, StopStatus status);

  /// Marks [stopId] as rescheduled and adds a new pending stop of the same
  /// customer to the same route at [at], linked to it. Returns the new
  /// stop's id. Callers validate [at] (later the same day).
  Future<String> rescheduleStop(String stopId, DateTime at);
}
