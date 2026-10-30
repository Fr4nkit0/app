import 'package:app/core/network/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

const _storage = FlutterSecureStorage();

/// The app's Dio wired to [adapter], plus the container to watch session expiry.
({Dio dio, ProviderContainer container}) _client(FakeHttpAdapter adapter) {
  final container = ProviderContainer(
    overrides: [
      apiBaseUrlProvider.overrideWithValue('https://api.example.test/api/v1'),
      secureStorageProvider.overrideWithValue(_storage),
    ],
  );
  addTearDown(container.dispose);
  final dio = container.read(dioProvider)..httpClientAdapter = adapter;
  return (dio: dio, container: container);
}

ResponseBody _refreshed() => FakeHttpAdapter.json(200, {
  'data': {
    'token': 'new-access',
    'refresh_token': 'new-refresh',
    'expires_at': '2026-10-22T10:00:00+00:00',
    'refresh_expires_at': '2026-11-20T10:00:00+00:00',
  },
});

String? _bearer(RequestOptions options) =>
    options.headers['Authorization'] as String?;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': 'old-access',
      'auth_refresh_token': 'old-refresh',
    });
  });

  group('expired access token', () {
    test(
      'is renewed with the refresh token and the request retried once',
      () async {
        final adapter = FakeHttpAdapter((options) {
          if (options.path == '/auth/refresh') return _refreshed();
          return _bearer(options) == 'Bearer new-access'
              ? FakeHttpAdapter.json(200, {'ok': true})
              : FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'});
        });
        final client = _client(adapter);

        final response = await client.dio.get('/sync/pull');

        expect(response.data, {'ok': true});
        expect(adapter.requests.map((r) => r.path), [
          '/sync/pull',
          '/auth/refresh',
          '/sync/pull',
        ]);
        expect(_bearer(adapter.requests[1]), 'Bearer old-refresh');
        expect(await _storage.read(key: 'auth_token'), 'new-access');
        expect(await _storage.read(key: 'auth_refresh_token'), 'new-refresh');
        expect(client.container.read(sessionExpiryProvider), 0);
      },
    );

    test('ends the session when the refresh token is rejected', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'}),
      );
      final client = _client(adapter);

      await expectLater(
        client.dio.get('/sync/pull'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests.map((r) => r.path), [
        '/sync/pull',
        '/auth/refresh',
      ]);
      expect(await _storage.read(key: 'auth_token'), isNull);
      expect(await _storage.read(key: 'auth_refresh_token'), isNull);
      expect(client.container.read(sessionExpiryProvider), 1);
    });

    test(
      'keeps the session when the refresh cannot reach the server',
      () async {
        final adapter = FakeHttpAdapter((options) {
          if (options.path == '/auth/refresh') {
            throw DioException.connectionError(
              requestOptions: options,
              reason: 'offline',
            );
          }
          return FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'});
        });
        final client = _client(adapter);

        await expectLater(
          client.dio.get('/sync/pull'),
          throwsA(isA<DioException>()),
        );

        expect(await _storage.read(key: 'auth_token'), 'old-access');
        expect(await _storage.read(key: 'auth_refresh_token'), 'old-refresh');
        expect(client.container.read(sessionExpiryProvider), 0);
      },
    );

    test('ends the session when there is no refresh token', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'old-access'});
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'}),
      );
      final client = _client(adapter);

      await expectLater(
        client.dio.get('/sync/pull'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests.map((r) => r.path), ['/sync/pull']);
      expect(client.container.read(sessionExpiryProvider), 1);
    });

    test(
      'is renewed only once for requests failing at the same time',
      () async {
        final adapter = FakeHttpAdapter((options) async {
          if (options.path == '/auth/refresh') {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return _refreshed();
          }
          return _bearer(options) == 'Bearer new-access'
              ? FakeHttpAdapter.json(200, {'ok': true})
              : FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'});
        });
        final client = _client(adapter);

        await Future.wait([
          client.dio.get('/sync/pull'),
          client.dio.get('/sync/bootstrap'),
        ]);

        expect(
          adapter.requests.where((r) => r.path == '/auth/refresh'),
          hasLength(1),
        );
      },
    );

    test('is not retried twice when the new token is also rejected', () async {
      final adapter = FakeHttpAdapter((options) {
        if (options.path == '/auth/refresh') return _refreshed();
        return FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'});
      });
      final client = _client(adapter);

      await expectLater(
        client.dio.get('/sync/pull'),
        throwsA(isA<DioException>()),
      );

      expect(adapter.requests.map((r) => r.path), [
        '/sync/pull',
        '/auth/refresh',
        '/sync/pull',
      ]);
    });
  });

  test('a rejected login does not try to refresh', () async {
    final adapter = FakeHttpAdapter(
      (_) => FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'}),
    );
    final client = _client(adapter);

    await expectLater(
      client.dio.post('/auth/login', data: {}),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requests.map((r) => r.path), ['/auth/login']);
    expect(client.container.read(sessionExpiryProvider), 0);
  });

  test('requests carry the stored access token', () async {
    final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {}));
    final client = _client(adapter);

    await client.dio.get('/auth/me');

    expect(_bearer(adapter.requests.single), 'Bearer old-access');
  });

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
