# Proposal: Address Mapping and Geocoding

## Intent
Provide an embedded, offline-friendly mapping and geocoding solution for managing customer addresses (streets, blocks/manzanas, and lots/lotes) using OpenStreetMap (OSM) data without launching external applications. The solution allows searching for blocks/streets using the Nominatim/Photon API and manually fine-tuning lot locations via an interactive drag-and-drop map pin, persisting the resulting coordinates (`latitude` and `longitude`) in the local Drift database. It also ensures that addresses are fully and consistently formatted across key screens in the app.

## Scope

### In Scope
- Add `latitude` (real/double) and `longitude` (real/double) fields to the `CustomerAddressTable` in the Drift database.
- Bump the Drift schema version and write migration logic to safely add these columns.
- Integrate the `flutter_map` (Leaflet-style interactive maps) and `latlong2` packages in the project.
- Implement an interactive map component (`AddressPickerMap`) centered on OSM tiles, enabling geocoding searches for blocks/streets and manual lot placement via drag-and-drop markers.
- Create an address formatter utility to format address components (`street`, `apartment`, `floor`, `visualReference`) consistently.
- Update the UI components (`RouteStopCard`, `VisitScreen`, and `CustomerProfileScreen`) to display the fully formatted address instead of only the street field.
- Integrate the map picker UI into the customer profile edit workflow.

### Out of Scope
- Real-time turn-by-turn navigation or routing directions.
- Setting up a custom tile server (using public OSM tile providers).
- Geocoding server deployment (utilizing public Photon/Nominatim endpoints).
- Address sync protocol with a backend (this proposal focuses on local storage and UI geocoding capabilities).

## Capabilities

### New Capabilities
- address-mapping: Adds interactive Leaflet-style maps (flutter_map) and geocoding to search blocks (manzanas) and manually place lots (lotes).

### Modified Capabilities
- None

## Approach
1. **Schema Migration**:
   - Update `lib/features/customers/data/database/customer.address.table.dart` to include `latitude` and `longitude` as nullable double fields.
   - Bump Drift `schemaVersion` to 4 in `lib/core/services/database.helper.dart`.
   - Add migration steps to alter table `customer_addresses` and add the new columns.
   - Run `dart run build_runner build -d` to generate updated database files.
2. **Library Dependencies**:
   - Add `flutter_map`, `latlong2`, and `http` (for API querying) to `pubspec.yaml`.
3. **Geocoding Implementation**:
   - Write a lightweight HTTP client utility to query public OSM Nominatim or Photon API for searching blocks (e.g. "Mza 488 A").
4. **Interactive Map Component**:
   - Implement `AddressPickerMap` using `flutter_map`.
   - Implement a draggable marker representing the selected coordinates.
   - Support tap-to-pin and marker dragging to set specific lot coordinates.
5. **Address Formatter**:
   - Write a central helper `AddressFormatter` to cleanly join fields such as `street`, `apartment`, `floor`, and `visualReference` into a single presentable address string.
6. **UI Integration**:
   - Update `RouteStopCard`, `VisitScreen`, and `CustomerProfileScreen` to display formatted addresses.
   - Add a map-pin button next to the address on the Customer Profile Screen to open the geolocator map dialog.

## Affected Areas

| File/Module | Type of Change | Description |
|---|---|---|
| `pubspec.yaml` | Modification | Add `flutter_map`, `latlong2` dependencies. |
| `lib/features/customers/data/database/customer.address.table.dart` | Modification | Add `latitude` and `longitude` double/real fields to `CustomerAddressTable`. |
| `lib/core/services/database.helper.dart` | Modification | Increment `schemaVersion` to 4, add migration step to add columns to `customer_addresses`. |
| `lib/core/utils/address_formatter.dart` | New | Formatter utility to generate unified, human-readable address labels. |
| `lib/features/customers/data/services/geocoding_service.dart` | New | Light service to query Nominatim/Photon API. |
| `lib/features/customers/presentation/widgets/address_picker_map.dart` | New | Flutter map wrapper with search bar and draggable marker. |
| `lib/features/customers/presentation/screens/customer_profile_screen.dart` | Modification | Update display to use full formatted address and add map trigger. |
| `lib/features/route/presentation/widgets/route_stop_card.dart` | Modification | Display full formatted address. |
| `lib/features/visits/presentation/screens/visit_screen.dart` | Modification | Display full formatted address. |

## Risks

| Risk Description | Severity | Mitigation Plan |
|---|---|---|
| Offline state during geocoding | Medium | Geocoding API requires internet. If offline, the search bar will warn the user, but manual mapping remains available by dragging the marker relative to cached tile zones. |
| Nominatim/Photon API Rate Limiting | Low | Cache geocoding requests or use light debounce on input search fields to minimize hits. |
| Drift database migration failures | High | Write integration tests verifying database upgrades from v3 to v4. |

## Rollback Plan
- Revert changes to `pubspec.yaml`, `customer.address.table.dart`, and `database.helper.dart`.
- If rollback occurs in production, the code changes are reverted; sqlite columns `latitude`/`longitude` will remain in the database but be ignored by the downgraded code, or database version can be handled appropriately.

## Dependencies
- `flutter_map` for mapping UI components.
- `latlong2` for handling geographical coordinate representation.
- `http` for calling open geocoding services.

## Success Criteria
- Table schema matches expectations and database migration executes without data loss.
- Addresses in `RouteStopCard`, `VisitScreen`, and `CustomerProfileScreen` show structured fields formatted nicely.
- The `AddressPickerMap` accurately performs search queries, renders OSM tiles, and updates latitude/longitude coordinate fields upon saving.
