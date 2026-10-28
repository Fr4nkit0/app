import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';

void main() {
  group('lighter content', () {
    RouteStop stopWith({double debt = 0, List<String> products = const []}) =>
        RouteStop(
          id: 's-1',
          customer: Customer(
            id: 'c-1',
            name: 'Kiosco Norte',
            phone: '3874000000',
            debtAmount: debt,
            productLabels: products,
            addresses: const [],
            preferences: const [],
          ),
          status: StopStatus.pending,
          scheduledAt: DateTime(2026, 10, 28, 9),
        );

    Future<void> pump(
      WidgetTester tester,
      RouteStop stop, {
      bool isNext = false,
    }) => tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: RouteStopCard(stop: stop, onTap: () {}, isNext: isNext),
            ),
          ),
        ),
      ),
    );

    testWidgets('drops the avatar, product chips and WhatsApp control', (
      tester,
    ) async {
      await pump(tester, stopWith(debt: 1500, products: ['Bidón 20L']));

      expect(find.byType(ProductChip), findsNothing);
      expect(find.text('KN'), findsNothing);
      expect(find.byTooltip('WhatsApp'), findsNothing);
      expect(find.byType(FaIcon), findsNothing);
    });

    testWidgets('shows the time bubble and the Próxima pill only when next', (
      tester,
    ) async {
      await pump(tester, stopWith());
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('Próxima'), findsNothing);

      await pump(tester, stopWith(), isNext: true);
      expect(find.text('Próxima'), findsOneWidget);
    });

    testWidgets('shows "Debe" only with debt', (tester) async {
      await pump(tester, stopWith());
      expect(find.textContaining('Debe'), findsNothing);

      await pump(tester, stopWith(debt: 1500));
      expect(find.text('Debe \$1.500'), findsOneWidget);
    });

    testWidgets('address is a single line with an ellipsis', (tester) async {
      await pump(tester, stopWith());

      final address = tester.widget<Text>(find.text('Sin dirección'));
      expect(address.maxLines, 1);
      expect(address.overflow, TextOverflow.ellipsis);
    });
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
