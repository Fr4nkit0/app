import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

/// Secure storage keys of the session tokens.
const authTokenKey = 'auth_token';
const authRefreshTokenKey = 'auth_refresh_token';

/// Bounds of every request, so a hung server ends the call with a retryable
/// timeout instead of leaving the sync running forever.
const apiConnectTimeout = Duration(seconds: 10);
const apiTransferTimeout = Duration(seconds: 30);

const _retriedFlag = 'auth_retried';
const _noRefreshPaths = {'/auth/login', '/auth/refresh'};

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Server base URL. Overridable in tests; defaults to the build-time value.
final apiBaseUrlProvider = Provider<String>((ref) => apiBaseUrl);

/// Counts the times the server ended the session; the auth controller
/// listens to it to go back to the login.
class SessionExpiry extends Notifier<int> {
  @override
  int build() => 0;

  void expire() => state++;
}

final sessionExpiryProvider = NotifierProvider<SessionExpiry, int>(
  SessionExpiry.new,
);

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  if (baseUrl.isEmpty) {
    throw StateError(
      'API_BASE_URL is not set. Run with '
      '--dart-define=API_BASE_URL=https://<host>/api/v1',
    );
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {'Accept': 'application/json'},
      connectTimeout: apiConnectTimeout,
      sendTimeout: apiTransferTimeout,
      receiveTimeout: apiTransferTimeout,
    ),
  );

  final storage = ref.watch(secureStorageProvider);
  final refresher = _TokenRefresher(
    dio: dio,
    storage: storage,
    onSessionEnded: () => ref.read(sessionExpiryProvider.notifier).expire(),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: authTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final canRetry =
            error.response?.statusCode == 401 &&
            options.extra[_retriedFlag] != true &&
            !_noRefreshPaths.contains(options.path);
        if (!canRetry) return handler.next(error);

        final rejectedToken = _tokenOf(options);
        if (!await refresher.refresh(rejectedToken)) {
          return handler.next(error);
        }

        try {
          options.extra[_retriedFlag] = true;
          return handler.resolve(await dio.fetch(options));
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ),
  );

  return dio;
});

String? _tokenOf(RequestOptions options) {
  final header = options.headers['Authorization'];
  return header is String && header.startsWith('Bearer ')
      ? header.substring(7)
      : null;
}

/// Swaps the refresh token for a new pair, once at a time for every request
/// that failed together.
class _TokenRefresher {
  _TokenRefresher({
    required this.dio,
    required this.storage,
    required this.onSessionEnded,
  });

  final Dio dio;
  final FlutterSecureStorage storage;
  final void Function() onSessionEnded;

  Future<bool>? _inFlight;

  /// Whether a usable access token is stored afterwards.
  Future<bool> refresh(String? rejectedToken) {
    return _inFlight ??= _refresh(
      rejectedToken,
    ).whenComplete(() => _inFlight = null);
  }

  Future<bool> _refresh(String? rejectedToken) async {
    // Another request or the background job already renewed it.
    final current = await storage.read(key: authTokenKey);
    if (current != null && current != rejectedToken) return true;

    final refreshToken = await storage.read(key: authRefreshTokenKey);
    if (refreshToken == null) {
      await _endSession();
      return false;
    }

    // A bare client: the refresh call must not go through this interceptor.
    final refreshClient = Dio(
      BaseOptions(
        baseUrl: dio.options.baseUrl,
        connectTimeout: apiConnectTimeout,
        sendTimeout: apiTransferTimeout,
        receiveTimeout: apiTransferTimeout,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ),
    )..httpClientAdapter = dio.httpClientAdapter;

    final Response<dynamic> response;
    try {
      response = await refreshClient.post<dynamic>('/auth/refresh');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != 401 && status != 403) return false; // Offline: retry later.

      // The background job may have rotated the pair in the meantime.
      if (await storage.read(key: authRefreshTokenKey) != refreshToken) {
        return true;
      }
      await _endSession();
      return false;
    }

    final body = response.data;
    final data = body is Map ? body['data'] : null;
    final token = data is Map ? data['token'] : null;
    final newRefresh = data is Map ? data['refresh_token'] : null;
    if (token is! String || newRefresh is! String) return false;

    await storage.write(key: authTokenKey, value: token);
    await storage.write(key: authRefreshTokenKey, value: newRefresh);
    return true;
  }

  Future<void> _endSession() async {
    await storage.delete(key: authTokenKey);
    await storage.delete(key: authRefreshTokenKey);
    onSessionEnded();
  }
}
