import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/theme_mode_controller.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/history/presentation/widgets/history_sync_status_card.dart';
import 'package:app/features/profile/profile_screen.dart';
import 'package:app/features/profile/widgets/profile_avatar.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

import '../../support/real_fonts.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(isAuthenticated: true, displayName: 'Esteban Benítez');
}

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  ProviderContainer makeContainer({SyncStatus status = const SyncStatus()}) {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        syncStatusProvider.overrideWith((ref) => Stream.value(status)),
        syncRunningProvider.overrideWith((ref) => Stream.value(false)),
        routeAllStopsProvider.overrideWith((ref) => Stream.value(const <RouteStop>[])),
        routeDayProvider.overrideWith((ref) => Stream.value(const <RouteStop>[])),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<ProviderContainer> pumpProfile(
    WidgetTester tester, {
    SyncStatus status = const SyncStatus(),
  }) async {
    final container = makeContainer(status: status);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('shows who is signed in', (tester) async {
    await pumpProfile(tester);

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('Esteban Benítez'), findsOneWidget);
    expect(find.widgetWithText(ProfileAvatar, 'EB'), findsOneWidget);
  });

  testWidgets('shows how the sync is doing', (tester) async {
    await pumpProfile(
      tester,
      status: SyncStatus(
        lastCycleAt: DateTime(2026, 10, 28, 9, 5),
        lastResult: SyncCycleResult.success,
        pendingCount: 2,
      ),
    );

    expect(find.byType(HistorySyncStatusCard), findsOneWidget);
    expect(find.text('Sincronizado a las 09:05'), findsOneWidget);
    expect(find.text('2 pendientes · 0 rechazados'), findsOneWidget);
  });

  testWidgets('offers the phone theme, light and dark, starting on the phone theme', (tester) async {
    final container = await pumpProfile(tester);

    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('choosing Oscuro switches and saves the theme', (tester) async {
    final container = await pumpProfile(tester);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(await const FlutterSecureStorage().read(key: ThemeModeController.storageKey), 'dark');
  });

  for (final (width, scale) in [(360.0, 1.0), (411.0, 1.0), (360.0, 1.3)]) {
    testWidgets('the theme labels stay on one line at ${width.toInt()} dp, text x$scale', (tester) async {
      expect(await loadRealFonts(), isTrue, reason: 'Roboto was not found in the Flutter SDK cache');
      await tester.binding.setSurfaceSize(Size(width, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpProfile(tester);

      // "Claro" is short enough to never wrap: the other labels match its height.
      final oneLine = tester.getSize(find.text('Claro')).height;
      for (final label in ['Sistema', 'Oscuro']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
        expect(paragraph.size.height, oneLine, reason: '$label wraps');
        expect(paragraph.didExceedMaxLines, isFalse, reason: '$label is cut');
      }
      expect(tester.takeException(), isNull);
    });
  }

  Future<void> scrollToSignOut(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('has the sign out action', (tester) async {
    await pumpProfile(tester);
    await scrollToSignOut(tester);

    expect(find.widgetWithText(OutlinedButton, 'Cerrar sesión'), findsOneWidget);
    expect(find.textContaining('sin sincronizar'), findsNothing);
  });

  testWidgets('warns before signing out with changes still pending', (tester) async {
    await pumpProfile(tester, status: const SyncStatus(pendingCount: 1));
    await scrollToSignOut(tester);

    expect(
      find.text('Tenés 1 cambio sin sincronizar. Sincronizá antes de cerrar sesión.'),
      findsOneWidget,
    );
  });

  testWidgets('the identity row on the route screen opens the profile', (tester) async {
    final container = makeContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: AppTheme.lightTheme, home: const RouteDayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('¡Hola, Esteban!'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
  });
}
