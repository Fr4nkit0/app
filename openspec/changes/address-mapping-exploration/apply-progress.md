# Implementation Progress: Address Mapping & Geocoding

This document tracks implementation progress for the `address-mapping-exploration` change.

## Current Status: Phase 3 Completed (All Phases Completed)

### Completed Tasks (PR 1: Database & Infrastructure)
- [x] Add dependencies (`flutter_map` v8.2.0, `latlong2` v0.9.1, and `http` v1.2.0) to [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml).
- [x] Update `CustomerAddressTable` in [customer.address.table.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/database/customer.address.table.dart) to add nullable `latitude` and `longitude` fields.
- [x] Increment `schemaVersion` to 4 in [database.helper.dart](file:///home/frankito/projects/marilin/app/lib/core/services/database.helper.dart) and add migration step in `onUpgrade` using `m.addColumn`.
- [x] Run code generation: `dart run build_runner build -d`.
- [x] Add double fields `latitude`/`longitude` to `CustomerAddress` in [customer.address.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/domain/models/customer.address.dart).

### Completed Tasks (PR 2: Core Logic & Services)
- [x] Declare `updateAddressCoordinates` in [customer.repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/customer.repository.dart).
- [x] Implement `updateAddressCoordinates` in [drift.customer.repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/drift.customer.repository.dart) to directly update coordinate columns.
- [x] Implement mock stub in [mock_customer_repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/mock_customer_repository.dart).
- [x] Add latitude and longitude to customer creation form state in [customer_form_state.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/providers/customer_form_state.dart) and [customer_form_provider.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/providers/customer_form_provider.dart).
- [x] Implement [AddressFormatter](file:///home/frankito/projects/marilin/app/lib/core/utils/address_formatter.dart) to handle traditional and block/lot formatting patterns.
- [x] Build [GeocodingService](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/geocoding_service.dart) querying Photon API (`https://photon.komoot.io/api/?q=...`).

### Completed Tasks (PR 3: UI Implementation & Wiring)
- [x] Implement [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) using `flutter_map` with marker tap calibration, floating search bar, input debouncing, and custom styling.
- [x] Integrate [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) trigger and status in [step_address_view.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/step_address_view.dart).
- [x] Update [customer_profile_screen.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/screens/customer_profile_screen.dart) to show formatted address (using [AddressFormatter](file:///home/frankito/projects/marilin/app/lib/core/utils/address_formatter.dart)), coordinate status indicator, and trigger map picker dialog to update address coordinates.
- [x] Update [route_stop_card.dart](file:///home/frankito/projects/marilin/app/lib/features/route/presentation/widgets/route_stop_card.dart) and [visit_screen.dart](file:///home/frankito/projects/marilin/app/lib/features/visits/presentation/screens/visit_screen.dart) to display formatted address (using [AddressFormatter](file:///home/frankito/projects/marilin/app/lib/core/utils/address_formatter.dart)) and link map buttons to [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart).

## Verification Results
- All codebase changes for Phase 3 have been written successfully.
- Codebase compiled and analyzed cleanly using `flutter analyze` with 0 errors/warnings on the modified files.
- Coordinates update flow was fully wired in both the Customer Creation flow, Customer Profile, Route Stop Cards, and Visits Screen.
- UI elements conform to Material 3 Expressive brand colors (`Color(0xFF1565C0)`).

## Next Steps
- Run verification tests to review and approve the implementation.
- Proceed to `/sdd-archive` to conclude the change and compile final summaries.
