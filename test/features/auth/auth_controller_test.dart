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
        'email': 'marcos@marilin.test',
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
      'sends email, password and device name, then stores token and name',
      () async {
        final adapter = _loginOk();
        final container = _container(adapter);
        await _settled(container);

        final ok = await container
            .read(authControllerProvider.notifier)
            .login('marcos@marilin.test', 'secret');

        expect(ok, isTrue);
        final request = adapter.requests.single;
        expect(request.path, '/auth/login');
        expect(request.data, {
          'email': 'marcos@marilin.test',
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

    test('shows the server error when the account is disabled', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(422, {
            'message': 'User account is disabled.',
            'errors': {
              'email': ['User account is disabled.'],
            },
          }),
        ),
      );
      await _settled(container);

      final ok = await container
          .read(authControllerProvider.notifier)
          .login('marcos@marilin.test', 'secret');

      expect(ok, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.error, 'User account is disabled.');
      expect(await _storage.read(key: 'auth_token'), isNull);
    });

    test('shows the server error when the driver is disabled', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(422, {
            'message': 'User is not an active driver.',
            'errors': {
              'email': ['User is not an active driver.'],
            },
          }),
        ),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('marcos@marilin.test', 'secret');

      expect(
        container.read(authControllerProvider).error,
        'User is not an active driver.',
      );
    });

    test('shows the server error for wrong credentials', () async {
      final container = _container(
        FakeHttpAdapter(
          (_) => FakeHttpAdapter.json(422, {
            'message': 'These credentials do not match our records.',
            'errors': {
              'email': ['These credentials do not match our records.'],
            },
          }),
        ),
      );
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('marcos@marilin.test', 'wrong');

      expect(
        container.read(authControllerProvider).error,
        'These credentials do not match our records.',
      );
    });
  });

  group('remember me', () {
    test('persists the email and the password in secure storage', () async {
      final container = _container(_loginOk());
      await _settled(container);

      await container
          .read(authControllerProvider.notifier)
          .login('marcos@marilin.test', 'secret', rememberCredentials: true);

      final all = await _storage.readAll();
      expect(all['auth_saved_email'], 'marcos@marilin.test');
      expect(all['auth_saved_password'], 'secret');

      final remembered = await container
          .read(authControllerProvider.notifier)
          .loadRememberedCredentials();
      expect(remembered.remember, isTrue);
      expect(remembered.email, 'marcos@marilin.test');
      expect(remembered.password, 'secret');
    });

    test(
      'forgets the email and the password when remember me is off',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'auth_remember_credentials': 'true',
          'auth_saved_email': 'old@marilin.test',
          'auth_saved_password': 'old-secret',
        });
        final container = _container(_loginOk());
        await _settled(container);

        await container
            .read(authControllerProvider.notifier)
            .login('marcos@marilin.test', 'secret');

        final remembered = await container
            .read(authControllerProvider.notifier)
            .loadRememberedCredentials();
        expect(remembered.remember, isFalse);
        expect(remembered.email, isNull);
        expect(remembered.password, isNull);
        expect(await _storage.read(key: 'auth_saved_password'), isNull);
      },
    );

    test('keeps the remembered password across restarts', () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_remember_credentials': 'true',
        'auth_saved_email': 'marcos@marilin.test',
        'auth_saved_password': 'secret',
      });
      final container = _container(
        FakeHttpAdapter((_) => throw StateError('no network expected')),
      );

      await _settled(container);

      final remembered = await container
          .read(authControllerProvider.notifier)
          .loadRememberedCredentials();
      expect(remembered.email, 'marcos@marilin.test');
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
          .login('marcos@marilin.test', 'secret');

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
        await _storage.write(
          key: 'auth_saved_email',
          value: 'marcos@marilin.test',
        );
        await _storage.write(key: 'auth_saved_password', value: 'secret');
        final container = await signedIn(
          FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {})),
        );

        await container.read(authControllerProvider.notifier).logout();

        final remembered = await container
            .read(authControllerProvider.notifier)
            .loadRememberedCredentials();
        expect(remembered.email, 'marcos@marilin.test');
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
