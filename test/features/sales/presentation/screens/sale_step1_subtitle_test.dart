import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/products/presentation/providers/product_list_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

final _customer = Customer(
  id: 'c-1',
  name: 'Hotel Altos',
  addresses: [],
  preferences: [],
);

Future<ProviderContainer> _pump(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      customerListProvider.overrideWith((ref) => Stream.value([_customer])),
      customerProductListProvider.overrideWith((ref, id) => Stream.value(const <Product>[])),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.lightTheme, home: const SaleStep1Screen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('with no customer chosen it asks for one', (tester) async {
    await _pump(tester);

    expect(find.text('Elegí el cliente para registrar la venta'), findsOneWidget);
  });

  testWidgets('with the customer already chosen it asks for the products instead', (tester) async {
    final container = await _pump(tester);

    container.read(saleDraftProvider.notifier).selectCustomer(_customer);
    await tester.pumpAndSettle();

    expect(find.text('Elegí el cliente para registrar la venta'), findsNothing);
    expect(find.text('Elegí los productos de la venta'), findsOneWidget);
  });
}
