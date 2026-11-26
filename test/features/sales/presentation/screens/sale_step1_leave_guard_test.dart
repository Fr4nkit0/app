import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/products/presentation/providers/product_list_provider.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

const _product = Product(
  id: 'p1',
  name: 'Bidón 20L',
  unitLabel: 'bidón',
  price: 6500,
);

final _customer = Customer(
  id: 'c1',
  name: 'Romina Cardozo',
  addresses: const [],
  preferences: const [],
);

/// A sale opened from a visit: Nueva Venta pushed above the visit.
Future<ProviderContainer> _pushFromVisit(
  WidgetTester tester, {
  required bool withItems,
}) async {
  final container = ProviderContainer(
    overrides: [
      customerProductListProvider.overrideWith(
        (ref, id) => Stream.value(const [_product]),
      ),
    ],
  );
  addTearDown(container.dispose);
  final draft = container.read(saleDraftProvider.notifier);
  draft.selectCustomer(_customer, visitId: 'stop-1');
  if (withItems) {
    draft.setQuantity(const SaleItem(product: _product, quantity: 0), 1);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SaleStep1Screen()),
              ),
              child: const Text('Visita'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Visita'));
  await tester.pumpAndSettle();
  expect(find.text('Nueva Venta'), findsOneWidget);
  return container;
}

Future<void> _tapBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Volver'));
  await tester.pumpAndSettle();
}

void main() {
  group('leaving a sale opened from a visit', () {
    testWidgets('with products asks before discarding; Seguir editando '
        'keeps the sale', (tester) async {
      final container = await _pushFromVisit(tester, withItems: true);

      await _tapBack(tester);

      expect(find.text('¿Descartar la venta en curso?'), findsOneWidget);
      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva Venta'), findsOneWidget);
      expect(container.read(saleDraftProvider).items, hasLength(1));
      expect(container.read(saleDraftProvider).visitId, 'stop-1');
    });

    testWidgets('with products, Descartar leaves and empties the draft', (
      tester,
    ) async {
      final container = await _pushFromVisit(tester, withItems: true);

      await _tapBack(tester);
      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva Venta'), findsNothing);
      expect(find.text('Visita'), findsOneWidget);
      expect(container.read(saleDraftProvider).isEmpty, isTrue);
      expect(container.read(saleDraftProvider).visitId, isNull);
    });

    testWidgets('system back with products also asks', (tester) async {
      final container = await _pushFromVisit(tester, withItems: true);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      await navigator.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar la venta en curso?'), findsOneWidget);
      expect(container.read(saleDraftProvider).items, hasLength(1));
    });

    testWidgets('without products leaves at once and empties the draft', (
      tester,
    ) async {
      final container = await _pushFromVisit(tester, withItems: false);

      await _tapBack(tester);

      expect(find.text('¿Descartar la venta en curso?'), findsNothing);
      expect(find.text('Nueva Venta'), findsNothing);
      expect(container.read(saleDraftProvider), isA<SaleDraftState>());
      expect(container.read(saleDraftProvider).isEmpty, isTrue);
      expect(container.read(saleDraftProvider).visitId, isNull);
    });
  });
}
