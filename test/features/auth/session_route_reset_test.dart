import 'package:app/core/network/dio_client.dart';
import 'package:app/core/services/database.helper.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/auth/logout_button.dart';
import 'package:app/features/auth/session_route_reset.dart';
import 'package:app/features/sync/data/repositories/pending_change.repository.dart';
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
  late ProviderContainer container;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'auth_token': 'stored-token'});
    db = AppDatabase(NativeDatabase.memory());
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api/v1'))
      ..httpClientAdapter = FakeHttpAdapter((_) => FakeHttpAdapter.json(200, {}));
    container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        secureStorageProvider.overrideWithValue(const FlutterSecureStorage()),
        pendingChangeRepositoryProvider.overrideWithValue(
          DriftPendingChangeRepository(db),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpPushedProfile(WidgetTester tester) async {
    container.read(authControllerProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SessionRouteReset(child: Scaffold(body: Text('root'))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Center(child: LogoutButton())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('logging out from a pushed screen returns to the root', (
    tester,
  ) async {
    await pumpPushedProfile(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider).isAuthenticated, isFalse);
    expect(find.byType(LogoutButton), findsNothing);
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('cancelling the logout keeps the pushed screen', (tester) async {
    await pumpPushedProfile(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutButton), findsOneWidget);
  });
}
