import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sales/presentation/providers/register_sale_usecase_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/container_types.dart';
import '../../../../support/real_fonts.dart';

class _RecordingRegisterSale implements RegisterSaleUseCase {
  final calls = <({Sale sale, double debtAmount})>[];
  List<ContainerMovement>? movements;

  @override
  Future<void> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
    double debtAmount = 0,
  }) async {
    movements = containerMovements;
    calls.add((sale: sale, debtAmount: debtAmount));
  }
}

class _PreparedDraft extends SaleDraft {
  _PreparedDraft(this._method, this._containerType);

  final PaymentMethod _method;
  final String? _containerType;

  // One jug of 6500.
  @override
  SaleDraftState build() => SaleDraftState(
    customer: Customer(
      id: 'c-1',
      name: 'Kiosco Norte',
      addresses: const [],
      preferences: const [],
    ),
    items: [
      SaleItem(
        product: Product(
          id: 'p-1',
          name: 'Bidón 20L',
          unitLabel: 'bidón',
          price: 6500,
          containerType: _containerType,
        ),
        quantity: 1,
      ),
    ],
    returnedContainers: {?_containerType: 1},
    paymentMethod: _method,
  );
}

/// Partial payment in sale step 3 (S2, S3, S4) on a 360dp phone.
void main() {
  setUpAll(() async {
    expect(
      await loadRealFonts(),
      isTrue,
      reason: 'Roboto was not found in the Flutter SDK cache',
    );
  });

  late _RecordingRegisterSale useCase;

  Future<void> pumpScreen(
    WidgetTester tester, {
    required PaymentMethod method,
    double debt = 0,
    String? containerType,
    List<CustomerContainerBalance> custody = const [],
  }) async {
    useCase = _RecordingRegisterSale();
    // A fresh tree for every pump, also within one test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleDraftProvider.overrideWith(
            () => _PreparedDraft(method, containerType),
          ),
          registerSaleUseCaseProvider.overrideWithValue(useCase),
          customerBalanceProvider.overrideWith((ref, id) => Stream.value(debt)),
          customerContainerBalancesProvider.overrideWith(
            (ref, id) => Stream.value(custody),
          ),
          containerTypesProvider.overrideWith(
            (ref) => Stream.value(catalogContainerTypes),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SaleStep3Screen(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final collectedField = find.widgetWithText(TextField, 'Monto recibido');
  final confirmButton = find.widgetWithText(FilledButton, 'Confirmar');
  const partialQuestion = 'El cliente queda debiendo \$500. ¿Confirmás?';

  Finder inDialog(Finder finder) =>
      find.descendant(of: find.byType(AlertDialog), matching: finder);

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirmButton.first).onPressed != null;

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;

  Future<void> tapConfirm(WidgetTester tester) async {
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }

  group('S2: "Monto recibido" for cash and transfer', () {
    testWidgets('starts at the total with nothing owed', (tester) async {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        await pumpScreen(tester, method: method);

        expect(collectedField, findsOneWidget, reason: method.name);
        expect(textOf(tester, collectedField), '6500', reason: method.name);
        expect(find.textContaining('Queda debiendo'), findsNothing);
        expect(confirmEnabled(tester), isTrue, reason: method.name);
        expect(tester.takeException(), isNull, reason: method.name);
      }
    });

    testWidgets('lowered to 6000 shows "Queda debiendo \$500" without '
        'overflowing at 360dp', (tester) async {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        await pumpScreen(tester, method: method);

        await tester.enterText(collectedField, '6000');
        await tester.pump();

        expect(
          find.text('Queda debiendo \$500'),
          findsOneWidget,
          reason: method.name,
        );
        expect(confirmEnabled(tester), isTrue, reason: method.name);
        expect(tester.takeException(), isNull, reason: method.name);
      }
    });

    testWidgets('0 or empty blocks Confirmar', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash);

      for (final text in ['0', '']) {
        await tester.enterText(collectedField, text);
        await tester.pump();
        expect(confirmEnabled(tester), isFalse, reason: '"$text"');
        expect(find.textContaining('Queda debiendo'), findsNothing);
      }
    });

    testWidgets('hidden for credit', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.credit);

      expect(collectedField, findsNothing);
      expect(find.textContaining('Queda debiendo'), findsNothing);
    });
  });

  testWidgets('S2: mixed 4000 + 2000 shows "Queda debiendo \$500" at '
      '360dp', (tester) async {
    await pumpScreen(tester, method: PaymentMethod.mixed);

    expect(collectedField, findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Efectivo'), '4000');
    await tester.enterText(
      find.widgetWithText(TextField, 'Transferencia'),
      '2000',
    );
    await tester.pump();

    expect(find.text('Queda debiendo \$500'), findsOneWidget);
    expect(find.textContaining('Falta'), findsNothing);
    expect(confirmEnabled(tester), isTrue);
    expect(tester.takeException(), isNull);
  });

  group('S4: confirming a partial sale asks first', () {
    testWidgets('shows "El cliente queda debiendo \$500. ¿Confirmás?"', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.cash);
      await tester.enterText(collectedField, '6000');
      await tester.pump();

      await tapConfirm(tester);

      expect(find.text(partialQuestion), findsOneWidget);
      expect(inDialog(find.text('Cancelar')), findsOneWidget);
      expect(inDialog(find.text('Confirmar')), findsOneWidget);
      expect(useCase.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Cancelar goes back to step 3 and saves nothing', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.cash);
      await tester.enterText(collectedField, '6000');
      await tester.pump();
      await tapConfirm(tester);

      await tester.tap(inDialog(find.text('Cancelar')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SaleStep3Screen), findsOneWidget);
      expect(textOf(tester, collectedField), '6000');
      expect(useCase.calls, isEmpty);
    });

    testWidgets('Confirmar saves the sale with the collected amount', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.transfer);
      await tester.enterText(collectedField, '6000');
      await tester.pump();
      await tapConfirm(tester);

      await tester.tap(inDialog(find.text('Confirmar')));
      await tester.pumpAndSettle(const Duration(seconds: 4));

      final sale = useCase.calls.single.sale;
      expect(sale.total, 6500);
      expect(sale.paymentMethod, PaymentMethod.transfer);
      expect(sale.settlement.transfer, 6000);
      expect(find.byType(SaleStep3Screen), findsNothing);
    });

    testWidgets('then the container returns, and Cancelar skips them', (
      tester,
    ) async {
      const custody = [
        CustomerContainerBalance(
          customerId: 'c-1',
          containerType: 'BIDON_20L',
          quantity: 5,
        ),
      ];
      await pumpScreen(
        tester,
        method: PaymentMethod.cash,
        containerType: 'BIDON_20L',
        custody: custody,
      );
      await tester.enterText(collectedField, '6000');
      await tester.pump();

      await tapConfirm(tester);
      await tester.tap(inDialog(find.text('Cancelar')));
      await tester.pumpAndSettle();
      expect(find.text('Retorno de Envases'), findsNothing);
      expect(useCase.calls, isEmpty);

      await tapConfirm(tester);
      await tester.tap(inDialog(find.text('Confirmar')));
      await tester.pumpAndSettle();
      expect(find.text('Retorno de Envases'), findsOneWidget);
      expect(useCase.calls, isEmpty);

      await tester.tap(
        inDialog(find.widgetWithText(FilledButton, 'Confirmar')),
      );
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(useCase.calls, hasLength(1));
      expect(useCase.calls.single.sale.settlement.cash, 6000);
      expect(useCase.movements!.single.returnedQuantity, 1);
    });
  });

  testWidgets('S6: a full payment confirms without asking, for every '
      'method', (tester) async {
    for (final method in [
      PaymentMethod.cash,
      PaymentMethod.transfer,
      PaymentMethod.mixed,
      PaymentMethod.credit,
    ]) {
      await pumpScreen(tester, method: method);
      if (method == PaymentMethod.mixed) {
        await tester.ensureVisible(find.text('Todo en efectivo'));
        await tester.tap(find.text('Todo en efectivo'));
        await tester.pump();
      }

      await tapConfirm(tester);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      expect(find.text(partialQuestion), findsNothing, reason: method.name);
      expect(useCase.calls, hasLength(1), reason: method.name);
      expect(useCase.calls.single.sale.total, 6500, reason: method.name);
    }
  });
}
