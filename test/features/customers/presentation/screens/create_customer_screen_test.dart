import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/providers/customer_form_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';

/// Opens the wizard from a list screen, the way the driver reaches it.
Future<void> _openWizard(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateCustomerScreen(),
                  ),
                ),
                child: const Text('Clientes'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Clientes'));
  await tester.pumpAndSettle();
}

/// Types a name and lets the form state reach the screen.
Future<void> _typeName(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Nombre completo'),
    'Hotel Altos',
  );
  await tester.pump();
}

bool _focused(WidgetTester tester, String label) => tester
    .widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, label),
        matching: find.byType(EditableText),
      ),
    )
    .focusNode
    .hasFocus;

/// The phone's back button (or gesture).
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('CreateCustomerScreen diagnostics test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: CreateCustomerScreen())),
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

  group('leaving the new-customer wizard', () {
    testWidgets('with a name typed asks before discarding it', (tester) async {
      await _openWizard(tester);
      await _typeName(tester);

      await _systemBack(tester);

      expect(find.text('¿Descartar el cliente nuevo?'), findsOneWidget);
      expect(find.byType(CreateCustomerScreen), findsOneWidget);
    });

    testWidgets('keeps the data when the driver chooses to keep editing', (
      tester,
    ) async {
      await _openWizard(tester);
      await _typeName(tester);
      await _systemBack(tester);

      await tester.tap(find.text('Seguir editando'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateCustomerScreen), findsOneWidget);
      expect(find.text('Hotel Altos'), findsOneWidget);
    });

    testWidgets('discards and closes when the driver confirms', (tester) async {
      await _openWizard(tester);
      await _typeName(tester);
      await _systemBack(tester);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateCustomerScreen), findsNothing);
    });

    testWidgets('the app bar back asks too', (tester) async {
      await _openWizard(tester);
      await _typeName(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('¿Descartar el cliente nuevo?'), findsOneWidget);
    });

    testWidgets('on the address step goes back one step like Atrás', (
      tester,
    ) async {
      await _openWizard(tester);
      await _typeName(tester);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      await _systemBack(tester);

      expect(find.text('¿Descartar el cliente nuevo?'), findsNothing);
      expect(find.byType(CreateCustomerScreen), findsOneWidget);
      expect(find.text('Datos del cliente'), findsOneWidget);
      expect(find.text('Hotel Altos'), findsOneWidget);

      // Back on the first step still asks before dropping the data.
      await _systemBack(tester);
      expect(find.text('¿Descartar el cliente nuevo?'), findsOneWidget);
    });

    testWidgets('on the preferences step goes back to the address', (
      tester,
    ) async {
      await _openWizard(tester);
      await _typeName(tester);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Calle y altura / Manzana'),
        'Belgrano 1200',
      );
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CreateCustomerScreen)),
      );
      container.read(customerFormProvider.notifier)
        ..updateNeighborhood('Centro')
        ..nextStep();
      await tester.pumpAndSettle();
      expect(container.read(customerFormProvider).currentStep, 2);

      await _systemBack(tester);

      expect(find.text('¿Descartar el cliente nuevo?'), findsNothing);
      expect(container.read(customerFormProvider).currentStep, 1);
      expect(find.text('¿Dónde hacemos las entregas?'), findsOneWidget);
    });

    testWidgets('with nothing typed closes without asking', (tester) async {
      await _openWizard(tester);

      await _systemBack(tester);

      expect(find.text('¿Descartar el cliente nuevo?'), findsNothing);
      expect(find.byType(CreateCustomerScreen), findsNothing);
    });
  });

  group('keyboard', () {
    testWidgets('the name field moves on to the phone', (tester) async {
      await _openWizard(tester);
      final name = find.widgetWithText(TextFormField, 'Nombre completo');
      final phone = find.widgetWithText(TextFormField, 'Teléfono (opcional)');

      expect(
        tester
            .widget<TextField>(
              find.descendant(of: name, matching: find.byType(TextField)),
            )
            .textInputAction,
        TextInputAction.next,
      );

      await tester.enterText(name, 'Hotel Altos');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      final phoneField = tester.widget<EditableText>(
        find.descendant(of: phone, matching: find.byType(EditableText)),
      );
      expect(phoneField.focusNode.hasFocus, isTrue);
    });

    testWidgets('the address fields move on to the next one', (tester) async {
      await _openWizard(tester);
      await _typeName(tester);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      TextInputAction? actionOf(String label) => tester
          .widget<TextField>(
            find.descendant(
              of: find.widgetWithText(TextFormField, label),
              matching: find.byType(TextField),
            ),
          )
          .textInputAction;

      expect(actionOf('Calle y altura / Manzana'), TextInputAction.next);
      expect(actionOf('Piso'), TextInputAction.next);
      expect(actionOf('Depto / Lote'), TextInputAction.next);
      expect(actionOf('Referencia visual (opcional)'), TextInputAction.done);
    });

    testWidgets('the phone moves on to the street', (tester) async {
      await _openWizard(tester);
      await _typeName(tester);
      final phone = find.widgetWithText(TextFormField, 'Teléfono (opcional)');
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: phone, matching: find.byType(TextField)),
            )
            .textInputAction,
        TextInputAction.next,
      );

      await tester.enterText(phone, '3874001122');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(find.text('¿Dónde hacemos las entregas?'), findsOneWidget);
      expect(_focused(tester, 'Calle y altura / Manzana'), isTrue);
    });

    testWidgets('the phone stays put while the name is missing', (
      tester,
    ) async {
      await _openWizard(tester);
      final phone = find.widgetWithText(TextFormField, 'Teléfono (opcional)');

      await tester.enterText(phone, '3874001122');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      expect(find.text('Datos del cliente'), findsOneWidget);
      expect(find.text('Please fill in the required fields.'), findsNothing);
    });

    testWidgets('the floor moves on to the apartment and it to the reference', (
      tester,
    ) async {
      await _openWizard(tester);
      await _typeName(tester);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Piso'), '3');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focused(tester, 'Depto / Lote'), isTrue);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Depto / Lote'),
        'A',
      );
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(_focused(tester, 'Referencia visual (opcional)'), isTrue);
    });

    testWidgets(
      'the reference is a single-line text keyboard, so Enter adds no newline',
      (tester) async {
        await _openWizard(tester);
        await _typeName(tester);
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();

        final reference = tester.widget<TextField>(
          find.descendant(
            of: find.widgetWithText(
              TextFormField,
              'Referencia visual (opcional)',
            ),
            matching: find.byType(TextField),
          ),
        );
        expect(reference.keyboardType, TextInputType.text);
        expect(reference.textInputAction, TextInputAction.done);
      },
    );

    testWidgets('Siguiente stays above the open keyboard on a Moto G6', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2160);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      await _openWizard(tester);

      // The soft keyboard takes the lower ~300 dp of the screen.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 2.625);
      await tester.pumpAndSettle();

      final screenHeight = 2160 / 2.625;
      final button = tester.getRect(
        find.widgetWithText(FilledButton, 'Siguiente'),
      );
      expect(button.bottom, lessThanOrEqualTo(screenHeight - 300));
      expect(
        find.widgetWithText(FilledButton, 'Siguiente').hitTestable(),
        findsOneWidget,
      );
    });
  });
}
