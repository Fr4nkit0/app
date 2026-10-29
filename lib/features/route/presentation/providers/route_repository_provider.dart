import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/route/data/repositories/drift_route_repository.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

final routeRepositoryProvider = Provider<RouteRepository>(
  (ref) => DriftRouteRepository(ref.watch(databaseProvider)),
);

/// A modern Notifier to manage the visible items page limit (Riverpod 3.x compatible)
class RoutePaginationLimit extends Notifier<int> {
  @override
  int build() => 10;

  void increment(int value) {
    state = state + value;
  }

  void reset() {
    state = 10;
  }
}

/// Controls the current page limit for stops list visualization
final routePaginationLimitProvider =
    NotifierProvider<RoutePaginationLimit, int>(RoutePaginationLimit.new);

/// Exposes the complete unpaginated list of stops for the day (ideal for global stats/progress)
final routeAllStopsProvider = StreamProvider<List<RouteStop>>((ref) {
  return ref.watch(routeRepositoryProvider).watchDayStops();
});

/// Exposes the total number of stops available for the day in real-time
final routeTotalStopsCountProvider = StreamProvider<int>((ref) {
  return ref
      .watch(routeRepositoryProvider)
      .watchDayStops()
      .map((list) => list.length);
});

/// Exposes the reactive list of day stops sliced by the current pagination limit
final routeDayProvider = StreamProvider<List<RouteStop>>((ref) {
  final limit = ref.watch(routePaginationLimitProvider);
  return ref.watch(routeRepositoryProvider).watchDayStops().map((list) {
    return list.take(limit).toList();
  });
});

final routeStopByIdProvider = Provider.family<RouteStop?, String>((ref, id) {
  return ref
      .watch(routeAllStopsProvider)
      .value
      ?.where((s) => s.id == id)
      .firstOrNull;
});

/// First pending stop of the day, in the order of [routeAllStopsProvider].
/// Null when nothing is pending or the list has not loaded yet.
final nextStopProvider = Provider<RouteStop?>((ref) {
  final stops = ref.watch(routeAllStopsProvider).value;
  return stops?.where((s) => s.status == StopStatus.pending).firstOrNull;
});
