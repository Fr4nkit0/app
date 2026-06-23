import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';

void main() {
  testWidgets('CreateCustomerScreen diagnostics test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CreateCustomerScreen(),
        ),
      ),
    );

    // Initial step (Step 1: Datos) should render
    expect(find.text('Datos del cliente'), findsOneWidget);

    // Fill in name to make step 1 valid
    await tester.enterText(find.byType(TextFormField).first, 'Test Customer');
    await tester.pumpAndSettle();

    // Click "Siguiente" button
    final nextButton = find.text('Siguiente');
    expect(nextButton, findsOneWidget);
    await tester.tap(nextButton);
    
    // Pump and settle for the page transition
    await tester.pumpAndSettle();

    // Now we should be on Step 2 (Dirección)
    expect(find.text('¿Dónde hacemos las entregas?'), findsOneWidget);
    expect(find.text('Calle y altura / Manzana'), findsOneWidget);
  });
}
