import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:app/features/customers/presentation/widgets/address_picker_map.dart';
import 'package:app/features/customers/data/services/routing_service.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    return Position(
      latitude: -24.789000,
      longitude: -65.411000,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 1.0,
      heading: 1.0,
      speed: 1.0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Stream.value(
      Position(
        latitude: -24.789000,
        longitude: -65.411000,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 1.0,
        heading: 1.0,
        speed: 1.0,
        speedAccuracy: 1.0,
        altitudeAccuracy: 1.0,
        headingAccuracy: 1.0,
      ),
    );
  }
}

class FakeRoutingService extends RoutingService {
  final RoutingRoute result;
  FakeRoutingService(this.result);

  @override
  Future<RoutingRoute> getRoute(LatLng start, LatLng end) async {
    return result;
  }
}

void main() {
  setUp(() {
    GeolocatorPlatform.instance = MockGeolocatorPlatform();
  });

  Widget wrapWithScope(Widget child, List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('AddressPickerMap Widget Tests', () {
    testWidgets('renders search bar and instructions', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithScope(
          const AddressPickerMap(
            initialLatitude: -24.789124,
            initialLongitude: -65.411624,
          ),
          [],
        ),
      );

      // Verify instruction text is visible
      expect(find.textContaining('Arrastrá el pin rojo o tocá el mapa'), findsOneWidget);
      // Verify search input placeholder is visible
      expect(find.textContaining('Buscar dirección'), findsOneWidget);
      // Verify confirm button is active
      expect(find.text('Cerrar / Volver'), findsOneWidget);
    });

    testWidgets('displays OSRM route distance and ETA on bottom panel', (WidgetTester tester) async {
      final fakeRoute = RoutingRoute(
        distance: 1200.0, // 1.2 km
        duration: 180.0,  // 3 min
        points: [
          LatLng(-24.789000, -65.411000),
          LatLng(-24.789124, -65.411624),
        ],
        isFallback: false,
      );

      await tester.pumpWidget(
        wrapWithScope(
          const AddressPickerMap(
            initialLatitude: -24.789124,
            initialLongitude: -65.411624,
          ),
          [
            routingServiceProvider.overrideWithValue(FakeRoutingService(fakeRoute)),
          ],
        ),
      );

      // Let the Geolocator initialize and route call complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Verify route info on bottom card
      expect(find.text('1.2 km'), findsOneWidget);
      expect(find.text('3 min'), findsOneWidget);
      expect(find.text('Distancia de ruta'), findsOneWidget);
    });

    testWidgets('displays fallback straight line warnings when OSRM fails', (WidgetTester tester) async {
      final fallbackRoute = RoutingRoute(
        distance: 500.0,
        duration: 60.0,
        points: [
          LatLng(-24.789000, -65.411000),
          LatLng(-24.789124, -65.411624),
        ],
        isFallback: true,
        error: 'OSRM server error',
      );

      await tester.pumpWidget(
        wrapWithScope(
          const AddressPickerMap(
            initialLatitude: -24.789124,
            initialLongitude: -65.411624,
          ),
          [
            routingServiceProvider.overrideWithValue(FakeRoutingService(fallbackRoute)),
          ],
        ),
      );

      // Let the Geolocator initialize and route call complete
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Verify route info with fallback layout on bottom card
      expect(find.text('500 m'), findsOneWidget);
      expect(find.text('1 min'), findsOneWidget);
      expect(find.text('Distancia lineal'), findsOneWidget);
      expect(find.textContaining('Ruta de red no disponible'), findsOneWidget);
    });
  });
}
