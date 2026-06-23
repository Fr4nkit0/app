import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class RoutingRoute {
  final double distance;
  final double duration;
  final List<LatLng> points;
  final String? error;
  final bool isFallback;

  RoutingRoute({
    required this.distance,
    required this.duration,
    required this.points,
    this.error,
    this.isFallback = false,
  });
}

class RoutingService {
  final http.Client _client;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  /// Requests a driving route between start and end coordinates.
  /// Falls back to straight line on timeout or exception.
  Future<RoutingRoute> getRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${start.longitude},${start.latitude};${end.longitude},${end.latitude}'
      '?geometries=geojson&overview=full',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'MarilinApp/1.0 (com.marilin.app)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final data = json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        throw Exception('No route found in OSRM response');
      }

      final routeData = routes.first as Map<String, dynamic>;
      final distance = (routeData['distance'] as num).toDouble();
      final duration = (routeData['duration'] as num).toDouble();

      final geometry = routeData['geometry'] as Map<String, dynamic>?;
      if (geometry == null) {
        throw Exception('No geometry found in OSRM route');
      }

      final coordinates = geometry['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) {
        throw Exception('No coordinates found in OSRM geometry');
      }

      final points = coordinates.map((coords) {
        final double lon = (coords[0] as num).toDouble();
        final double lat = (coords[1] as num).toDouble();
        return LatLng(lat, lon);
      }).toList();

      return RoutingRoute(
        distance: distance,
        duration: duration,
        points: points,
        isFallback: false,
      );
    } catch (e) {
      // Calculate geodesic straight-line fallback using Geolocator
      final distance = Geolocator.distanceBetween(
        start.latitude,
        start.longitude,
        end.latitude,
        end.longitude,
      );
      // Average city routing speed is 30 km/h = 8.33 m/s
      final duration = distance / 8.33;

      return RoutingRoute(
        distance: distance,
        duration: duration,
        points: [start, end],
        isFallback: true,
        error: e.toString(),
      );
    }
  }
}

final routingServiceProvider = Provider<RoutingService>((ref) {
  return RoutingService();
});

