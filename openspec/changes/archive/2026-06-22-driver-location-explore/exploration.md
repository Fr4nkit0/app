## Exploration: Driver Location, Geocoding, & Route Routing on Map

### Current State
- **Map Representation:** The app has an interactive `AddressPickerMap` (located in [address_picker_map.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart)) using `flutter_map` (v8.2.0) and OpenStreetMap tiles. It renders a single red marker for the selected customer coordinate pin.
- **Geocoding:** `GeocodingService` (located in [geocoding_service.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/geocoding_service.dart)) queries the Photon API (`https://photon.komoot.io/api/`) to translate search queries into coordinate pins.
- **Missing GPS Location:** The project currently lacks the `geolocator` package in `pubspec.yaml`, and no location permissions are declared in the Android Manifest (`AndroidManifest.xml`) or iOS plist metadata. There is no logic to fetch or display the driver's current position on the map.
- **Missing Route Tracing:** There is no integration with a routing service or polyline rendering. The map cannot draw a route path connecting the driver to the customer.

### Affected Areas
- [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml) — Needs the `geolocator: ^13.0.2` package added to dependencies.
- [AndroidManifest.xml](file:///home/frankito/projects/marilin/app/android/app/src/main/AndroidManifest.xml) — Needs `android.permission.ACCESS_FINE_LOCATION` and `android.permission.ACCESS_COARSE_LOCATION` permissions.
- [Info.plist](file:///home/frankito/projects/marilin/app/ios/Runner/Info.plist) — Needs keys `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` for iOS runtime location prompts.
- [address_picker_map.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) — Will be modified to:
  1. Initialize permission checks and fetch driver GPS location using `geolocator`.
  2. Add a blue marker layer for the driver's current coordinates.
  3. Query the OSRM routing API (`https://router.project-osrm.org/route/v1/driving/`) with coordinates format `lon1,lat1;lon2,lat2` to receive a routing geometry (GeoJSON LineString).
  4. Parse the GeoJSON coordinates from `[longitude, latitude]` array structures to `LatLng(latitude, longitude)`.
  5. Add a `PolylineLayer` to draw the route between the driver marker and the customer marker pin.
  6. Gracefully handle routing API timeouts/failures with direct-line visual fallbacks.

### Approaches
1. **On-Demand Single-Route Fetch (Foreground Only)** — Request the driver's current GPS location on map load, render it as a static blue marker, and query OSRM to draw the initial route to the customer pin. Re-query only when the customer's coordinate pin is explicitly changed (via manual tap or search result).
   - Pros: Low battery consumption, simple state lifecycle, prevents OSRM rate-limiting blocks.
   - Cons: The route does not dynamically update as the driver moves physically in real-time unless manually refreshed.
   - Effort: Low

2. **Real-Time Dynamic Routing Stream** — Establish a constant location updates stream using `Geolocator.getPositionStream` and dynamically request OSRM updates on every location change to keep the routing polyline updated.
   - Pros: Real-time turn-by-turn routing representation on the map.
   - Cons: High battery drain; risks OSRM public server rate limits (429 Too Many Requests) and IP blocks; complex state handling during active movement.
   - Effort: High

3. **Throttled Stream with Direct-Line Fallback** — Subscribe to the GPS stream but filter/throttle updates (e.g. recalculate only when driver moves >20m, and at most once every 5 seconds). If the OSRM server fails or rate-limits requests, fall back to rendering a straight dashed direct line between coordinates.
   - Pros: Balance of real-time awareness and resource management; high resilience against API failure or offline states.
   - Cons: Dashed line is not a roads-based route, but works as a fallback guide.
   - Effort: Medium

### Recommendation
- **Approach 3 (Throttled Stream with Direct-Line Fallback)** is highly recommended. It provides a modern dynamic routing feel as the driver moves, whilst mitigating the risks of public API rate limits (via throttling) and network connectivity drops (via physical direct-line fallback). We should implement a dedicated `OSRM` routing client (or extend `GeocodingService`) that fetches the route, parses the GeoJSON, and handles exceptions safely.

### Risks
- **OSRM API Rate Limiting & Failures:** OSRM's public server has no uptime guarantees and can rate-limit high-frequency traffic.
  - *Mitigation:* Limit calls using threshold distance filters and time throttling, and render a simple direct dashed path as fallback.
- **Internet Outages:** Drivers frequently lose signal in deep streets.
  - *Mitigation:* Ensure routing failures are silent warnings that do not crash the app, keeping existing pins and markers accessible.
- **Permission Rejection:** The driver may decline location permissions.
  - *Mitigation:* Fallback gracefully by omitting the driver marker and the route layer, permitting manual geocoding/pin selection as normal.

### Ready for Proposal
Yes — The technical details and file architectures needed to integrate Geolocator, permission handlers, OSRM API, and flutter_map PolylineLayer are clear. The orchestrator should proceed to the proposal phase.
