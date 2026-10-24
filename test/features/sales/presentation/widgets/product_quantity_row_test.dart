import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/sales/presentation/widgets/product_quantity_row.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/core/theme/sales_tokens.dart';

// Helper to create a test Product
Product _makeProduct({String name = 'Agua 20L', double price = 1500}) {
  return Product(id: 'p1', name: name, unitLabel: 'bidón', price: price);
}

// Minimal MaterialApp wrapper with SalesTokens extension
Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [SalesTokens.light]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('ProductQuantityRow (pure StatelessWidget)', () {
    test('ProductQuantityRow is a StatelessWidget (not ConsumerWidget)', () {
      // Structural check — verify the widget can be instantiated with
      // pure constructor args (no ref/provider needed).
      final product = _makeProduct();
      final row = ProductQuantityRow(
        product: product,
        quantity: 0,
        onIncrement: () {},
        onDecrement: () {},
      );
      expect(row, isA<StatelessWidget>());
    });

    testWidgets('renders product name and price', (tester) async {
      final product = _makeProduct(name: 'Soda 1.5L', price: 900);
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: product,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      );
      expect(find.text('Soda 1.5L'), findsOneWidget);
      expect(find.textContaining('\$900'), findsOneWidget);
      expect(find.textContaining('acuerdo'), findsNothing);
    });

    testWidgets('marks a price that comes from the customer agreement', (
      tester,
    ) async {
      const product = Product(
        id: 'p1',
        name: 'Agua 20L',
        unitLabel: 'bidón',
        price: 1200,
        agreementId: 31,
      );
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: product,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      );
      expect(find.text('\$1200 c/u · acuerdo'), findsOneWidget);
    });

    testWidgets('calls onIncrement when + button is tapped', (tester) async {
      var incrementCalled = 0;
      final product = _makeProduct();
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: product,
            quantity: 0,
            onIncrement: () => incrementCalled++,
            onDecrement: () {},
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(incrementCalled, 1);
    });

    testWidgets('calls onDecrement when - button is tapped (quantity > 0)', (
      tester,
    ) async {
      var decrementCalled = 0;
      final product = _makeProduct();
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: product,
            quantity: 2,
            onIncrement: () {},
            onDecrement: () => decrementCalled++,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();
      expect(decrementCalled, 1);
    });

    // Subtotal test removed as ProductQuantityRow no longer displays subtotal

    testWidgets('decrement button is disabled when quantity is 0', (
      tester,
    ) async {
      var decrementCalled = 0;
      final product = _makeProduct();
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: product,
            quantity: 0,
            onIncrement: () {},
            onDecrement: () => decrementCalled++,
          ),
        ),
      );
      // Try tapping the remove button — it should be disabled (onTap: null)
      await tester.tap(find.byIcon(Icons.remove_rounded), warnIfMissed: false);
      await tester.pump();
      expect(decrementCalled, 0);
    });
  
    testWidgets('a product without price shows it and cannot be incremented', (
      tester,
    ) async {
      var incrementCalled = 0;
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: _makeProduct(price: 0),
            quantity: 0,
            onIncrement: () => incrementCalled++,
            onDecrement: () {},
          ),
        ),
      );

      expect(find.text('Sin precio'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(incrementCalled, 0);
    });
  });
}
