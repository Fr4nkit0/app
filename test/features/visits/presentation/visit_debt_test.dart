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
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';
import 'package:app/features/visits/presentation/widgets/visit_debt_banner.dart';

/// The stop carries a debt cached when the route was loaded; the visit must
/// ignore it and read the customer account only (S29).
final _stop = RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
    debtAmount: 800,
  ),
  status: StopStatus.pending,
  scheduledAt: DateTime(2026, 10, 28, 9),
);

void main() {
  Future<void> pumpVisit(WidgetTester tester, Stream<double> balance) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routeStopByIdProvider('s-1').overrideWithValue(_stop),
          customerBalanceProvider('c-1').overrideWith((_) => balance),
          stopSalesProvider('s-1').overrideWith((_) => Stream.value([])),
          visitPaymentsProvider('s-1').overrideWith((_) => Stream.value([])),
          visitMovementsProvider('s-1').overrideWith((_) async => []),
          customerContainerBalancesProvider(
            'c-1',
          ).overrideWith((_) => Stream.value([])),
          containerTypesProvider.overrideWith((_) => Stream.value([])),
          visitOutcomesProvider.overrideWith((_) => Stream.value(const [])),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [MarilinTokens.light]),
          home: const VisitScreen(stopId: 's-1'),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the debt of the customer account', (tester) async {
    await pumpVisit(tester, Stream.value(1500));

    final banner = tester.widget<VisitDebtBanner>(find.byType(VisitDebtBanner));
    expect(banner.debtAmount, 1500);
  });

  testWidgets('an account of 0 hides the stop debt', (tester) async {
    await pumpVisit(tester, Stream.value(0));

    expect(find.byType(VisitDebtBanner), findsNothing);
  });

  testWidgets('while the account loads the stop debt is not shown', (
    tester,
  ) async {
    await pumpVisit(tester, const Stream<double>.empty());

    expect(find.byType(VisitDebtBanner), findsNothing);
  });
}
