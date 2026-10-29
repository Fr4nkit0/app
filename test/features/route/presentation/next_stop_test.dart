import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/route/presentation/widgets/next_stop_card.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

import '../../../support/real_fonts.dart';

class _SignedIn extends AuthController {
  @override
  AuthState build() => AuthState(isAuthenticated: true, displayName: 'Esteban');
}

RouteStop _stop(
  String id, {
  String name = 'Kiosco Norte',
  StopStatus status = StopStatus.pending,
  String? phone,
  double debt = 0,
  List<CustomerAddress> addresses = const [],
  int hour = 9,
}) => RouteStop(
  id: id,
  customer: Customer(
    id: 'c-$id',
    name: name,
    phone: phone,
    addresses: addresses,
    preferences: const [],
    debtAmount: debt,
  ),
  status: status,
  scheduledAt: DateTime(2026, 10, 28, hour),
);

void main() {
  setUpAll(() async {
    expect(await loadRealFonts(), isTrue, reason: 'Roboto not found');
  });
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  group('nextStopProvider', () {
    Future<RouteStop?> nextOf(List<RouteStop> stops) async {
      final container = ProviderContainer(
        overrides: [
          routeAllStopsProvider.overrideWith((ref) => Stream.value(stops)),
        ],
      );
      addTearDown(container.dispose);
      // Riverpod 3 pauses unlistened providers; listening lets the stream flow.
      container.listen(routeAllStopsProvider, (_, _) {});
      await container.read(routeAllStopsProvider.future);
      return container.read(nextStopProvider);
    }

    test('picks the first pending stop in day order', () async {
      final next = await nextOf([
        _stop('a', status: StopStatus.done),
        _stop('b'),
        _stop('c'),
      ]);
      expect(next?.id, 'b');
    });

    test('is null when no stop is pending', () async {
      expect(await nextOf([_stop('a', status: StopStatus.done)]), isNull);
      expect(await nextOf(const []), isNull);
    });

    test('is null while the list has not loaded', () {
      final container = ProviderContainer(
        overrides: [
          routeAllStopsProvider.overrideWith(
            (ref) => const Stream<List<RouteStop>>.empty(),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(nextStopProvider), isNull);
    });
  });

  Future<void> pumpRoute(
    WidgetTester tester,
    List<RouteStop> stops, {
    int custody = 0,
  }) async {
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
              pendingCount: 0,
              rejectedCount: 0,
            ),
          ),
        ),
        syncRunningProvider.overrideWith((ref) => Stream.value(false)),
        routeAllStopsProvider.overrideWith((ref) => Stream.value(stops)),
        routeDayProvider.overrideWith((ref) => Stream.value(stops)),
        for (final s in stops)
          customerContainerBalancesProvider(s.customer.id).overrideWith(
            (ref) => Stream.value([
              if (custody > 0)
                CustomerContainerBalance(
                  customerId: s.customer.id,
                  containerType: 'BIDON_20L',
                  quantity: custody,
                ),
            ]),
          ),
        for (final s in stops) ...[
          customerBalanceProvider(
            s.customer.id,
          ).overrideWith((_) => Stream.value(0.0)),
          stopSalesProvider(s.id).overrideWith((_) => Stream.value([])),
          visitPaymentsProvider(s.id).overrideWith((_) => Stream.value([])),
          visitMovementsProvider(s.id).overrideWith((_) async => []),
          routeStopByIdProvider(s.id).overrideWithValue(s),
        ],
        visitOutcomesProvider.overrideWith((_) => Stream.value(const [])),
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

  Finder inHero(Finder f) =>
      find.descendant(of: find.byType(NextStopCard), matching: f);

  final address = [
    CustomerAddress(
      id: 'ad',
      street: 'Av. Belgrano 123',
      neighborhood: 'Centro',
    ),
  ];

  testWidgets('hero shows name, address, time, debt, custody and actions', (
    tester,
  ) async {
    await pumpRoute(tester, [
      _stop('s-1', phone: '387 400-0000', debt: 1500, addresses: address),
    ], custody: 3);

    expect(find.byType(NextStopCard), findsOneWidget);
    expect(inHero(find.text('Próxima parada')), findsOneWidget);
    expect(inHero(find.text('Kiosco Norte')), findsOneWidget);
    expect(inHero(find.text('Av. Belgrano 123, Centro')), findsOneWidget);
    expect(inHero(find.text('Programada 09:00')), findsOneWidget);
    expect(inHero(find.text('Debe \$1.500')), findsOneWidget);
    expect(inHero(find.text('3 envases en custodia')), findsOneWidget);
    expect(inHero(find.text('Llamar')), findsOneWidget);
    expect(inHero(find.text('WhatsApp')), findsOneWidget);
    expect(inHero(find.text('Navegar')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero omits debt, custody, actions and shows fallback address', (
    tester,
  ) async {
    await pumpRoute(tester, [_stop('s-1')]);

    expect(inHero(find.text('Sin dirección cargada')), findsOneWidget);
    expect(inHero(find.textContaining('Debe')), findsNothing);
    expect(inHero(find.textContaining('custodia')), findsNothing);
    expect(inHero(find.text('Llamar')), findsNothing);
    expect(inHero(find.text('WhatsApp')), findsNothing);
  });

  testWidgets('tapping the hero opens the visit for that stop', (tester) async {
    await pumpRoute(tester, [
      _stop('s-1', status: StopStatus.done),
      _stop('s-2', name: 'Almacén Sur', hour: 10),
    ]);

    await tester.tap(inHero(find.text('Almacén Sur')));
    await tester.pumpAndSettle();

    final screen = tester.widget<VisitScreen>(find.byType(VisitScreen));
    expect(screen.stopId, 's-2');
  });

  testWidgets('done state replaces the hero when every stop is closed', (
    tester,
  ) async {
    await pumpRoute(tester, [
      _stop('s-1', status: StopStatus.done),
      _stop('s-2', status: StopStatus.absent, hour: 10),
    ]);

    expect(find.byType(NextStopCard), findsNothing);
    expect(find.text('Ruta terminada'), findsOneWidget);
    expect(find.text('2 paradas cerradas'), findsOneWidget);
    expect(find.text('Llamar'), findsNothing);
  });

  testWidgets('nothing is rendered in the hero slot for an empty list', (
    tester,
  ) async {
    await pumpRoute(tester, const []);

    expect(find.byType(NextStopCard), findsNothing);
    expect(find.text('Ruta terminada'), findsNothing);
    expect(find.text('Sin paradas por ahora'), findsOneWidget);
  });

  testWidgets('progress is one line with counts', (tester) async {
    await pumpRoute(tester, [
      _stop('s-1', status: StopStatus.done),
      _stop('s-2', hour: 10),
      _stop('s-3', hour: 11),
    ]);

    expect(find.text('1 de 3 paradas · 2 pendientes'), findsOneWidget);
    expect(find.text('Progreso de la jornada'), findsNothing);
  });

  testWidgets('only the list card of the next stop shows "Próxima"', (
    tester,
  ) async {
    await pumpRoute(tester, [
      _stop('s-1', status: StopStatus.done),
      _stop('s-2', name: 'Almacén Sur', hour: 10),
      _stop('s-3', name: 'Bar Este', hour: 11),
    ]);

    final cards = find.byType(RouteStopCard);
    expect(cards, findsNWidgets(3));
    Finder pill(String name) => find.descendant(
      of: find.ancestor(of: find.text(name), matching: cards).first,
      matching: find.text('Próxima'),
    );
    expect(pill('Almacén Sur'), findsOneWidget);
    expect(pill('Bar Este'), findsNothing);
    expect(find.text('Próxima'), findsOneWidget);
  });

  testWidgets('a 60-char name and a long address do not overflow', (
    tester,
  ) async {
    await pumpRoute(tester, [
      _stop(
        's-1',
        name: 'Distribuidora Mayorista de Bebidas y Alimentos del Norte SRL',
        phone: '3874000000',
        debt: 1234567,
        addresses: [
          CustomerAddress(
            id: 'ad',
            street: 'Avenida Presidente Doctor Hipólito Yrigoyen 1234',
            neighborhood: 'Barrio Parque General San Martín Sector Norte',
            floor: '12',
            apartment: 'B',
            visualReference: 'portón verde, al lado de la farmacia grande',
          ),
        ],
      ),
    ], custody: 12);

    expect(tester.takeException(), isNull);
    expect(find.byType(NextStopCard), findsOneWidget);
  });
}
