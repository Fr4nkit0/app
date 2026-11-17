import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/route/presentation/widgets/neighborhood_picker_sheet.dart';
import 'package:app/features/route/presentation/widgets/route_filter_bar.dart';
import 'package:app/features/route/presentation/widgets/route_progress_line.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

import '../../../support/real_fonts.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(isAuthenticated: true, displayName: 'Esteban');
}

RouteStop _stop(
  String id,
  String name, {
  String? neighborhood,
  StopStatus status = StopStatus.pending,
}) => RouteStop(
  id: id,
  customer: Customer(
    id: 'c-$id',
    name: name,
    addresses: [
      if (neighborhood != null)
        CustomerAddress(id: 'a-$id', neighborhood: neighborhood),
    ],
    preferences: const [],
  ),
  status: status,
  scheduledAt: DateTime(2026, 11, 17, 9),
);

void main() {
  setUpAll(() async {
    expect(await loadRealFonts(), isTrue);
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  final stops = [
    _stop('1', 'Kiosco Norte', neighborhood: 'Güemes'),
    _stop('2', 'Almacén Rosa', neighborhood: 'Centro'),
    _stop('3', 'Panadería Sol', status: StopStatus.done),
  ];

  Future<void> pumpRoute(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(_SignedIn.new),
        syncStatusProvider.overrideWith(
          (ref) => Stream.value(
            const SyncStatus(lastResult: SyncCycleResult.success),
          ),
        ),
        syncRunningProvider.overrideWith((ref) => Stream.value(false)),
        routeAllStopsProvider.overrideWith((ref) => Stream.value(stops)),
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
    await tester.pumpAndSettle();
  }

  List<String> shownCustomers(WidgetTester tester) => [
    for (final card in tester.widgetList<RouteStopCard>(
      find.byType(RouteStopCard),
    ))
      card.stop.customer.name,
  ];

  final search = find.byKey(RouteDayScreen.searchFieldKey);

  testWidgets('without a filter it lists every stop with the next stop and '
      'the progress', (tester) async {
    await pumpRoute(tester);

    expect(search, findsOneWidget);
    expect(shownCustomers(tester), [
      'Kiosco Norte',
      'Almacén Rosa',
      'Panadería Sol',
    ]);
    expect(find.byType(RouteProgressLine), findsOneWidget);
  });

  testWidgets('the search matches the customer name only and hides the '
      'next stop and the progress', (tester) async {
    await pumpRoute(tester);

    await tester.enterText(search, 'almacen');
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), ['Almacén Rosa']);
    expect(find.byType(RouteProgressLine), findsNothing);
    expect(find.text('1 de 3 paradas'), findsOneWidget);

    await tester.enterText(search, 'guemes');
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), isEmpty);
  });

  testWidgets('the neighborhood picker lists the route neighborhoods with '
      'their stops, searches them and picks one', (tester) async {
    await pumpRoute(tester);

    await tester.tap(find.byKey(RouteFilterBar.neighborhoodButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Elegí un barrio'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('Güemes'), findsOneWidget);
    expect(find.text('1 parada'), findsNWidgets(2));

    await tester.enterText(
      find.descendant(
        of: find.byKey(NeighborhoodPickerSheet.searchFieldKey),
        matching: find.byType(TextField),
      ),
      'gue',
    );
    await tester.pumpAndSettle();
    expect(find.text('Centro'), findsNothing);

    await tester.tap(find.text('Güemes'));
    await tester.pumpAndSettle();

    expect(find.text('Elegí un barrio'), findsNothing);
    expect(shownCustomers(tester), ['Kiosco Norte']);
    // The picked neighborhood shows on the button, with a way to drop it.
    expect(
      find.descendant(
        of: find.byKey(RouteFilterBar.neighborhoodButtonKey),
        matching: find.text('Güemes'),
      ),
      findsOneWidget,
    );

    // Readable: the label is not the color of the pill behind it.
    final label = tester.widget<Text>(
      find.descendant(
        of: find.byKey(RouteFilterBar.neighborhoodButtonKey),
        matching: find.text('Güemes'),
      ),
    );
    final pill = tester.widget<Material>(
      find
          .descendant(
            of: find.byKey(RouteFilterBar.neighborhoodButtonKey),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(label.style!.color, isNot(pill.color));

    await tester.tap(find.byTooltip('Quitar barrio'));
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), hasLength(3));
  });

  testWidgets('the neighborhood combines with the customer search', (
    tester,
  ) async {
    await pumpRoute(tester);

    await tester.tap(find.byKey(RouteFilterBar.neighborhoodButtonKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Centro'));
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), ['Almacén Rosa']);

    await tester.enterText(search, 'kiosco');
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), isEmpty);
    expect(find.text('Ninguna parada coincide'), findsOneWidget);
  });

  testWidgets('status chips show their counts, hide empty statuses and '
      'keep only that status', (tester) async {
    await pumpRoute(tester);

    expect(find.widgetWithText(ChoiceChip, 'Todas 3'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Pendientes 2'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Visitadas 1'), findsOneWidget);
    expect(find.textContaining('Ausentes'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Visitadas 1'));
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), ['Panadería Sol']);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Todas 3'));
    await tester.pumpAndSettle();
    expect(shownCustomers(tester), hasLength(3));
    expect(find.byType(RouteProgressLine), findsOneWidget);
  });

  testWidgets('no match shows an empty state that clears every filter', (
    tester,
  ) async {
    await pumpRoute(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Visitadas 1'));
    await tester.enterText(search, 'zzz');
    await tester.pumpAndSettle();

    expect(shownCustomers(tester), isEmpty);
    expect(find.text('Ninguna parada coincide'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Limpiar filtros'));
    await tester.pumpAndSettle();

    expect(shownCustomers(tester), hasLength(3));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: search, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      isEmpty,
    );
  });
}
