import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/network/dio_client.dart';

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
  final Dio _dio;

  GeocodingService(this._dio);

  Future<List<GeocodingResult>> search(
    String query, {
    int limit = 5,
    double? biasLatitude = -24.789124,
    double? biasLongitude = -65.411624,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      final response = await _dio.get(
        '/map/geocode',
        queryParameters: {
          'q': query,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP error ${response.statusCode}');
      }

      final data = response.data['data'] as List<dynamic>? ?? const [];
      final results = <GeocodingResult>[];

      for (final item in data) {
        final double longitude = (item['longitude'] as num).toDouble();
        final double latitude = (item['latitude'] as num).toDouble();

        final String name = item['name']?.toString() ?? '';
        final String? street = item['street']?.toString();

        results.add(
          GeocodingResult(
            name: name,
            latitude: latitude,
            longitude: longitude,
            street: street,
            // Our proxy simplified the data and no longer returns houseNumber, city, state, country
            // but we maintain the constructor for compatibility.
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
  final dio = ref.watch(dioProvider);
  return GeocodingService(dio);
});
