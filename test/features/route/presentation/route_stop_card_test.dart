import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';

void main() {
  testWidgets('WhatsApp control has a tooltip and a 44dp hit area', (
    tester,
  ) async {
    final stop = RouteStop(
      id: 's-1',
      customer: Customer(
        id: 'c-1',
        name: 'Kiosco Norte',
        phone: '3874000000',
        addresses: const [],
        preferences: const [],
      ),
      status: StopStatus.pending,
      scheduledAt: DateTime(2026, 10, 28, 9),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RouteStopCard(stop: stop, onTap: () {}),
            ),
          ),
        ),
      ),
    );

    final control = find.byTooltip('WhatsApp');
    expect(control, findsOneWidget);
    final size = tester.getSize(control);
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
  });

  group('sync badge', () {
    RouteStop stopWith(StopStatus status) => RouteStop(
      id: 's-1',
      customer: Customer(
        id: 'c-1',
        name: 'Kiosco Norte',
        addresses: const [],
        preferences: const [],
      ),
      status: status,
      scheduledAt: DateTime(2026, 10, 28, 9),
    );

    final unsent = PendingChange(
      id: 1,
      entity: PendingEntity.routeStop,
      entityId: 's-1',
      action: PendingAction.update,
      status: PendingStatus.pending,
      createdAt: DateTime(2026, 10, 28),
    );

    Future<void> pump(WidgetTester tester, StopStatus status) =>
        tester.pumpWidget(
          ProviderScope(
            overrides: [
              recordSyncStatusProvider((
                entity: PendingEntity.routeStop,
                id: 's-1',
              )).overrideWith((ref) => Stream.value(unsent)),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: RouteStopCard(stop: stopWith(status), onTap: () {}),
                ),
              ),
            ),
          ),
        );

    for (final status in [
      StopStatus.done,
      StopStatus.absent,
      StopStatus.rescheduled,
    ]) {
      testWidgets('closed stop (${status.name}) shows the badge', (
        tester,
      ) async {
        await pump(tester, status);
        await tester.pump();

        expect(find.text('Sin enviar'), findsOneWidget);
      });
    }

    testWidgets('a pending stop shows no badge', (tester) async {
      await pump(tester, StopStatus.pending);
      await tester.pump();

      expect(find.text('Sin enviar'), findsNothing);
    });
  });
}
