import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/widgets/discard_sale_dialog.dart';

void main() {
  group('SaleDraftState.isEmpty', () {
    const product = Product(
      id: 'p1',
      name: 'Agua 20L',
      unitLabel: 'bidón',
      price: 1500,
    );

    test('is true with no customer and no lines', () {
      expect(const SaleDraftState().isEmpty, isTrue);
    });

    test('is false once a line is added', () {
      final state = SaleDraftState(
        items: [SaleItem(product: product, quantity: 1)],
      );
      expect(state.isEmpty, isFalse);
    });

    test('is false once a customer is chosen', () {
      final customer = Customer(
        id: 'c1',
        name: 'Kiosco Norte',
        addresses: const [],
        preferences: const [],
      );
      expect(SaleDraftState(customer: customer).isEmpty, isFalse);
    });
  });

  group('confirmDiscardSale', () {
    Future<Future<bool>> open(WidgetTester tester) async {
      late Future<bool> result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => result = confirmDiscardSale(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('names what is lost and offers to keep editing', (
      tester,
    ) async {
      final result = await open(tester);

      expect(find.text('¿Descartar la venta en curso?'), findsOneWidget);
      expect(find.text('Vas a perder los productos cargados.'), findsOneWidget);

      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('returns true on Descartar', (tester) async {
      final result = await open(tester);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(await result, isTrue);
    });

    testWidgets('dismissing the dialog keeps the sale', (tester) async {
      final result = await open(tester);

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(await result, isFalse);
    });
  });
}
