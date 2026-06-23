## Exploration: Address Mapping and Geocoding in Marilin
### Current State
The system stores customer addresses in the `customer_addresses` table (`lib/features/customers/data/database/customer.address.table.dart`) with simple textual fields: `street`, `apartment`, `floor`, and `visualReference`. It references the customer using `customerId`. The route planning and stop tracking features (such as `RouteStopTable`) refer to these addresses via `customerAddressId` but have no concept of geographic coordinates (latitude/longitude). Addresses in the region are often unstructured, referring to block and lot identifiers (e.g., "Manzana 488 A Lote 9") rather than traditional streets and house numbers. There is currently no map interface or geocoding implementation in the app.

### Affected Areas
- `pubspec.yaml` — Needs new mapping packages (`flutter_map` (8.2.1), `latlong2` (0.9.1), and `geocoding` (4.0.0), and an HTTP client package like `http` or `dio` if needed to query OSM Nominatim/Photon API).
- `lib/features/customers/data/database/customer.address.table.dart` — Needs schema changes to add columns for `latitude` (real), `longitude` (real), and optionally structured fields like `block` (manzana) and `lot` (lote).
- `lib/core/services/database.helper.dart` — Needs to increment the `schemaVersion` (from 3 to 4) and implement the schema migration path in `onUpgrade`.
- `lib/features/customers/presentation/screens/create_customer_screens.dart` — UI needs updates to support address creation with mapping coordinates, searching locations, and manual calibration.
- `lib/features/customers/presentation/screens/customer_profile_screen.dart` — UI needs updates to show/edit the customer address on an embedded map.
- `lib/features/route/presentation/screens/route_day_screen.dart` — Can be extended to display an embedded map showing route stops.

### Approaches
1. **Embedded Leaflet-style Map (`flutter_map`) + OpenStreetMap Tiles + Nominatim/Photon API with Manual Map Calibration (Recommended)** — Implement an inline, embedded interactive map using `flutter_map` and OpenStreetMap tiles. Address search will be performed using OSM-based geocoding APIs (like Nominatim or Photon) which index block/manzana structures mapped by the community in Argentina. Since some blocks/lots may not be mapped, the UI will provide a drag-and-drop marker functionality for manual calibration/fine-tuning. Coordinates are saved directly to the database.
   - Pros:
     - Keeps the user completely inside the app (embedded UI), matching the Material 3 design and Flutter/Riverpod environment.
     - Supports search queries with block/manzana and lot/lote because OpenStreetMap has a rich community mapping index for these structures in Argentina.
     - Manual calibration (dragging the marker) solves the edge case where a new block/lot is not yet mapped in OSM.
     - Works across Android, iOS, and Web.
   - Cons:
     - Public geocoding APIs have rate/usage limits; high usage might require a paid provider or hosting a private Photon instance.
     - Higher development effort to implement maps, custom geocoding services, and drag-and-drop marker interactions.
   - Effort: Medium

2. **Native App Launching / OsmAnd App Integration** — Use standard platform intents (`geo:` URI scheme) or the `map_launcher` package to launch external maps (such as OsmAnd or Google Maps) to perform navigation or search.
   - Pros:
     - Extremely simple to implement (just launch an external URL).
     - OsmAnd handles offline searches and has a pre-built navigation engine.
   - Cons:
     - Leaves the application entirely (poor user experience, user explicitly requested an embedded solution).
     - No two-way communication: we cannot easily get coordinates back from external apps to save them in our database.
     - Custom styling or overlays (like route stop sequences) cannot be shown inside our app.
   - Effort: Low

### Recommendation
Approach 1 is highly recommended. It fulfills the requirement of having a fully embedded map inside the Flutter application. By querying Nominatim/Photon (OpenStreetMap's geocoder), the app can resolve "manzana/lote" addresses that are mapped in OpenStreetMap. Combining this with a manual drag-and-drop marker calibration feature provides a robust fallback so that operators can pinpoint any address and save the exact coordinates (`latitude` and `longitude`) directly to the Drift database.

### Risks
- **OSM Data Coverage:** In some newer or rural neighborhoods, the specific manzana/lote might not be mapped in OpenStreetMap yet. This is mitigated by the manual map calibration fallback.
- **Geocoding API Rate Limits:** Using free Nominatim/Photon endpoints has strict rate limits. Mitigated by caching lookups, setting proper User-Agent headers, or eventually hosting a small private instance of Photon if search volume increases.
- **Drift Migration:** Upgrading the schema for existing installations requires a careful SQLite migration to avoid data loss.

### Ready for Proposal
Yes — The orchestrator should tell the user that we are ready to proceed to the proposal/spec phase to implement the Drift schema changes, set up `flutter_map` with OSM, configure Nominatim/Photon API integration, and design the manual calibration UI.
