# Design: Address Mapping and Geocoding

The Address Mapping and Geocoding capability provides an embedded, offline-friendly mapping and geocoding solution for managing customer addresses (streets, blocks/manzanas, and lots/lotes) using OpenStreetMap (OSM) data. The solution allows searching for blocks/streets using the Photon API and manually calibrating lot locations via an interactive map pin, persisting coordinates (`latitude` and `longitude`) in the local Drift SQLite database. It also ensures that addresses are formatted consistently across key screens.

## Technical Approach

We will implement this capability in a series of layers:
1. **Local Database Schema & Migration**: Update [CustomerAddressTable](file:///home/frankito/projects/marilin/app/lib/features/customers/data/database/customer.address.table.dart) to add `latitude` and `longitude` fields. Bump the schema version in [AppDatabase](file:///home/frankito/projects/marilin/app/lib/core/services/database.helper.dart) to 4 and write the migration code.
2. **Library Setup**: Add mapping, location representation, and networking libraries: `flutter_map` (v8.2.0), `latlong2` (v0.9.1), and `http` (v1.2.0) to [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml).
3. **API Integration (Geocoding)**: Build a simple [GeocodingService](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/geocoding_service.dart) to query the public Photon API (`https://photon.komoot.io/api/?q=...`) to translate address strings into geographical coordinates.
4. **UI Components**:
   - Create an interactive dialog [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) that houses `flutter_map`.
   - Users can drag a pin marker or tap anywhere on the map to reposition the pin.
   - Includes a search bar to dynamically execute geocoding queries with input debouncing.
5. **Address Formatting Utility**: Create [AddressFormatter](file:///home/frankito/projects/marilin/app/lib/core/utils/address_formatter.dart) to format raw address parameters (`street`, `apartment`, `floor`, `visualReference`) into cohesive display strings for both traditional and block/lot addresses.
6. **UI Integration**: Integrate [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) into:
   - [RouteStopCard](file:///home/frankito/projects/marilin/app/lib/features/route/presentation/widgets/route_stop_card.dart)
   - [VisitScreen](file:///home/frankito/projects/marilin/app/lib/features/visits/presentation/screens/visit_screen.dart)
   - [CustomerProfileScreen](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/screens/customer_profile_screen.dart) (under the "Datos" tab and edit view)
   - [StepAddressView](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/step_address_view.dart) in customer creation.

## Architecture Decisions

- **Decision 1: Direct Coordinate Update API in Repository**
  - *Rationale*: Updating address coordinates from map calibration is a specialized, common operation. Rather than creating a whole customer object and performing a full transaction delete/re-insert (which is how `updateCustomer` is currently implemented), we will introduce `updateAddressCoordinates` to modify only `latitude` and `longitude` fields in a lightweight statement.
- **Decision 2: Reusing Existing Columns for Block & Lot**
  - *Rationale*: According to database constraints, the columns `street` and `apartment` are repurposed to represent Calle/Manzana and Depto/Lote respectively. This prevents schema bloat and maintains full backwards compatibility with existing records.
- **Decision 3: Map Taps & Pin Dragging for Manual Calibration**
  - *Rationale*: Tap gestures on the map body and drag events on the marker are supported to place the marker. A custom tap gesture callback `MapOptions(onTap: ...)` handles repositioning, ensuring maximum compatibility across platforms.
- **Decision 4: Geocoding via Public Photon API**
  - *Rationale*: Photon is an OpenStreetMap-based geocoding service that performs extremely well with block numbers (Manzanas) and community-mapped zones in Argentina. It does not require API keys, making it perfect for an offline-first regional client app, and it can be self-hosted locally if needed.

## Data Flow

```text
+-----------------------+      Click Map Icon       +-----------------------------+
|    UI Screen Widget   | ------------------------> |      AddressPickerMap       |
| (RouteStopCard/Visit) |                           +-----------------------------+
+-----------------------+                                          |
                                                                   v
                                                    Coordinates present in DB?
                                                    /                        \
                                                 YES                         NO
                                                 /                             \
                                                v                               v
                                  Center map at coordinate            Device online?
                                                                      /             \
                                                                   YES               NO
                                                                   /                   \
                                                                  v                     v
                                                           Query Photon API      Center at default
                                                           & center map          (Salta, Argentina)
                                                                  |                     |
                                                                  v                     v
                                                            Place Marker           Place Marker &
                                                                                   Show Warning
                                                                  |                     |
                                                                  +----------+----------+
                                                                             |
                                                                             v
                                                                 User Tap / Search Calibration
                                                                             |
                                                                             v
+-----------------------+      Drift DB updates      +------------------------------------------+
|  All UI listeners     | <------------------------- | customerRepository.updateCoordinates(...) |
|  reactively rebuild   |                            +------------------------------------------+
+-----------------------+
```

## File Changes

| File Path | Type | Description |
|---|---|---|
| [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml) | Modify | Add `flutter_map: ^8.2.0`, `latlong2: ^0.9.1`, and `http: ^1.2.0`. |
| [customer.address.table.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/database/customer.address.table.dart) | Modify | Add `latitude` and `longitude` nullable real fields. |
| [database.helper.dart](file:///home/frankito/projects/marilin/app/lib/core/services/database.helper.dart) | Modify | Increment `schemaVersion` to 4; implement migration from v3 to v4. |
| [customer.address.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/domain/models/customer.address.dart) | Modify | Add `latitude` and `longitude` double fields. |
| [customer_form_state.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/providers/customer_form_state.dart) | Modify | Add `latitude` and `longitude` fields to customer state. |
| [customer_form_provider.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/providers/customer_form_provider.dart) | Modify | Pass `latitude`/`longitude` on customer creation submit; add setters. |
| [customer.repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/customer.repository.dart) | Modify | Declare `updateAddressCoordinates` method. |
| [drift.customer.repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/drift.customer.repository.dart) | Modify | Implement `updateAddressCoordinates` and map fields. |
| [mock_customer_repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/mock_customer_repository.dart) | Modify | Implement mock stub for `updateAddressCoordinates`. |
| [address_formatter.dart](file:///home/frankito/projects/marilin/app/lib/core/utils/address_formatter.dart) | New | Central formatting logic for traditional and block/lot addresses. |
| [geocoding_service.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/geocoding_service.dart) | New | Photon geocoding API client. |
| [address_picker_map.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) | New | Map component widget with dynamic search and tap/drag calibrations. |
| [step_address_view.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/step_address_view.dart) | Modify | Add map picker trigger button and status row showing coordinates. |
| [customer_profile_screen.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/screens/customer_profile_screen.dart) | Modify | Display formatted address, integrate [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart). |
| [route_stop_card.dart](file:///home/frankito/projects/marilin/app/lib/features/route/presentation/widgets/route_stop_card.dart) | Modify | Display formatted address, wire map button to map selection/view. |
| [visit_screen.dart](file:///home/frankito/projects/marilin/app/lib/features/visits/presentation/screens/visit_screen.dart) | Modify | Display formatted address, wire map button to map selection/view. |

## Interfaces / Contracts

### AddressFormatter

```dart
class AddressFormatter {
  /// Formats customer address details into a single human-readable line.
  /// Handles block & lot format (e.g., "Manzana 488 A, Lote 9 (Opposite the park)")
  /// and traditional format (e.g., "Calle Falsa 123, Floor 2, Apt B (Green gate)").
  static String format({
    required String? street,
    required String? apartment,
    required String? floor,
    required String? visualReference,
  }) {
    if (street == null || street.isEmpty) return 'Sin dirección';

    final isBlock = street.toLowerCase().startsWith('manzana') || 
                    street.toLowerCase().startsWith('mza');

    final parts = <String>[];
    
    // 1. Street / Block name
    parts.add(street.trim());

    // 2. Floor / Apt / Lot details
    if (isBlock) {
      if (apartment != null && apartment.isNotEmpty) {
        // Apartment maps to "Lote" for block structures
        final cleanApt = apartment.replaceAll(RegExp(r'(?i)lote\s*'), '').trim();
        parts.add('Lote $cleanApt');
      }
      if (floor != null && floor.isNotEmpty) {
        parts.add('Piso $floor');
      }
    } else {
      if (floor != null && floor.isNotEmpty) {
        parts.add('Piso $floor');
      }
      if (apartment != null && apartment.isNotEmpty) {
        final cleanApt = apartment.replaceAll(RegExp(r'(?i)depto\s*'), '').trim();
        parts.add('Depto $cleanApt');
      }
    }

    var baseAddress = parts.join(', ');

    // 3. Visual reference suffix
    if (visualReference != null && visualReference.isNotEmpty) {
      baseAddress += ' ($visualReference)';
    }

    return baseAddress;
  }
}
```

### GeocodingService

```dart
class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;

  GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

abstract class GeocodingService {
  /// Resolves text address to lat/lng coordinates using external search API.
  Future<List<GeocodingResult>> search(String query);
}
```

### CustomerRepository Coordinate Method

```dart
abstract class CustomerRepository {
  // ... existing methods

  /// Updates only coordinates of an address directly.
  Future<Resource<void>> updateAddressCoordinates(
    String addressId,
    double latitude,
    double longitude,
  );
}
```

## Testing Strategy

| Target | Test Type | Coverage / Details |
|---|---|---|
| `AddressFormatter` | Unit Test | Test traditional formatting, block/lot formatting, missing/null parameters, formatting normalization (clearing duplicate "Depto" or "Lote" prefixes). |
| `GeocodingService` | Unit Test | Mock `http.Client` to verify Photon JSON response parsing and query construction. |
| `Drift Database Migration` | Integration | Verify upgrade path from `schemaVersion` 3 to 4. Ensure table columns `latitude` and `longitude` are added, and that existing addresses survive the schema update with data intact. |
| `drift.customer.repository.dart` | Integration | Test `updateAddressCoordinates` actually updates the records, and stream provider gets notified. |
| `AddressPickerMap` | Widget Test | Verify search input triggering geocoding, tap gestures updating coordinate state, confirmation returning correct LatLng, and offline indicator display. |

## Migration / Rollout

We need to migrate the Drift schema from version 3 to version 4.

1. **Table Definition Changes**:
   Add `latitude` and `longitude` columns to `CustomerAddressTable` in [customer.address.table.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/database/customer.address.table.dart):
   ```dart
   late final latitude = real().nullable()();
   late final longitude = real().nullable()();
   ```

2. **Database Helper Changes**:
   In [database.helper.dart](file:///home/frankito/projects/marilin/app/lib/core/services/database.helper.dart), bump `schemaVersion` to 4:
   ```dart
   @override
   int get schemaVersion => 4;
   ```
   Add a migration step to `onUpgrade` of the `MigrationStrategy`:
   ```dart
   onUpgrade: (m, from, to) async {
     if (from < 3) {
       // ... existing v2 -> v3 tables creation
     }
     if (from < 4) {
       // Migrate to version 4: add latitude and longitude columns
       await m.addColumn(customerAddressTable, customerAddressTable.latitude);
       await m.addColumn(customerAddressTable, customerAddressTable.longitude);
     }
   },
   ```

3. **Generating Code & Schema**:
   Run `dart run build_runner build -d` to generate updated database helper classes.
   Run `dart run drift_dev make-migrations` to cache schema snapshots and scaffold migration tests.

4. **Rollback Options**:
   If a migration failure occurs, we rollback the Flutter build version. SQLite columns `latitude` and `longitude` will remain in the SQLite database but won't be queried or modified by the downgraded app code (reverting `schemaVersion` to 3).

## Open Questions
- None
