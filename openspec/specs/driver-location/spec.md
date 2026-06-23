# Driver Location Tracking & Routing Specification

## Purpose
Define the functional behavior and requirements for real-time driver GPS tracking, route rendering using the OSRM routing API, throttled API usage, fallback mechanisms for signal loss or rate limiting, and interactive temporary destination drag estimation on the embedded map.

## Requirements

### Requirement: Foreground GPS Location Tracking
The system MUST request location permissions (fine/coarse) and fetch the driver's current position only while the map widget is active in the foreground.
- GIVEN the map screen is opened
- WHEN the user grants location permissions
- THEN the system retrieves the driver's GPS coordinates and displays a blue marker on the map representing the driver's current position.

- GIVEN the map screen is opened
- WHEN location permissions are denied
- THEN the system does not display the driver's marker or route, and allows normal customer pin display without crashing.

### Requirement: Route Polyline Tracing
The system MUST fetch and render a driving route polyline connecting the driver's position and the customer pin using the OSRM routing API.
- GIVEN a valid driver position and customer pin coordinates
- WHEN the map loads or updates
- THEN the system queries OSRM routing API (formatting coordinates as `lon1,lat1;lon2,lat2`) and parses the resulting GeoJSON geometry (reversing coordinate arrays from `[longitude, latitude]` to `LatLng(latitude, longitude)`) to display a route polyline.

### Requirement: OSRM API Throttling
To prevent rate-limiting (HTTP 429) from the public OSRM server, routing requests MUST be throttled.
- GIVEN active GPS tracking
- WHEN the driver's position changes
- THEN the system MUST NOT trigger an OSRM routing API call unless at least 5 seconds have passed since the last call AND the driver has moved more than 20 meters.

### Requirement: Temporary Drag Estimation
The user MUST be able to drag the customer pin on the map to estimate routes, distances, and ETAs to arbitrary points. This action MUST NOT modify the customer's permanent database record.
- GIVEN the map screen is active
- WHEN the user drags the customer pin to a new position
- THEN the system recalculates and updates the route polyline, distance, and ETA display in the UI temporarily, and does NOT save or write the new coordinates to the database.

### Requirement: Resilient Fallback
The system MUST gracefully handle OSRM API routing failures, timeouts, or rate limits by falling back to a straight-line representation.
- GIVEN the map screen is active and querying OSRM
- WHEN the OSRM routing request fails, timeouts, or returns an error (such as HTTP 429)
- THEN the system displays a warning message or logs the error silently, and falls back to rendering a straight dashed line connecting the driver and customer pins.
