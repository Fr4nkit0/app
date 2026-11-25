import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/usecases/drift_transaction_runner.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/data/repositories/route.repository.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/route_reorder_screen.dart';

RouteStop _stop(String id, {StopStatus status = StopStatus.pending}) =>
    RouteStop(
      id: id,
      customer: Customer(
        id: 'cust-$id',
        name: 'Cliente $id',
        addresses: const [],
        preferences: const [],
      ),
      status: status,
      scheduledAt: DateTime(2026, 11, 25, 9),
      hasScheduledTime: true,
    );

class _FakeRouteRepository implements RouteRepository {
  _FakeRouteRepository(this.stops);

  final List<RouteStop> stops;

  /// Each saved order as its ids joined, then whether it also applies to
  /// the coming same weekdays.
  final List<(String, bool)> reorders = [];

  @override
  Stream<List<RouteStop>> watchDayStops() => Stream.value(stops);

  @override
  Future<void> reorderDayStops(
    List<String> orderedStopIds, {
    bool applyToTemplate = false,
  }) async => reorders.add((orderedStopIds.join(','), applyToTemplate));

  @override
  Future<void> markStop(String id, StopStatus status) =>
      throw UnimplementedError();

  @override
  Future<String> rescheduleStop(String stopId, DateTime at) =>
      throw UnimplementedError();
}

void main() {
  Future<_FakeRouteRepository> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeRouteRepository([
      _stop('A'),
      _stop('B'),
      _stop('C'),
      _stop('D', status: StopStatus.done),
    ]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeRepositoryProvider.overrideWithValue(repository),
          transactionRunnerProvider.overrideWithValue(
            <T>(Future<T> Function() action) => action(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RouteReorderScreen(),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('lists only the pending stops, numbered in route order', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Ordenar paradas'), findsOneWidget);
    expect(find.text('Cliente A'), findsOneWidget);
    expect(find.text('Cliente C'), findsOneWidget);
    expect(find.text('Cliente D'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('saves the dragged order, the closed stops after it, and goes '
      'back', (tester) async {
    final repository = await pumpScreen(tester);

    await tester.drag(
      find.byKey(const ValueKey('reorder-handle-A')),
      const Offset(0, 110),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solo hoy'));
    await tester.pumpAndSettle();

    expect(repository.reorders, [('B,A,C,D', false)]);
    expect(find.text('Ordenar paradas'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  });
  testWidgets('going back after a drag asks before discarding the order', (
    tester,
  ) async {
    final repository = await pumpScreen(tester);

    await tester.drag(
      find.byKey(const ValueKey('reorder-handle-A')),
      const Offset(0, 110),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('¿Descartar el nuevo orden?'), findsOneWidget);
    await tester.tap(find.text('Seguir ordenando'));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar paradas'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(repository.reorders, isEmpty);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('saving asks whether the order is also for the coming same '
      'weekdays and sends the choice', (tester) async {
    final repository = await pumpScreen(tester);

    await tester.drag(
      find.byKey(const ValueKey('reorder-handle-A')),
      const Offset(0, 110),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();

    // The stops are of Wednesday 2026-11-25.
    expect(find.text('Solo hoy'), findsOneWidget);
    await tester.tap(find.text('Hoy y los próximos miércoles'));
    await tester.pumpAndSettle();

    expect(repository.reorders, [('B,A,C,D', true)]);
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('closing the choice without picking keeps the screen and saves '
      'nothing', (tester) async {
    final repository = await pumpScreen(tester);

    await tester.drag(
      find.byKey(const ValueKey('reorder-handle-A')),
      const Offset(0, 110),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(repository.reorders, isEmpty);
    expect(find.text('Ordenar paradas'), findsOneWidget);
  });
}
