import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';

import '../../support/fake_http_adapter.dart';

const _storage = FlutterSecureStorage();

ProviderContainer _container(
  FakeHttpAdapter adapter, {
  PendingChangeRepository? queue,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
    ..httpClientAdapter = adapter;
  final container = ProviderContainer(
    overrides: [
      dioProvider.overrideWithValue(dio),
      secureStorageProvider.overrideWithValue(_storage),
      deviceNameProvider.overrideWithValue('Test Phone'),
      if (queue != null)
        pendingChangeRepositoryProvider.overrideWithValue(queue),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<AuthState> _settled(ProviderContainer container) async {
  container.read(authControllerProvider);
  for (var i = 0; i < 100; i++) {
    final state = container.read(authControllerProvider);
    if (!state.isLoading) return state;
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(authControllerProvider);
}

FakeHttpAdapter _loginOk() => FakeHttpAdapter(
  (_) => FakeHttpAdapter.json(200, {
    'data': {
      'token': 'plain-text-token',
      'refresh_token': 'plain-refresh-token',
      'user': {
        'id': 7,
        'name': 'Marcos Reparto',
        'username': 'mreparto',
        'email': null,
      },
    },
    'message': 'Login successful',
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('login', () {
    test(
      'sends username, password and device name, then stores token and name',
      () async {
        final adapter = _loginOk();
        final container = _container(adapter);
        await _settled(container);

        final ok = await container
            .read(authControllerProvider.notifier)
            .login('mreparto', 'secret');

        expect(ok, isTrue);
        final request = adapter.requests.single;
        expect(request.path, '/auth/login');
        expect(request.data, {
          'username': 'mreparto',
          'password': 'secret',
          'device_name': 'Test Phone',
        });
        expect(await _storage.read(key: 'auth_token'), 'plain-text-token');
        expect(await _storage.read(key: 'auth_display_name'), 'Marcos Reparto');
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isTrue);
        expect(state.displayName, 'Marcos Reparto');
      },
    );

    test('falls back to the username when the user has no name', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(200, {
            'data': {
              'token': 'plain-text-token',
              'user': {'id': 7, 'username': 'jperez', 'email': null},
            },
          }),
        ),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('jperez', 'secret');

      expect(container.read(authControllerProvider).displayName, 'Jperez');
      expect(await _storage.read(key: 'auth_display_name'), 'Jperez');
    });

    test('a rejected login without a message names the username', () async {
      final container = _container(
        FakeHttpAdapter((_) => FakeHttpAdapter.json(401, {})),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'wrong');

      expect(
        container.read(authControllerProvider).error,
        'Usuario o contraseña incorrectos.',
      );
    });

    test('shows the server error when the account is disabled', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(422, {
            'message': 'Tu cuenta está deshabilitada.',
            'errors': {
              'username': ['Tu cuenta está deshabilitada.'],
            },
          }),
        ),
      );
      await _settled(container);

      final ok = await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'secret');

      expect(ok, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, 'Tu cuenta está deshabilitada.');
      expect(await _storage.read(key: 'auth_token'), isNull);
    });

    test('shows the server error when the driver is disabled', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(422, {
            'message': 'El usuario no es un repartidor activo.',
            'errors': {
              'username': ['El usuario no es un repartidor activo.'],
            },
          }),
        ),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'secret');

      expect(
        container.read(authControllerProvider).error,
        'El usuario no es un repartidor activo.',
      );
    });

    test('shows the server error for wrong credentials', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(422, {
            'message':
                'Estas credenciales no coinciden con nuestros registros.',
            'errors': {
              'username': [
                'Estas credenciales no coinciden con nuestros registros.',
              ],
            },
          }),
        ),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'wrong');

      expect(
        container.read(authControllerProvider).error,
        'Estas credenciales no coinciden con nuestros registros.',
      );
    });

    const locked =
        'Demasiados intentos de inicio de sesión. Intente de nuevo en 42 '
        'segundos.';

    test(
      'shows the server message when too many attempts lock the login',
      () async {
        final container = _container(
          FakeHttpAdapter(
            (_) => FakeHttpAdapter.json(429, {
              'message': locked,
              'errors': {
                'username': [locked],
              },
              'retry_after': 42,
            }),
          ),
        );
        await _settled(container);

        final ok = await container
            .read(authControllerProvider.notifier)
            .login('mreparto', 'wrong');

        expect(ok, isFalse);
        expect(container.read(authControllerProvider).error, locked);
      },
    );

    test('shows the lock message from errors.username when there is no '
        'message', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(429, {
            'errors': {
              'username': [locked],
            },
            'retry_after': 42,
          }),
        ),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'wrong');

      expect(container.read(authControllerProvider).error, locked);
    });
  });

  group('remember me', () {
    test('persists the username and the password in secure storage', () async {
      final container = _container(_loginOk());
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'secret', rememberCredentials: true);

      final all = await _storage.readAll();
      expect(all['auth_saved_username'], 'mreparto');
      expect(all['auth_saved_password'], 'secret');

      final remembered = await container
          .read(authControllerProvider.notifier)
          .loadRememberedCredentials();
      expect(remembered.remember, isTrue);
      expect(remembered.username, 'mreparto');
      expect(remembered.password, 'secret');
    });

    test(
      'forgets the username and the password when remember me is off',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_remember_credentials': 'true',
          'auth_saved_username': 'old',
          'auth_saved_password': 'old-secret',
        });
        final container = _container(_loginOk());
        await _settled(container);

        await container
            .read(authControllerProvider.notifier)
            .login('mreparto', 'secret');

        final remembered = await container
            .read(authControllerProvider.notifier)
            .loadRememberedCredentials();
        expect(remembered.remember, isFalse);
        expect(remembered.username, isNull);
        expect(remembered.password, isNull);
        expect(await _storage.read(key: 'auth_saved_password'), isNull);
      },
    );

    test('sends and remembers the username trimmed', () async {
      final adapter = _loginOk();
      final container = _container(adapter);
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login(' JPerez ', 'secret', rememberCredentials: true);

      expect((adapter.requests.single.data as Map)['username'], 'JPerez');
      expect(await _storage.read(key: 'auth_saved_username'), 'JPerez');
    });

    test('drops a legacy remembered email instead of prefilling it', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_remember_credentials': 'true',
        'auth_saved_email': 'marcos@marilin.test',
        'auth_saved_password': 'secret',
      });
      final container = _container(_loginOk());
      await _settled(container);

      final before = await container
          .read(authControllerProvider.notifier)
          .loadRememberedCredentials();
      expect(before.username, isNull);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'secret', rememberCredentials: true);

      expect(await _storage.read(key: 'auth_saved_email'), isNull);
      expect(await _storage.read(key: 'auth_saved_username'), 'mreparto');
    });

    test('keeps the remembered password across restarts', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_remember_credentials': 'true',
        'auth_saved_username': 'mreparto',
        'auth_saved_password': 'secret',
      });
      final container = _container(
        FakeHttpAdapter((_) => throw StateError('no network expected')),
      );

      await _settled(container);

      final remembered = await container
          .read(authControllerProvider.notifier)
          .loadRememberedCredentials();
      expect(remembered.username, 'mreparto');
      expect(remembered.password, 'secret');
    });
  });

  group('startup', () {
    test(
      'opens authenticated without network when a token is stored',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_token': 'stored-token',
          'auth_display_name': 'Marcos Reparto',
        });
        final adapter = FakeHttpAdapter(
          (_) => throw StateError('no network expected'),
        );
        final container = _container(adapter);

        final state = await _settled(container);

        expect(state.isAuthenticated, isTrue);
        expect(state.displayName, 'Marcos Reparto');
        expect(adapter.requests, isEmpty);
      },
    );

    test('shows the login when there is no stored token', () async {
      final container = _container(
        FakeHttpAdapter((_) => throw StateError('no network expected')),
      );

      final state = await _settled(container);

      expect(state.isAuthenticated, isFalse);
    });
  });

  group('session', () {
    test('login stores the refresh token next to the access token', () async {
      final container = _container(_loginOk());
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('mreparto', 'secret');

      expect(
        await _storage.read(key: 'auth_refresh_token'),
        'plain-refresh-token',
      );
    });

    test('an expired session goes back to the login with a message', () async {
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'stored-token'});
      final container = _container(
        FakeHttpAdapter((_) => throw StateError('no network expected')),
      );
      expect((await _settled(container)).isAuthenticated, isTrue);

      container.read(sessionExpiryProvider.notifier).expire();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, 'Tu sesión venció. Iniciá sesión de nuevo.');
    });
  });

  group('logout', () {
    late AppDatabase db;
    late DriftPendingChangeRepository queue;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = DriftPendingChangeRepository(db);
    });

    tearDown(() async => db.close());

    Future<ProviderContainer> signedIn(FakeHttpAdapter adapter) async {
      await _storage.write(key: 'auth_token', value: 'plain-text-token');
      final container = _container(adapter, queue: queue);
      await _settled(container);
      return container;
    }

    test(
      'is blocked while changes are pending and keeps the session',
      () async {
        final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {}));
        final container = await signedIn(adapter);
        await queue.enqueue(
          entity: PendingEntity.sale,
          entityId: 'sale-1',
          action: PendingAction.insert,
        );
        await queue.enqueue(
          entity: PendingEntity.payment,
          entityId: 'pay-1',
          action: PendingAction.insert,
        );

        final result = await container
            .read(authControllerProvider.notifier)
            .logout();

        expect(result, isA<LogoutBlocked>());
        final blocked = result as LogoutBlocked;
        expect(blocked.pendingCount, 2);
        expect(blocked.message, contains('2'));
        expect(blocked.message, contains('sincroniz'));
        expect(adapter.requests, isEmpty);
        expect(await _storage.read(key: 'auth_token'), 'plain-text-token');
        expect(container.read(authControllerProvider).isAuthenticated, isTrue);
      },
    );

    test('is allowed when the queue is empty and clears the session', () async {
      await _storage.write(
        key: 'auth_refresh_token',
        value: 'plain-refresh-token',
      );
      final adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {}));
      final container = await signedIn(adapter);

      final result = await container
          .read(authControllerProvider.notifier)
          .logout();

      expect(result, isA<LoggedOut>());
      expect(adapter.requests.single.path, '/auth/logout');
      expect(await _storage.read(key: 'auth_token'), isNull);
      expect(await _storage.read(key: 'auth_refresh_token'), isNull);
      expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    });

    test(
      'does not report an expired session after a voluntary logout',
      () async {
        late ProviderContainer container;
        container = await signedIn(
          FakeHttpAdapter((_) {
            // The logout request found the session already dead on the server.
            container.read(sessionExpiryProvider.notifier).expire();
            return FakeHttpAdapter.json(401, {'message': 'Unauthenticated.'});
          }),
        );

        await container.read(authControllerProvider.notifier).logout();

        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.error, isNull);
      },
    );

    test(
      'keeps the remembered credentials so the next login is one tap',
      () async {
        await _storage.write(key: 'auth_remember_credentials', value: 'true');
        await _storage.write(key: 'auth_saved_username', value: 'mreparto');
        await _storage.write(key: 'auth_saved_password', value: 'secret');
        final container = await signedIn(
          FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {})),
        );

        await container.read(authControllerProvider.notifier).logout();

        final remembered = await container
            .read(authControllerProvider.notifier)
            .loadRememberedCredentials();
        expect(remembered.username, 'mreparto');
        expect(remembered.password, 'secret');
      },
    );

    test('is allowed when every change was already sent or rejected', () async {
      final container = await signedIn(
        FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {})),
      );
      await queue.enqueue(
        entity: PendingEntity.sale,
        entityId: 'sale-1',
        action: PendingAction.insert,
      );
      await queue.enqueue(
        entity: PendingEntity.payment,
        entityId: 'pay-1',
        action: PendingAction.insert,
      );
      final changes = await queue.getPending();
      await queue.markSent([changes[0].id]);
      await queue.markRejected(changes[1].id, 'invalid');

      final result = await container
          .read(authControllerProvider.notifier)
          .logout();

      expect(result, isA<LoggedOut>());
    });
  });
}
