import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:app/core/network/dio_client.dart';

const _authTokenKey = 'auth_token';
const _authDisplayNameKey = 'auth_display_name';
const _authRememberKey = 'auth_remember_credentials';
const _authSavedEmailKey = 'auth_saved_email';
const _authSavedPasswordKey = 'auth_saved_password';

class RememberedCredentials {
  const RememberedCredentials({
    this.email,
    this.password,
    this.remember = false,
  });

  final String? email;
  final String? password;
  final bool remember;
}

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final String? displayName;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.displayName,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    String? displayName,
    bool clearDisplayName = false,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: clearError ? null : (error ?? this.error),
      displayName:
          clearDisplayName ? null : (displayName ?? this.displayName),
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuth();
    return AuthState(isLoading: true);
  }

  Future<void> _checkAuth() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.read(key: _authTokenKey);
    final displayName = await storage.read(key: _authDisplayNameKey);

    if (token != null) {
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
        displayName: displayName,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        clearDisplayName: true,
      );
    }
  }

  Future<RememberedCredentials> loadRememberedCredentials() async {
    final storage = ref.read(secureStorageProvider);
    final remember = await storage.read(key: _authRememberKey) == 'true';
    if (!remember) {
      return const RememberedCredentials(remember: false);
    }
    final email = await storage.read(key: _authSavedEmailKey);
    final password = await storage.read(key: _authSavedPasswordKey);
    return RememberedCredentials(
      email: email,
      password: password,
      remember: true,
    );
  }

  Future<void> clearLoginError() async {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  String? _parseDisplayName(Map<String, dynamic> data, String email) {
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      final name = user['name'] ?? user['full_name'] ?? user['display_name'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }
    final direct = data['name'] ?? data['display_name'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }
    final local = email.split('@').first.trim();
    if (local.isNotEmpty) {
      return local[0].toUpperCase() + local.substring(1);
    }
    return null;
  }

  String _mapLoginError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final error = data['error'];
      if (error is String && error.trim().isNotEmpty) {
        return error.trim();
      }
      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }
    }

    if (status == 401 || status == 403) {
      return 'Correo o contraseña incorrectos.';
    }
    if (status == 422) {
      return 'Revisá los datos ingresados e intentá de nuevo.';
    }
    if (status != null && status >= 500) {
      return 'El servidor no está disponible. Intentá más tarde.';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'La conexión tardó demasiado. Revisá tu red e intentá de nuevo.';
      case DioExceptionType.connectionError:
        return 'Sin conexión. Podés trabajar offline después de iniciar sesión cuando haya red.';
      default:
        break;
    }

    return 'No pudimos iniciar sesión. Intentá de nuevo.';
  }

  Future<void> _persistRememberedCredentials({
    required String email,
    required String password,
    required bool remember,
  }) async {
    final storage = ref.read(secureStorageProvider);
    if (remember) {
      await storage.write(key: _authRememberKey, value: 'true');
      await storage.write(key: _authSavedEmailKey, value: email);
      await storage.write(key: _authSavedPasswordKey, value: password);
    } else {
      await storage.write(key: _authRememberKey, value: 'false');
      await storage.delete(key: _authSavedEmailKey);
      await storage.delete(key: _authSavedPasswordKey);
    }
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberCredentials = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final raw = response.data;
      final data = raw is Map<String, dynamic>
          ? raw
          : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
      final token = data['access_token'] ?? data['token'];
      if (token != null) {
        final storage = ref.read(secureStorageProvider);
        await storage.write(key: _authTokenKey, value: token.toString());

        final displayName = _parseDisplayName(data, email);
        if (displayName != null) {
          await storage.write(key: _authDisplayNameKey, value: displayName);
        }

        await _persistRememberedCredentials(
          email: email,
          password: password,
          remember: rememberCredentials,
        );

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          displayName: displayName,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'La respuesta del servidor no incluyó un token válido.',
        );
        return false;
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapLoginError(e),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ocurrió un error inesperado. Intentá de nuevo.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/auth/logout');
    } catch (_) {
      // Ignore errors on logout
    } finally {
      final storage = ref.read(secureStorageProvider);
      await storage.delete(key: _authTokenKey);
      await storage.delete(key: _authDisplayNameKey);
      state = state.copyWith(
        isAuthenticated: false,
        isLoading: false,
        clearDisplayName: true,
      );
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
