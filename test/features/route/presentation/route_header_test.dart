import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

import '../../../support/real_fonts.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() =>
      AuthState(isAuthenticated: true, displayName: 'Esteban Benítez');
}

const _months = [
  '',
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];
const _days = [
  '',
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

String _todayLabel() {
  final now = DateTime.now();
  return '${_days[now.weekday]}, ${now.day} de ${_months[now.month]}';
}

void main() {
  // Overflow is measured with Roboto, as on a phone; the default test font is
  // a wide box font and would report false overflows.
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  Future<void> pumpRoute(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        syncStatusProvider.overrideWith(
          (ref) => Stream.value(
            SyncStatus(
              lastCycleAt: DateTime(2026, 10, 28, 18, 27),
              lastResult: SyncCycleResult.success,
              pendingCount: 12,
              rejectedCount: 3,
            ),
          ),
        ),
        syncRunningProvider.overrideWith((ref) => Stream.value(false)),
        routeAllStopsProvider.overrideWith(
          (ref) => Stream.value(const <RouteStop>[]),
        ),
        routeDayProvider.overrideWith(
          (ref) => Stream.value(const <RouteStop>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(360, 800), devicePixelRatio: 1),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const RouteDayScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool exceeds(WidgetTester tester, Finder finder) =>
      tester.renderObject<RenderParagraph>(finder).didExceedMaxLines;

  testWidgets('the date is the greeting subtitle, not a chip', (tester) async {
    await pumpRoute(tester);

    expect(find.text('Buen día de reparto'), findsNothing);
    final date = find.text(_todayLabel());
    expect(date, findsOneWidget);
    expect(tester.widget<Text>(date).style?.fontSize, greaterThanOrEqualTo(14));
    expect(exceeds(tester, date), isFalse);
  });

  testWidgets('sync status and counts fit a 360dp phone without an ellipsis', (
    tester,
  ) async {
    await pumpRoute(tester);

    final headline = find.text('Sincronizado 18:27');
    final pending = find.text('12 pendientes');
    final rejected = find.text('3 rechazados');
    expect(headline, findsOneWidget);
    expect(
      tester.widget<Text>(headline).style?.fontSize,
      greaterThanOrEqualTo(14),
    );
    expect(exceeds(tester, headline), isFalse);
    expect(exceeds(tester, pending), isFalse);
    expect(exceeds(tester, rejected), isFalse);
    expect(
      tester.getSize(find.byType(InkWell).first).height,
      greaterThanOrEqualTo(44),
    );
  });
}
