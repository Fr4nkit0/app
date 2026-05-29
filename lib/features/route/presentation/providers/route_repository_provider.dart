import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/route/data/repositories/mock_route_repository.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';

final mockRouteRepositoryProvider =
    Provider<MockRouteRepository>((ref) => MockRouteRepository());

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return ref.watch(mockRouteRepositoryProvider);
});

final routeDayProvider = StreamProvider<List<RouteStop>>((ref) {
  return ref.watch(routeRepositoryProvider).watchDayStops();
});

final routeStopByIdProvider =
    Provider.family<RouteStop?, String>((ref, id) {
  return ref
      .watch(routeDayProvider)
      .value
      ?.where((s) => s.id == id)
      .firstOrNull;
});
