# Tasks: Driver Location Tracking & Route Estimation

## Review Workload Forecast

Estimated changed lines: 300-350 lines (Low risk)
400-line budget risk: Low
Chained PRs recommended: No
Delivery strategy: ask-on-risk (explicitly waived by user for this session)
Decision needed before apply: No
Chain strategy: stacked-to-main

---

## Implementation Tasks

### Phase 1: Foundation (dependencies and config)
- [x] Add `geolocator: ^13.0.2` to [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml) dependencies.
- [x] Add `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions to [AndroidManifest.xml](file:///home/frankito/projects/marilin/app/android/app/src/main/AndroidManifest.xml).
- [x] Add `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` to [Info.plist](file:///home/frankito/projects/marilin/app/ios/Runner/Info.plist).

### Phase 2: Core Service (routing service)
- [x] Create `RoutingRoute` model and `RoutingService` class in [routing_service.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/routing_service.dart).
- [x] Connect OSRM routing client and support GeoJSON coordinate parsing (reversing lon,lat to `LatLng`).
- [x] Expose `RoutingService` via a riverpod provider: `routingServiceProvider`.
- [x] Implement a straight-line fallback in `RoutingService` if the network request fails or OSRM is offline.

### Phase 3: UI Integration (map updates)
- [x] Update `AddressPickerMap` widget in [address_picker_map.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) to initialize `Geolocator` permission checks and request driver coordinates.
- [x] Set up location stream with `distanceFilter` of 20 meters and time-based throttling (5 seconds) to trigger routing updates.
- [x] Render driver blue marker and routing polyline on the map.
- [x] Enable customer `Marker` dragging with `MapController` projection coordinates estimation, update distance/ETA in the UI without modifying database coordinates.
- [x] Show fallback dashed straight-line if OSRM queries fail/timeout.

### Phase 4: Testing & Verification
- [x] Test: Verify `RoutingService` parses OSRM responses and handles timeouts/exceptions via local geodesic computation.
- [x] Test: Verify widget updates: driver blue marker, customer red marker, polyline, and distance/ETA panel.
