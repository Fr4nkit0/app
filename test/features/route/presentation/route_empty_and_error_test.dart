import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/sync/sync_engine.dart';

import '../../../support/real_fonts.dart';

class _FakeEngine implements SyncEngine {
  int cycles = 0;

  @override
  Future<SyncStatus> runCycle() async {
    cycles++;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const SyncStatus(lastResult: SyncCycleResult.success);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedIn extends AuthController {
  @override
  AuthState build() =>
      AuthState(isAuthenticated: true, displayName: 'Esteban Benítez');
}

void main() {
  // Roboto, as on a phone; the default test font is wide and overflows.
  setUpAll(() async {
    expect(await loadRealFonts(), isTrue);
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> pumpRoute(
    WidgetTester tester, {
    bool syncRunning = false,
    Stream<List<RouteStop>> Function()? dayStream,
    SyncCycleResult? lastResult = SyncCycleResult.success,
    SyncEngine? engine,
  }) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      // No automatic retries: only the Reintentar button may reload.
      retry: (_, _) => null,
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        if (engine != null) syncEngineProvider.overrideWithValue(engine),
        syncStatusProvider.overrideWith(
          (ref) => Stream.value(
            SyncStatus(
              lastCycleAt: DateTime(2026, 10, 28, 18, 27),
              lastResult: lastResult,
              pendingCount: 0,
              rejectedCount: 0,
            ),
          ),
        ),
        syncRunningProvider.overrideWith((ref) => Stream.value(syncRunning)),
        routeAllStopsProvider.overrideWith(
          (ref) => Stream.value(const <RouteStop>[]),
        ),
        routeDayProvider.overrideWith(
          (ref) => dayStream?.call() ?? Stream.value(const <RouteStop>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RouteDayScreen(),
        ),
      ),
    );
    // A running sync animates a spinner forever, so it never settles.
    if (syncRunning) {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'with no route after a successful sync, it says the route was not '
    'dispatched yet and offers a sync',
    (tester) async {
      await pumpRoute(tester);

      expect(find.text('Tu ruta todavía no fue despachada'), findsOneWidget);
      expect(
        find.text('Se va a cargar cuando administración la despache.'),
        findsOneWidget,
      );
      expect(find.text('Sin paradas por ahora'), findsNothing);
      final button = find.widgetWithText(OutlinedButton, 'Sincronizar ahora');
      expect(button, findsOneWidget);
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    },
  );

  testWidgets('pull-to-refresh on an empty route runs one sync cycle', (
    tester,
  ) async {
    final engine = _FakeEngine();
    await pumpRoute(tester, engine: engine);

    await tester.fling(
      find.text('Tu ruta todavía no fue despachada'),
      const Offset(0, 400),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(engine.cycles, 1);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  for (final lastResult in [SyncCycleResult.offline, null]) {
    testWidgets(
      'with no route for today and no connection ($lastResult), it asks to '
      'connect to download it',
      (tester) async {
        await pumpRoute(tester, lastResult: lastResult);

        expect(find.text('Falta la ruta de hoy'), findsOneWidget);
        expect(
          find.text('Conectate a internet para descargar la ruta de hoy.'),
          findsOneWidget,
        );
        expect(find.text('Sin paradas por ahora'), findsNothing);
        expect(find.text('Descargando la ruta de hoy…'), findsNothing);
        final button = find.widgetWithText(OutlinedButton, 'Sincronizar ahora');
        expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
      },
    );

    testWidgets(
      'with no route for today and a sync running ($lastResult), it shows '
      'the route downloading',
      (tester) async {
        await pumpRoute(tester, lastResult: lastResult, syncRunning: true);

        expect(find.text('Descargando la ruta de hoy…'), findsOneWidget);
        expect(find.text('Falta la ruta de hoy'), findsNothing);
        expect(
          find.text('Conectate a internet para descargar la ruta de hoy.'),
          findsNothing,
        );
        expect(find.text('Sin paradas por ahora'), findsNothing);
        expect(find.byType(OutlinedButton), findsNothing);
      },
    );
  }

  testWidgets('a server failure keeps the generic empty message', (
    tester,
  ) async {
    await pumpRoute(tester, lastResult: SyncCycleResult.failure);

    expect(find.text('Sin paradas por ahora'), findsOneWidget);
    expect(find.text('Tu ruta todavía no fue despachada'), findsNothing);
    expect(find.text('Falta la ruta de hoy'), findsNothing);
  });

  testWidgets('the sync action is disabled while a sync runs', (tester) async {
    await pumpRoute(tester, syncRunning: true);

    final button = find.widgetWithText(OutlinedButton, 'Sincronizando…');
    expect(button, findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(find.text('Sincronizar ahora'), findsNothing);
  });

  testWidgets('a load error shows a retry that reloads the route', (
    tester,
  ) async {
    var loads = 0;
    await pumpRoute(
      tester,
      dayStream: () {
        loads++;
        return Stream<List<RouteStop>>.error(Exception('boom'));
      },
    );

    expect(find.text('No pudimos cargar la ruta'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(loads, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Reintentar'));
    await tester.pumpAndSettle();

    expect(loads, 2);
  });
}
