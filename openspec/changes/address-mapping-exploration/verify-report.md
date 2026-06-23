# Verification Report: Address Mapping & Geocoding

- **Change Name:** address-mapping-exploration
- **Date:** 2026-06-22
- **Testing Mode:** Standard (Manual Code Verification & Static Analysis)
- **Status:** **PASS**

---

## Executive Summary
This report documents the verification of the **Address Mapping & Geocoding** capability implemented for the **Marilin** app. All requirements specified in the [Address Mapping Specification](file:///home/frankito/projects/marilin/app/openspec/changes/address-mapping-exploration/specs/address-mapping/spec.md) and designed in [Design: Address Mapping and Geocoding](file:///home/frankito/projects/marilin/app/openspec/changes/address-mapping-exploration/design.md) have been successfully met. 

The application compiles cleanly with `flutter analyze` showing no errors on the modified files.

---

## Requirements Verification

### 1. Map Trigger from UI Screens
- **Requirement:** Trigger map view from [RouteStopCard](file:///home/frankito/projects/marilin/app/lib/features/route/presentation/widgets/route_stop_card.dart), [VisitScreen](file:///home/frankito/projects/marilin/app/lib/features/visits/presentation/screens/visit_screen.dart), [CustomerProfileScreen](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/screens/customer_profile_screen.dart), and [StepAddressView](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/step_address_view.dart) during customer creation.
- **Code Inspection:**
  - **`RouteStopCard`:** Integrated `AddressPickerMap` dialog when the map button is pressed. Correctly captures returned `LatLng` coordinates and triggers repository update.
  - **`VisitScreen`:** Uncommented the map button and wired it to open `AddressPickerMap`. Displays coordinate status (green checkmark and coordinates) when present.
  - **`CustomerProfileScreen`:** Renders the map picker button using the M3 Expressive style, displays the coordinate status under the address info, and updates database reactively.
  - **`StepAddressView`:** Integrated a "Ubicar en Mapa" button in the address step of customer creation. Coordinates are updated in the form state and persisted during customer creation.
- **Status:** **PASS**

### 2. Manual Coordinate Calibration
- **Requirement:** Allow users to reposition the pin marker by dragging/tapping the map. Auto-geocode using Photon API, or default to a safe location (Salta, Argentina) when offline.
- **Code Inspection:**
  - **`AddressPickerMap`:** Implements `MapOptions` with an `onTap` listener that updates the `_selectedLatLng` state.
  - **Marker Rendering:** A red `location_on` Icon marker is dynamically drawn at the coordinates specified by `_selectedLatLng`.
  - **Geocoding:** `GeocodingService` targets the Photon API (`https://photon.komoot.io/api/`), with result biasing set to Salta, Argentina.
  - **Offline/Failure Fallback:** In `AddressPickerMap`, geocoding queries are wrapped in try-catch. Failure resets results but keeps map interaction fully functional, defaulting the map center to Salta (`-24.789124, -65.411624`) so users can calibrate coordinates manually.
- **Status:** **PASS**

### 3. Consistent Address Formatting
- **Requirement:** Format raw address elements (street, apartment, floor, visualReference) into a single cohesive line. Handle block/lot and traditional patterns.
- **Code Inspection:**
  - **`AddressFormatter`:** Formats address parts separated by ` - `. It replaces and normalizes traditional and block/lot patterns:
    - `"mza"` or `"manzana"` is normalized to `"Mza."`.
    - `"lte"` or `"lote"` is normalized to `"Lote"`.
    - `"nro"`, `"n°"`, `"num"`, or `"numero"` is normalized to `"N°"`.
    - `"av"` or `"avenida"` is normalized to `"Av."`.
    - Formats numeric floors as `"Piso [number]"` and alphanumeric apartments as `"Depto [apt]"` (or `"Lote [apt]"` if part of a block).
  - Used reactively in all relevant UI screens for consistent rendering.
- **Status:** **PASS**

### 4. Coordinates Persistency
- **Requirement:** Persist latitude and longitude coordinates in the local Drift SQLite database.
- **Code Inspection:**
  - **Database Schema:** `CustomerAddressTable` updated with nullable `latitude` and `longitude` fields (real type).
  - **Migration:** Database `schemaVersion` bumped to `4`. `AppDatabase`'s `onUpgrade` adds columns `latitude` and `longitude` to the `customer_addresses` table.
  - **Repository:** Introduced `updateAddressCoordinates` method in the interface and implemented it in `DriftCustomerRepository` (using a lightweight Drift update query) and `MockCustomerRepository`.
- **Status:** **PASS**

---

## Static Analysis Verification
- **Command Executed:** `flutter analyze`
- **Result:** Compilation succeeds. Zero errors or severe warnings found on modified files.
  - *Note:* The analyzer outputted a few warnings/info items on unrelated files or pre-existing code (e.g. unused `_buildProfileCustodyRow` in `customer_profile_screen.dart` or non-camelCase database fields in route/sales tables), which do not block this capability's release.

---

## Identified Risks & Recommendations
1. **Photon API Availability:** The geocoding service depends on the public, free Photon API. If the service experiences downtime, the app falls back to manual calibration on Salta. **Recommendation:** Monitor usage; if API limits or performance become an issue, consider self-hosting a Photon instance since it is lightweight and open-source.
2. **Offline Mode Center:** When offline, the map centers on Salta. This is highly suitable since the app is regionally focused. If the app expands to other regions in the future, the default fallback coordinates should be made dynamic based on the user's branch or warehouse.
