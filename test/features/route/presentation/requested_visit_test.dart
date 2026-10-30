import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/widgets/next_stop_card.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/providers/pending_change_repository_provider.dart';

RouteStop _stop({
  StopStatus status = StopStatus.pending,
  bool isRequested = false,
  String? note,
}) => RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
  ),
  status: status,
  scheduledAt: DateTime(2026, 10, 30, 9),
  isRequested: isRequested,
  note: note,
);

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    ProviderScope(
      overrides: [
        recordSyncStatusProvider((
          entity: PendingEntity.routeStop,
          id: 's-1',
        )).overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: [MarilinTokens.light]),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  group('route card', () {
    for (final status in [StopStatus.pending, StopStatus.done]) {
      testWidgets('a requested ${status.name} stop shows the mark and note', (
        tester,
      ) async {
        await pump(
          tester,
          RouteStopCard(
            stop: _stop(
              status: status,
              isRequested: true,
              note: 'Llamar antes',
            ),
            onTap: () {},
          ),
        );

        expect(find.text('Visita solicitada'), findsOneWidget);
        expect(find.text('Llamar antes'), findsOneWidget);
      });
    }

    testWidgets('a requested stop without a note shows only the mark', (
      tester,
    ) async {
      await pump(
        tester,
        RouteStopCard(stop: _stop(isRequested: true), onTap: () {}),
      );

      expect(find.text('Visita solicitada'), findsOneWidget);
    });

    testWidgets('a normal stop shows no mark', (tester) async {
      await pump(tester, RouteStopCard(stop: _stop(), onTap: () {}));

      expect(find.text('Visita solicitada'), findsNothing);
    });
  });

  group('next stop card', () {
    testWidgets('a requested stop shows the mark and note', (tester) async {
      await pump(
        tester,
        NextStopCard(
          stop: _stop(isRequested: true, note: 'Llamar antes'),
          custodyCount: 0,
          onTap: () {},
        ),
      );

      expect(find.text('Visita solicitada'), findsOneWidget);
      expect(find.text('Llamar antes'), findsOneWidget);
    });

    testWidgets('a normal stop shows no mark', (tester) async {
      await pump(
        tester,
        NextStopCard(stop: _stop(), custodyCount: 0, onTap: () {}),
      );

      expect(find.text('Visita solicitada'), findsNothing);
    });
  });
}
