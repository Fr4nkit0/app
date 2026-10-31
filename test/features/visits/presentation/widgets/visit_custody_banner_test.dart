import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  List<CustomerContainerBalance> balances, {
  List<ContainerType> types = const [
    ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L'),
    ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L'),
    ContainerType(id: 3, code: 'CRATE', label: 'Cajón'),
  ],
  double textScale = 1,
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      containerTypesProvider.overrideWith((_) => Stream.value(types)),
      customerContainerBalancesProvider(
        'c-1',
      ).overrideWith((_) => Stream.value(balances)),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: [MarilinTokens.light]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      // The horizontal padding of the visit screen.
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: VisitCustodyBanner(stop: _stop),
        ),
      ),
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

    expect(find.text('Bidón 20L · 0'), findsOneWidget);
    expect(find.text('Sifón 1.5L · 0'), findsOneWidget);
    expect(find.text('Cajón · 7'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  for (final textScale in [1.0, 1.3]) {
    testWidgets('on a 360dp phone at text scale $textScale the chips show the '
        'full name and quantity', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(
        tester,
        const [
          CustomerContainerBalance(
            customerId: 'c-1',
            containerType: 'JUG',
            quantity: 4,
          ),
          CustomerContainerBalance(
            customerId: 'c-1',
            containerType: 'SIPHON',
            quantity: 2,
          ),
        ],
        types: const [
          ContainerType(id: 1, code: 'JUG', label: 'Bidón 20L'),
          ContainerType(id: 2, code: 'SIPHON', label: 'Sifón 1.5L'),
        ],
        textScale: textScale,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final chip in ['Bidón 20L · 4', 'Sifón 1.5L · 2']) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: find.text(chip), matching: find.byType(RichText)),
        );
        // Laid out at its natural width: neither cut nor broken into lines.
        expect(paragraph.didExceedMaxLines, isFalse, reason: chip);
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(
            paragraph.getMaxIntrinsicWidth(double.infinity) - 0.01,
          ),
          reason: chip,
        );
      }
    });
  }

  testWidgets('without custody there is nothing to return', (tester) async {
    await _pump(tester, const []);
    await tester.pumpAndSettle();

    expect(find.text('Envases bajo custodia'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });
}
