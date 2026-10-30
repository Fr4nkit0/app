import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';

import '../../../support/container_types.dart';

const _refused = VisitOutcome(
  id: 2,
  code: 'refused',
  name: 'No quiso',
  triggersReschedule: false,
);

RouteStop _stop({
  StopStatus status = StopStatus.pending,
  bool isRequested = false,
  String? note,
}) => RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Tolaba',
    addresses: const [],
    preferences: const [],
  ),
  status: status,
  scheduledAt: DateTime(2026, 10, 30, 9),
  isRequested: isRequested,
  note: note,
  visit: status == StopStatus.pending
      ? null
      : const VisitSummary(outcome: _refused),
);

void main() {
  Future<void> pumpVisit(WidgetTester tester, RouteStop stop) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeStopByIdProvider('s-1').overrideWithValue(stop),
          customerBalanceProvider('c-1').overrideWith((_) => Stream.value(0)),
          stopSalesProvider('s-1').overrideWith((_) => Stream.value([])),
          visitPaymentsProvider('s-1').overrideWith((_) => Stream.value([])),
          visitMovementsProvider('s-1').overrideWith((_) async => []),
          customerContainerBalancesProvider(
            'c-1',
          ).overrideWith((_) => Stream.value([])),
          containerTypesProvider.overrideWith(
            (_) => Stream.value(catalogContainerTypes),
          ),
          visitOutcomesProvider.overrideWith(
            (_) => Stream.value(const [_refused]),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: const VisitScreen(stopId: 's-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final status in [StopStatus.pending, StopStatus.done]) {
    testWidgets('a requested ${status.name} visit shows the mark and note', (
      tester,
    ) async {
      await pumpVisit(
        tester,
        _stop(status: status, isRequested: true, note: 'Llamar antes'),
      );

      expect(find.text('Visita solicitada'), findsOneWidget);
      expect(find.text('Llamar antes'), findsOneWidget);
    });
  }

  testWidgets('a normal visit shows no mark', (tester) async {
    await pumpVisit(tester, _stop());

    expect(find.text('Visita solicitada'), findsNothing);
  });
}
