import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/features/customers/data/services/routing_service.dart';

void main() {
  group('RoutingService Tests', () {
    final start = LatLng(-24.789124, -65.411624); // Salta, Argentina
    final end = LatLng(-24.795000, -65.405000);

    test('should parse OSRM response successfully and reverse coordinates', () async {
      final mockResponse = {
        'routes': [
          {
            'distance': 1500.5,
            'duration': 180.0,
            'geometry': {
              'type': 'LineString',
              'coordinates': [
                [-65.411624, -24.789124],
                [-65.405000, -24.795000]
              ]
            }
          }
        ]
      };

      final mockClient = MockClient((request) async {
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'router.project-osrm.org');
        expect(request.url.path, '/route/v1/driving/-65.411624,-24.789124;-65.405,-24.795');
        expect(request.url.queryParameters['geometries'], 'geojson');
        expect(request.url.queryParameters['overview'], 'full');

        return http.Response(json.encode(mockResponse), 200);
      });

      final service = RoutingService(client: mockClient);
      final route = await service.getRoute(start, end);

      expect(route.isFallback, isFalse);
      expect(route.distance, 1500.5);
      expect(route.duration, 180.0);
      expect(route.points, hasLength(2));
      expect(route.points[0].latitude, -24.789124);
      expect(route.points[0].longitude, -65.411624);
      expect(route.points[1].latitude, -24.795000);
      expect(route.points[1].longitude, -65.405000);
      expect(route.error, isNull);
    });

    test('should fallback to straight line calculation on HTTP error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });

      final service = RoutingService(client: mockClient);
      final route = await service.getRoute(start, end);

      expect(route.isFallback, isTrue);
      expect(route.distance, isPositive);
      expect(route.duration, isPositive);
      expect(route.points, hasLength(2));
      expect(route.points[0], start);
      expect(route.points[1], end);
      expect(route.error, contains('HTTP error 429'));
    });

    test('should fallback to straight line calculation on exception or timeout', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network connection timed out');
      });

      final service = RoutingService(client: mockClient);
      final route = await service.getRoute(start, end);

      expect(route.isFallback, isTrue);
      expect(route.distance, isPositive);
      expect(route.duration, isPositive);
      expect(route.points, hasLength(2));
      expect(route.points[0], start);
      expect(route.points[1], end);
      expect(route.error, contains('Network connection timed out'));
    });
  });
}
