import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GeocodingResult {
  final String name;
  final double latitude;
  final double longitude;
  final String? street;
  final String? houseNumber;
  final String? city;
  final String? state;
  final String? country;

  GeocodingResult({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.street,
    this.houseNumber,
    this.city,
    this.state,
    this.country,
  });

  String get formattedAddress {
    final parts = <String>[];
    if (street != null && street!.isNotEmpty) {
      if (houseNumber != null && houseNumber!.isNotEmpty) {
        parts.add('$street $houseNumber');
      } else {
        parts.add(street!);
      }
    } else {
      parts.add(name);
    }
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }
}

class GeocodingService {
  final http.Client _client;

  GeocodingService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<GeocodingResult>> search(
    String query, {
    int limit = 5,
    double? biasLatitude = -24.789124,
    double? biasLongitude = -65.411624,
  }) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse('https://photon.komoot.io/api/').replace(
      queryParameters: {
        'q': query,
        'limit': limit.toString(),
        if (biasLatitude != null) 'lat': biasLatitude.toString(),
        if (biasLongitude != null) 'lon': biasLongitude.toString(),
      },
    );

    try {
      final response = await _client
          .get(url, headers: {'User-Agent': 'MarilinApp/1.0 (com.marilin.app)'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final data =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final features = data['features'] as List<dynamic>? ?? const [];

      final results = <GeocodingResult>[];
      for (final feature in features) {
        final geometry = feature['geometry'] as Map<String, dynamic>?;
        final properties = feature['properties'] as Map<String, dynamic>?;

        if (geometry == null || properties == null) continue;

        final coordinates = geometry['coordinates'] as List<dynamic>?;
        if (coordinates == null || coordinates.length < 2) continue;

        // GeoJSON coordinates order: [longitude, latitude]
        final double longitude = (coordinates[0] as num).toDouble();
        final double latitude = (coordinates[1] as num).toDouble();

        final String name = properties['name']?.toString() ?? '';
        final String? street = properties['street']?.toString();
        final String? houseNumber = properties['housenumber']?.toString();
        final String? city = properties['city']?.toString();
        final String? stateName = properties['state']?.toString();
        final String? country = properties['country']?.toString();

        results.add(
          GeocodingResult(
            name: name,
            latitude: latitude,
            longitude: longitude,
            street: street,
            houseNumber: houseNumber,
            city: city,
            state: stateName,
            country: country,
          ),
        );
      }
      return results;
    } catch (e) {
      rethrow;
    }
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService();
});
