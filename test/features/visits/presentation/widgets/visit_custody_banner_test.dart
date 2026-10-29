import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/presentation/widgets/visit_custody_banner.dart';

final _stop = RouteStop(
  id: 's-1',
  customer: Customer(
    id: 'c-1',
    name: 'Kiosco',
    addresses: const [],
    preferences: const [],
  ),
  status: StopStatus.pending,
  scheduledAt: DateTime(2026, 10, 28, 9),
);

Future<void> _pump(
  WidgetTester tester,
  List<CustomerContainerBalance> balances,
) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      containerTypesProvider.overrideWith(
        (_) => Stream.value(const [
          ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L'),
          ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L'),
          ContainerType(id: 3, code: 'CRATE', label: 'Cajón'),
        ]),
      ),
      customerContainerBalancesProvider(
        'c-1',
      ).overrideWith((_) => Stream.value(balances)),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [MarilinTokens.light]),
      home: Scaffold(body: VisitCustodyBanner(stop: _stop)),
    ),
  ),
);

void main() {
  testWidgets('shows the custody of every catalog type by its label', (
    tester,
  ) async {
    await _pump(tester, const [
      CustomerContainerBalance(
        customerId: 'c-1',
        containerType: 'CRATE',
        quantity: 7,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Bidón 20L: '), findsOneWidget);
    expect(find.text('Sifón 1.5L: '), findsOneWidget);
    expect(find.text('Cajón: '), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('without custody there is nothing to return', (tester) async {
    await _pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.text('Envases bajo custodia'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });
}
