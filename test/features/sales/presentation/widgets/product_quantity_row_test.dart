import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/sales/presentation/widgets/product_quantity_row.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/core/theme/sales_tokens.dart';

import '../../../../support/real_fonts.dart';

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
      expect(find.text('\$1.200 c/u · acuerdo'), findsOneWidget);
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

      expect(find.text('Sin precio · no se puede vender'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(incrementCalled, 0);
    });
  });

  group('ProductQuantityRow truck stock warning', () {
    Product stocked(int available) => Product(
      id: 'p1',
      name: 'Agua 20L',
      unitLabel: 'bidón',
      price: 1500,
      available: available,
    );

    testWidgets('warns when the quantity exceeds the truck stock and still '
        'allows adding more', (tester) async {
      var increments = 0;
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: stocked(3),
            quantity: 5,
            onIncrement: () => increments++,
            onDecrement: () {},
          ),
        ),
      );

      expect(find.text('Solo quedan 3 en el camión'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(increments, 1);
    });

    testWidgets('shows no warning within the truck stock', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: stocked(3),
            quantity: 3,
            onIncrement: () {},
            onDecrement: () {},
          ),
        ),
      );

      expect(find.textContaining('Solo quedan'), findsNothing);
    });

    testWidgets('shows a negative truck stock as negative and still allows '
        'adding more', (tester) async {
      var increments = 0;
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: stocked(-1),
            quantity: 1,
            onIncrement: () => increments++,
            onDecrement: () {},
          ),
        ),
      );

      expect(find.text('Sin stock en el camión (-1)'), findsOneWidget);
      expect(find.textContaining('Solo quedan'), findsNothing);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(increments, 1);
    });

    testWidgets('a day without a route (stock 0) warns without blocking', (
      tester,
    ) async {
      var increments = 0;
      await tester.pumpWidget(
        _wrap(
          ProductQuantityRow(
            product: stocked(0),
            quantity: 1,
            onIncrement: () => increments++,
            onDecrement: () {},
          ),
        ),
      );

      expect(find.text('Sin stock en el camión (0)'), findsOneWidget);
      expect(find.textContaining('Solo quedan'), findsNothing);
      await tester.tap(find.byIcon(Icons.add_rounded));
      expect(increments, 1);
    });

    testWidgets('the negative warning is no taller than the low stock one on '
        'a narrow phone', (tester) async {
      expect(
        await loadRealFonts(),
        isTrue,
        reason: 'Roboto was not found in the Flutter SDK cache',
      );
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<double> rowHeight(int available) async {
        await tester.pumpWidget(
          _wrap(
            ListView(
              children: [
                ProductQuantityRow(
                  product: stocked(available),
                  quantity: 5,
                  onIncrement: () {},
                  onDecrement: () {},
                ),
              ],
            ),
          ),
        );
        return tester.getSize(find.byType(ProductQuantityRow)).height;
      }

      final lowStock = await rowHeight(3);
      expect(await rowHeight(-12), lessThanOrEqualTo(lowStock));
    });

    testWidgets('the stepper does not move when the warning appears or goes '
        'away on a narrow phone', (tester) async {
      expect(
        await loadRealFonts(),
        isTrue,
        reason: 'Roboto was not found in the Flutter SDK cache',
      );
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<List<Offset>> stepperAt(int available, int quantity) async {
        await tester.pumpWidget(
          // The sale screen lists the rows in a scroll view, so a row is
          // as tall as its content.
          _wrap(
            ListView(
              children: [
                ProductQuantityRow(
                  product: stocked(available),
                  quantity: quantity,
                  onIncrement: () {},
                  onDecrement: () {},
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        return [
          tester.getCenter(find.byIcon(Icons.remove_rounded)),
          tester.getCenter(find.text('$quantity')),
          tester.getCenter(find.byIcon(Icons.add_rounded)),
        ];
      }

      // The QA repro: 35 over a stock of 34 warns, 34 does not.
      final warned = await stepperAt(34, 35);
      expect(find.text('Solo quedan 34 en el camión'), findsOneWidget);
      final clear = await stepperAt(34, 34);
      expect(find.textContaining('en el camión'), findsNothing);
      for (var i = 0; i < 3; i++) {
        expect(clear[i].dy, closeTo(warned[i].dy, 0.01));
      }

      final negative = await stepperAt(-12, 35);
      expect(find.text('Sin stock en el camión (-12)'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        expect(negative[i].dy, closeTo(clear[i].dy, 0.01));
      }
    });
  });

  testWidgets('the stepper buttons are labelled for TalkBack', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        ProductQuantityRow(
          product: _makeProduct(name: 'Soda 1.5L'),
          quantity: 1,
          onIncrement: () {},
          onDecrement: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Quitar una Soda 1.5L'), findsOneWidget);
    expect(find.bySemanticsLabel('Agregar una Soda 1.5L'), findsOneWidget);
    semantics.dispose();
  });
}
