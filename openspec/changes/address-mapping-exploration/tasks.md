# Tasks: Address Mapping and Geocoding

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 350-450 lines |
| 400-line budget risk | Medium |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (Database & Infrastructure) -> PR 2 (Geocoding & Format Utils) -> PR 3 (Map Widgets & UI Wiring) |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Notes |
|------|------|-----------|-------|
| 1 | DB Schema & Migrations | PR 1 | Base branch; Drift v3 to v4 migration |
| 2 | Utilities & Geocoding | PR 2 | Build GeocodingService and AddressFormatter |
| 3 | Embedded Map Picker & UI | PR 3 | Map widget and integration into Profile, Route Stop Card, and Visit screens |

## Phase 1: Database & Infrastructure
- [x] Add dependencies (`flutter_map`, `latlong2`, `http`) to [pubspec.yaml](file:///home/frankito/projects/marilin/app/pubspec.yaml).
- [x] Update `CustomerAddressTable` in [customer.address.table.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/database/customer.address.table.dart) to add nullable `latitude` and `longitude` fields.
- [x] Increment `schemaVersion` to 4 in [database.helper.dart](file:///home/frankito/projects/marilin/app/lib/core/services/database.helper.dart) and add migration step in `onUpgrade` using `m.addColumn`.
- [x] Run `dart run build_runner build -d` to generate updated database helper classes.
- [x] Add double fields `latitude`/`longitude` to `CustomerAddress` in [customer.address.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/domain/models/customer.address.dart).

## Phase 2: Core Logic & Services
- [x] Declare `updateAddressCoordinates` in [customer.repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/customer.repository.dart).
- [x] Implement `updateAddressCoordinates` in [drift.customer.repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/drift.customer.repository.dart) to directly update coordinate columns.
- [x] Implement mock stub in [mock_customer_repository.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/data/repositories/mock_customer_repository.dart).
- [x] Add latitude and longitude to customer creation form state in [customer_form_state.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/providers/customer_form_state.dart) and [customer_form_provider.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/providers/customer_form_provider.dart).
- [x] Implement [AddressFormatter](file:///home/frankito/projects/marilin/app/lib/core/utils/address_formatter.dart) to handle traditional and block/lot formatting patterns.
- [x] Build [GeocodingService](file:///home/frankito/projects/marilin/app/lib/features/customers/data/services/geocoding_service.dart) querying Photon API.

## Phase 3: UI Implementation & Wiring
- [x] Implement [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) using `flutter_map` with marker tap/drag calibration and geocoding search.
- [x] Integrate [AddressPickerMap](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/address_picker_map.dart) trigger and status in [step_address_view.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/widgets/step_address_view.dart).
- [x] Update [customer_profile_screen.dart](file:///home/frankito/projects/marilin/app/lib/features/customers/presentation/screens/customer_profile_screen.dart) to show formatted address and open `AddressPickerMap` dialog.
- [x] Update [route_stop_card.dart](file:///home/frankito/projects/marilin/app/lib/features/route/presentation/widgets/route_stop_card.dart) and [visit_screen.dart](file:///home/frankito/projects/marilin/app/lib/features/visits/presentation/screens/visit_screen.dart) to display formatted address and link map buttons to calibration.

