import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/presentation/widgets/product_quantity_row.dart';

const _product = Product(
  id: 'p1',
  name: 'Agua 20L',
  unitLabel: 'bidón',
  price: 1500,
);

Widget _wrap(Widget child) => MaterialApp(
  theme: ThemeData(extensions: [SalesTokens.light]),
  home: Scaffold(body: child),
);

Widget _row({
  Product product = _product,
  int quantity = 3,
  VoidCallback? onIncrement,
  VoidCallback? onDecrement,
  ValueChanged<int>? onQuantitySubmitted,
}) => _wrap(
  ProductQuantityRow(
    product: product,
    quantity: quantity,
    onIncrement: onIncrement ?? () {},
    onDecrement: onDecrement ?? () {},
    onQuantitySubmitted: onQuantitySubmitted,
  ),
);

void main() {
  group('S1 glove-sized stepper', () {
    testWidgets('buttons are at least 56x48 and the number is >= 20sp', (
      tester,
    ) async {
      await tester.pumpWidget(_row());

      for (final icon in [Icons.remove_rounded, Icons.add_rounded]) {
        final size = tester.getSize(
          find.ancestor(of: find.byIcon(icon), matching: find.byType(Ink)),
        );
        expect(size.width, greaterThanOrEqualTo(56));
        expect(size.height, greaterThanOrEqualTo(48));
        expect(tester.widget<Icon>(find.byIcon(icon)).size, 24);
      }

      final text = tester.widget<Text>(find.text('3'));
      expect(text.style!.fontSize, greaterThanOrEqualTo(20));
    });

    testWidgets('holding + repeats the increment', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_row(onIncrement: () => taps++));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.add_rounded)),
      );
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pump();

      expect(taps, greaterThan(1));
    });

    testWidgets('a single tap increments once', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_row(onIncrement: () => taps++));

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump(const Duration(seconds: 1));

      expect(taps, 1);
    });
  });

  group('S2 numeric entry', () {
    Future<void> openDialog(WidgetTester tester) async {
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
    }

    testWidgets('accepting 12 submits 12', (tester) async {
      final submitted = <int>[];
      await tester.pumpWidget(_row(onQuantitySubmitted: submitted.add));

      await openDialog(tester);
      expect(find.text('Cantidad'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '12');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(submitted, [12]);
      expect(find.text('Cantidad'), findsNothing);
    });

    for (final input in ['', '1000', 'abc']) {
      testWidgets('invalid input "$input" keeps the value', (tester) async {
        final submitted = <int>[];
        await tester.pumpWidget(_row(onQuantitySubmitted: submitted.add));

        await openDialog(tester);
        await tester.enterText(find.byType(TextField), input);
        await tester.tap(find.text('Aceptar'));
        await tester.pumpAndSettle();

        expect(submitted, isEmpty);
      });
    }

    testWidgets('Cancelar submits nothing', (tester) async {
      final submitted = <int>[];
      await tester.pumpWidget(_row(onQuantitySubmitted: submitted.add));

      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '7');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(find.text('Cantidad'), findsNothing);
    });

    Product stocked(int available) => Product(
      id: 'p1',
      name: 'Agua 20L',
      unitLabel: 'bidón',
      price: 1500,
      available: available,
    );

    testWidgets('shows the truck stock and still accepts more than it', (
      tester,
    ) async {
      final submitted = <int>[];
      await tester.pumpWidget(
        _row(product: stocked(34), onQuantitySubmitted: submitted.add),
      );

      await openDialog(tester);
      expect(find.text('En el camión: 34'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '50');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(submitted, [50]);
    });

    testWidgets('shows a negative truck stock as is', (tester) async {
      final submitted = <int>[];
      await tester.pumpWidget(
        _row(product: stocked(-3), onQuantitySubmitted: submitted.add),
      );

      await openDialog(tester);
      expect(find.text('En el camión: -3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '2');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(submitted, [2]);
    });

    testWidgets('shows no truck stock when it is unknown', (tester) async {
      await tester.pumpWidget(_row(onQuantitySubmitted: (_) {}));

      await openDialog(tester);

      expect(find.textContaining('En el camión'), findsNothing);
    });

    testWidgets('over 999 still asks for 0 to 999 with the stock shown', (
      tester,
    ) async {
      final submitted = <int>[];
      await tester.pumpWidget(
        _row(product: stocked(34), onQuantitySubmitted: submitted.add),
      );

      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '1000');
      await tester.tap(find.text('Aceptar'));
      await tester.pumpAndSettle();

      expect(submitted, isEmpty);
      expect(find.text('Ingresá un número entre 0 y 999'), findsOneWidget);
    });

    testWidgets('does nothing when onQuantitySubmitted is null', (
      tester,
    ) async {
      await tester.pumpWidget(_row());

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(find.text('Cantidad'), findsNothing);
    });
  });
}
