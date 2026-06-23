# Proposal: Driver Location Tracking & Route Estimation

## Intent
Provide real-time driver GPS tracking in the foreground and interactive route estimation (distance & ETA) on the embedded map without mutating database customer coordinates.

## Scope

### In Scope
- Add `geolocator` dependency and declare location permissions (Android/iOS).
- Fetch driver GPS location on map load in foreground.
- Fetch and trace driving route between driver and customer pins using public OSRM API.
- Allow dragging the customer pin to temporarily recalculate route, distance, and ETA in the UI.
- Draw a straight dashed line fallback if OSRM requests fail, timeout, or rate-limit.

### Out of Scope
- Background location tracking or persistent route history.
- Saving/updating the customer coordinates in the database when the pin is dragged on this screen.
- Launching external maps applications.

## Capabilities

### New Capabilities
- `driver-location`: Real-time driver positioning on map and route/ETA estimation to the customer pin.

### Modified Capabilities
None

## Approach
Implement geolocator to get foreground location. Query OSRM on map load and when the customer pin is dragged. Implement a throttled stream and map state layers for driver marker (blue) and polyline route (or direct line fallback).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modified | Add `geolocator` dependency |
| `android/app/src/main/AndroidManifest.xml` | Modified | Add ACCESS_FINE_LOCATION and ACCESS_COARSE_LOCATION |
| `ios/Runner/Info.plist` | Modified | Add location description plist keys |
| `lib/features/customers/presentation/widgets/address_picker_map.dart` | Modified | Integrate location tracking, routing, and pin estimation |

## Risks

| Risk | Likelihood | Mitigation |
|------|--------|-------------|
| OSRM Rate Limiting (429) | Medium | Throttle API requests to at most 1 query per 5 seconds and 20m movement threshold. |
| Network offline | High | Silent failure rendering a direct dashed line fallback. |
| Location permission denied | Medium | Omit driver position and routing, allow standard view. |

## Rollback Plan
Revert code changes in pubspec.yaml, config files, and address_picker_map.dart.

## Dependencies
- Public OSRM routing API service.

## Success Criteria
- [ ] Driver position marker (blue) is displayed on map load (if permission is granted).
- [ ] Route polyline displays correct roads-based route from driver to customer marker.
- [ ] Dragging customer pin updates route, distance, and ETA estimate dynamically in the UI without modifying database values.
- [ ] Network errors or OSRM timeouts fall back gracefully to a direct dashed line between the pins.
