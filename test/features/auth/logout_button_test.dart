import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/auth/logout_button.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftPendingChangeRepository queue;
  late FakeHttpAdapter adapter;
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'stored-token'});
    db = AppDatabase(NativeDatabase.memory());
    queue = DriftPendingChangeRepository(db);
    adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {}));
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = adapter;
    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        secureStorageProvider.overrideWithValue(const FlutterSecureStorage()),
        pendingChangeRepositoryProvider.overrideWithValue(queue),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpButton(WidgetTester tester) async {
    // Start the session check so the controller has settled before tapping.
    container.read(authControllerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: LogoutButton())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('logs out after the driver confirms', (tester) async {
    await pumpButton(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(adapter.requests.single.path, '/auth/logout');
    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
  });

  testWidgets('does nothing when the driver cancels', (tester) async {
    await pumpButton(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(adapter.requests, isEmpty);
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  });

  testWidgets('explains why it cannot log out with changes pending', (
    tester,
  ) async {
    await queue.enqueue(
      entity: PendingEntity.sale,
      entityId: 'sale-1',
      action: PendingAction.insert,
    );
    await pumpButton(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 cambio sin sincronizar'), findsOneWidget);
    expect(adapter.requests, isEmpty);
    expect(container.read(authControllerProvider).isAuthenticated, isTrue);
  });
}
