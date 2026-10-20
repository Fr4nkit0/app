import 'package:app/core/network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dio base URL comes from the configured API base URL', () {
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('https://api.example.test/api/v1'),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(dioProvider).options.baseUrl,
      'https://api.example.test/api/v1',
    );
  });

  test('dio fails fast when no API base URL was provided at build time', () {
    final container = ProviderContainer(
      overrides: [apiBaseUrlProvider.overrideWithValue('')],
    );
    addTearDown(container.dispose);

    expect(() => container.read(dioProvider), throwsA(anything));
  });
}
