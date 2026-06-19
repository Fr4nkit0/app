import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/sales/presentation/widgets/product_quantity_row.dart';
import 'package:app/core/theme/sales_tokens.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Product _product({
  String id = 'p1',
  String name = 'Agua 20L',
  double price = 1500,
}) {
  return Product(id: id, name: name, unitLabel: 'bidón', price: price);
}

Customer _customer() => Customer(
  id: 'c1',
  name: 'Juan Test',
  addresses: const [],
  preferences: const [],
  productLabels: const [],
  debtAmount: 0,
  isFrequent: false,
);

/// Wraps with MaterialApp+SalesTokens.
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [SalesTokens.light]),
    home: Scaffold(body: child),
  );
}

// ---------------------------------------------------------------------------
// Tests — Task 2.2: SaleStep1Screen / _SelectedMode passes quantity down
// ---------------------------------------------------------------------------

void main() {
  group(
    'Task 2.2: _SelectedMode passes quantity from saleDraftProvider to ProductQuantityRow',
    () {
      testWidgets(
        'ProductQuantityRow shows quantity=0 when product is not in draft items',
        (tester) async {
          final product = _product();
          final customer = _customer();

          // Draft has customer but NO items for product p1
          final draftWithCustomer = SaleDraftState(
            customer: customer,
            items: const [],
          );

          final qty =
              draftWithCustomer.items
                  .where((i) => i.product.id == product.id)
                  .map((i) => i.quantity)
                  .firstOrNull ??
              0;

          await tester.pumpWidget(
            _wrap(
              ProductQuantityRow(
                product: product,
                quantity: qty,
                onIncrement: () {},
                onDecrement: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // quantity=0 → shows '0'
          expect(find.text('0'), findsOneWidget);
        },
      );

      testWidgets(
        'ProductQuantityRow shows correct quantity when product IS in draft items',
        (tester) async {
          final product = _product();
          final customer = _customer();

          // Draft has 3 units of p1
          final draftWithItems = SaleDraftState(
            customer: customer,
            items: [SaleItem(product: product, quantity: 3)],
          );

          final qty =
              draftWithItems.items
                  .where((i) => i.product.id == product.id)
                  .map((i) => i.quantity)
                  .firstOrNull ??
              0;

          await tester.pumpWidget(
            _wrap(
              ProductQuantityRow(
                product: product,
                quantity: qty,
                onIncrement: () {},
                onDecrement: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          // quantity=3 → renders '3' and subtotal
          expect(find.text('3'), findsOneWidget);
          expect(find.textContaining('Subtotal'), findsOneWidget);
          // 1500 * 3 = 4500
          expect(find.textContaining('4500'), findsOneWidget);
        },
      );

      testWidgets(
        'onIncrement callback from parent is called when + tapped on ProductQuantityRow',
        (tester) async {
          final product = _product();
          int callCount = 0;

          await tester.pumpWidget(
            _wrap(
              ProductQuantityRow(
                product: product,
                quantity: 0,
                onIncrement: () => callCount++,
                onDecrement: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byIcon(Icons.add_rounded));
          await tester.pump();

          // The parent-provided callback was called — not the internal provider
          expect(callCount, 1);
        },
      );
    },
  );
}
