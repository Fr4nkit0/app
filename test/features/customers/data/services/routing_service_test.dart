import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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

      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, '/map/route');
          expect(options.queryParameters['origin_lat'], start.latitude);
          expect(options.queryParameters['origin_lng'], start.longitude);
          expect(options.queryParameters['destination_lat'], end.latitude);
          expect(options.queryParameters['destination_lng'], end.longitude);

          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': mockResponse},
          ));
        },
      ));

      final service = RoutingService(dio);
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
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 429,
            data: 'Rate limit exceeded',
          ));
        },
      ));

      final service = RoutingService(dio);
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
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.reject(DioException(
            requestOptions: options,
            error: 'Network connection timed out',
          ));
        },
      ));

      final service = RoutingService(dio);
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
