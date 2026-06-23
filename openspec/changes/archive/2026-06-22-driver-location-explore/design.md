# Technical Design: Driver Location Tracking & Route Estimation

This document defines the technical design and architectural decisions for implementing foreground GPS tracking, route rendering using the public OSRM API, and interactive temporary destination drag estimation on the embedded map in the Marilin application.

## References
- Proposal: [proposal.md](file:///home/frankito/projects/marilin/app/openspec/changes/driver-location-explore/proposal.md)
- Specification: [spec.md](file:///home/frankito/projects/marilin/app/openspec/specs/driver-location/spec.md)

---

## 1. Technical Approach

### 1.1. Foreground GPS Location Tracking
We will integrate the `geolocator` package to access physical GPS location. The tracking lifecycle is bound entirely to the foreground execution of the map widget:
1. **Permission Check & Request:** When the map screen initializes, it checks for location permissions. If not granted, it prompts the user.
2. **Current Position Lookup:** If permissions are granted, the initial location is fetched to center the map (if no pre-existing customer coordinates exist).
3. **Location Stream Subscription:** A foreground position stream subscription is established. The stream listener updates the local UI state with the driver's current position, represented by a blue marker.
4. **Lifecycle Cleanup:** The stream subscription is cancelled in `dispose` to prevent memory leaks and battery drain.

### 1.2. Route Tracing using OSRM Routing Service
We will query the public Open Source Routing Machine (OSRM) API:
- **Base Endpoint:** `https://router.project-osrm.org/route/v1/driving/`
- **Request Format:** `https://router.project-osrm.org/route/v1/driving/{start_lon},{start_lat};{end_lon},{end_lat}?geometries=geojson&overview=full`
- **Response Format:** GeoJSON LineString containing coordinates ordered as `[longitude, latitude]`. We parse these coordinates, reverse them to `[latitude, longitude]`, and map them to `List<LatLng>` for rendering.

### 1.3. Resilient Fallback (Straight-Line & Custom Estimates)
If OSRM requests fail (due to rate-limiting, network issues, or timeouts):
- The system will catch the exception, log the warning, and show a temporary banner or tooltip informing the user.
- The map fallback displays a straight dashed line between the driver and customer pins.
- **Estimated Calculations:**
  - **Distance:** Computed using `Geolocator.distanceBetween(lat1, lon1, lat2, lon2)` (in meters).
  - **Duration:** Estimated using a sensible city routing speed average (e.g., 30 km/h or `8.33 m/s`), calculated as:
    $$\text{duration (seconds)} = \frac{\text{distance (meters)}}{8.33}$$

---

## 2. Architecture Decisions

### 2.1. Single Responsibility Principle (SRP): Routing Service
We will create a separate `RoutingService` class rather than adding routing methods to `GeocodingService`.
- **Rationale:** Geocoding (Photon API) and Routing (OSRM API) have completely different API endpoints, parameters, model classes, and failure modes. Keeping them separate prevents the geocoding module from becoming bloated and violating SRP.

### 2.2. State Management: Local UI State vs. Global Providers
The coordinate changes from pin-dragging are purely interactive and transient (not saved to the database on this screen).
- **Rationale:** We will keep the temporary coordinates and route calculations as local UI state within `_AddressPickerMapState`. This avoids unnecessary global state pollution and makes the cleanup simple since the state is destroyed when the widget is popped.
- A stateless Riverpod `Provider<RoutingService>` is registered to expose the service instance to the widget tree.

### 2.3. Throttling and Polling Strategy for Location & Routing Updates
To prevent OSRM server rate limiting (HTTP 429) and optimize battery/network resource usage:
1. **GPS Distance Filtering:** The `Geolocator.getPositionStream` will be initialized with a `distanceFilter` of 20 meters.
2. **Time Throttling:** The routing recalculation will keep track of `_lastRoutingRequestTime`. It will not call OSRM unless at least 5 seconds have passed since the last request.
3. **Pin-Drag Debouncing:** When the customer pin is dragged, routing requests will be debounced (e.g., waiting 500ms after the drag stops or using a debounced update during drag) to prevent rapid consecutive API requests.

---

## 3. Data Flow Representation

```
                    +-----------------------------+
                    | Geolocator Position Stream  | (Distance Filter: 20m)
                    +--------------+--------------+
                                   |
                                   v  (Driver Location Update)
+------------------+  +------------v----------------+  +------------------+
| Customer Drag    |  |                             |  | Map Initial Load |
| / Tap Gesture    |  |   AddressPickerMap State    |  | (Permissions Ok) |
+--------+---------+  +------------+----------------+  +--------+---------+
         |                         |                            |
         | (Target Updated)        | (Checks Throttle:          | (Initial Setup)
         |                         |  Time > 5s)                |
         +------------------------>+<---------------------------+
                                   |
                                   v
                      +------------+------------+
                      |  RoutingService.getRoute  |
                      +------------+------------+
                                   |
                     +-------------+-------------+
                     |                           |
                     v (Try OSRM Request)        v (Catch Failure/Timeout)
            +--------+---------+        +--------+---------+
            |  Query OSRM API  |        |   Local Geodesic  |
            |  (GeoJSON Route) |        |    Calculation   |
            +--------+---------+        +--------+---------+
                     |                           |
                     | (List<LatLng>)            | (Direct [Start, End])
                     v                           v
            +--------+---------------------------+---------+
            |  Update Map Polyline & Info Panel Display   |
            +---------------------------------------------+
```

---

## 4. Detailed File Changes

| File Path | Action | Description |
|-----------|--------|-------------|
| [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml) | Modify | Add `geolocator: ^13.0.2` under `dependencies`. |
| [AndroidManifest.xml](file:///home/frankito/projects/marilin/app/android/app/src/main/AndroidManifest.xml) | Modify | Declare `android.permission.ACCESS_FINE_LOCATION` and `android.permission.ACCESS_COARSE_LOCATION`. |
| [Info.plist](file:///home/frankito/projects/marilin/app/ios/Runner/Info.plist) | Modify | Add `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` keys. |
| [routing_service.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/routing_service.dart) | Create | Define `RoutingRoute` model, `RoutingService` client, and `routingServiceProvider`. |
| [address_picker_map.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) | Modify | Integrate Geolocator permissions, driver position stream, routing polyline drawing, fallback UI alerts, and customer marker draggable behavior. |

---

## 5. Interface & Model Contracts

### 5.1. Model: `RoutingRoute`
```dart
import 'package:latlong2/latlong.dart';

class RoutingRoute {
  final double distance;     // Distance in meters
  final double duration;     // Duration in seconds
  final List<LatLng> points; // Decoded coordinate list
  final String? error;       // Error message if routing failed
  final bool isFallback;     // True if utilizing direct-line calculations

  RoutingRoute({
    required this.distance,
    required this.duration,
    required this.points,
    this.error,
    this.isFallback = false,
  });
}
```

### 5.2. Service: `RoutingService`
```dart
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoutingService {
  final http.Client _client;

  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  /// Requests a driving route between start and end coordinates.
  /// Falls back to straight line on timeout or exception.
  Future<RoutingRoute> getRoute(LatLng start, LatLng end) async {
    // Implementation fetches from:
    // https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full
  }
}

final routingServiceProvider = Provider<RoutingService>((ref) {
  return RoutingService();
});
```

---

## 6. Dragging Gesture Conversion Logic

In `AddressPickerMap`, coordinates conversion during dragging is achieved using the `MapController`'s projection utilities. We wrap the customer `Marker`'s child in a `GestureDetector`:

```dart
Marker(
  point: _selectedLatLng!,
  width: 60.0,
  height: 60.0,
  alignment: Alignment.topCenter,
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onPanUpdate: (details) {
      final mapRenderBox = mapKey.currentContext!.findRenderObject() as RenderBox;
      final localPoint = mapRenderBox.globalToLocal(details.globalPosition);
      final latLng = _mapController.camera.pointToLatLng(Point(localPoint.dx, localPoint.dy));
      
      setState(() {
        _selectedLatLng = latLng;
      });
      
      _debouncedRecalculateRoute();
    },
    child: const Icon(
      Icons.location_on,
      color: Colors.red,
      size: 40.0,
    ),
  ),
)
```

---

## 7. Testing Strategy

### 7.1. Unit Testing `RoutingService`
- **Mock http.Client:** Test API query responses using `http/testing`'s `MockClient`.
- **Success Case:** Parse standard OSRM response JSON, verifying decoded `LatLng` array structures and route distance/duration mapping.
- **Timeout/Error Case:** Verify that connection failure, HTTP 429, or HTTP 500 responses return a `RoutingRoute` flagged as `isFallback = true` with geodesic calculation values.

### 7.2. Widget & State Testing
- **Widget Test Map Rendering:** Verify `AddressPickerMap` accurately renders:
  - Blue marker at driver coordinates.
  - Red marker at customer coordinates.
  - `PolylineLayer` matching parsed route points.
  - Interactive distance and duration card displaying converted miles/meters and minutes.
- **Provider Overrides:** Override `routingServiceProvider` in tests using a mock service that returns constant routes to avoid dependency on the live network API.
