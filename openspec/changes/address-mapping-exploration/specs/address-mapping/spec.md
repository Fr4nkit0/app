# Address Mapping Specification

## Purpose
The Address Mapping capability provides an embedded, offline-friendly mapping and geocoding solution for managing customer addresses (streets, blocks/manzanas, and lots/lotes) using OpenStreetMap (OSM) data without launching external applications. The solution allows searching for blocks/streets using the Nominatim/Photon API and manually fine-tuning lot locations via an interactive drag-and-drop map pin, persisting the resulting coordinates (latitude and longitude) in the local Drift SQLite database. It also ensures that addresses are formatted consistently across key screens in the app.

## Requirements

### Requirement: Map Trigger from UI Screens
The system MUST allow triggering the interactive map view by clicking the map icon in [RouteStopCard](file:///home/frankito/projects/marilin/app/lib/features/route/presentation/widgets/route_stop_card.dart), [VisitScreen](file:///home/frankito/projects/marilin/app/lib/features/visits/presentation/screens/visit_screen.dart), or [CustomerProfileScreen](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/screens/customer_profile_screen.dart).

#### Scenario: Open map with existing coordinates
* **GIVEN** the customer address already has valid latitude and longitude coordinates stored in the database.
* **WHEN** the user clicks the map icon button on any of the screens.
* **THEN** the system MUST open the embedded interactive map centered on those coordinates.
* **AND** place the pin marker at that exact location.

#### Scenario: Open map without existing coordinates (Auto-Geocoding)
* **GIVEN** the customer address does NOT have latitude and longitude coordinates stored in the database.
* **WHEN** the user clicks the map icon button.
* **THEN** the system MUST open the embedded interactive map.
* **AND** automatically execute a geocoding search query using the customer's text address (e.g., street or block).
* **AND** place the pin marker at the resolved location, allowing the user to manually calibrate it.

#### Scenario: Offline auto-geocoding fallback
* **GIVEN** the customer address does NOT have coordinates and the device has no internet connection.
* **WHEN** the user clicks the map icon button.
* **THEN** the system MUST open the map centered on a default city center location (e.g., Salta).
* **AND** display a warning that automatic search is unavailable, enabling manual coordinate calibration.

### Requirement: Manual Coordinate Calibration
The system MUST support manual location selection by dragging and dropping a pin marker on an embedded interactive map.

#### Scenario: Manual calibration of coordinates by dragging the marker
* **GIVEN** the map is displayed with an existing location pin marker.
* **WHEN** the user drags the marker to a new position on the map.
* **THEN** the system updates the temporary coordinate state with the new latitude and longitude.

#### Scenario: Manual calibration of coordinates by tapping the map
* **GIVEN** the map is displayed.
* **WHEN** the user taps a specific location on the map.
* **THEN** the pin marker moves to the tapped location and the system updates the coordinates.

### Requirement: Consistent Address Formatting
The system MUST construct and display a formatted address label combining all available address components (street, floor/manzana, apartment/lote).

#### Scenario: Display formatted address with traditional street details
* **GIVEN** a customer address record containing street = "Calle Falsa 123", floor = "2", apartment = "B", and visualReference = "Green gate".
* **WHEN** the system formats this address for display.
* **THEN** the resulting label is constructed as "Calle Falsa 123, Floor 2, Apt B (Green gate)".

#### Scenario: Display formatted address with block and lot details
* **GIVEN** a customer address record containing street = "Manzana 488 A", floor = null, apartment = "Lote 9", and visualReference = "Opposite the park".
* **WHEN** the system formats this address for display.
* **THEN** the resulting label is constructed as "Manzana 488 A, Lote 9 (Opposite the park)".

### Requirement: Coordinates Persistency
The system MUST store the latitude and longitude coordinates in the local SQLite database.

#### Scenario: Save selected coordinates to the database
* **GIVEN** the user has selected or calibrated coordinates to latitude = -34.6037 and longitude = -58.3816.
* **WHEN** the user confirms and saves the selection.
* **THEN** the system triggers a database update in the Drift SQLite database for the corresponding customer address.
* **AND** persists the latitude and longitude coordinates.
