import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

abstract class RouteRepository {
  Stream<List<RouteStop>> watchDayStops();
  Future<void> markStop(String id, StopStatus status);
}
