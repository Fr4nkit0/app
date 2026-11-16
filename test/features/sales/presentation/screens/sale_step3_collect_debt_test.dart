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

  @override
  Future<void> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
    double debtAmount = 0,
  }) async {
    calls.add((sale: sale, debtAmount: debtAmount));
  }
}

class _PreparedDraft extends SaleDraft {
  _PreparedDraft(this._method);

  final PaymentMethod _method;

  // Two of 6500: a sale of 13000.
  @override
  SaleDraftState build() => SaleDraftState(
    customer: Customer(
      id: 'c-1',
      name: 'Kiosco Norte',
      addresses: const [],
      preferences: const [],
    ),
    items: const [
      SaleItem(
        product: Product(
          id: 'p-1',
          name: 'Agua 20L',
          unitLabel: 'bidón',
          price: 6500,
        ),
        quantity: 2,
      ),
    ],
    paymentMethod: _method,
  );
}

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
    required double debt,
  }) async {
    useCase = _RecordingRegisterSale();
    // A fresh tree for every pump, also within one test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleDraftProvider.overrideWith(() => _PreparedDraft(method)),
          registerSaleUseCaseProvider.overrideWithValue(useCase),
          customerBalanceProvider.overrideWith((ref, id) => Stream.value(debt)),
          customerContainerBalancesProvider.overrideWith(
            (ref, id) => Stream.value(const <CustomerContainerBalance>[]),
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

  final collectDebt = find.text('Cobrar también la deuda');
  final confirmButton = find.widgetWithText(FilledButton, 'Confirmar');
  final debtField = find.widgetWithText(TextField, 'Deuda a cobrar');

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirmButton).onPressed != null;

  String textOf(WidgetTester tester, String label) => tester
      .widget<TextField>(find.widgetWithText(TextField, label))
      .controller!
      .text;

  Future<void> switchOn(WidgetTester tester) async {
    await tester.ensureVisible(collectDebt);
    await tester.tap(collectDebt);
    await tester.pumpAndSettle();
  }

  group('S4: when the switch is offered', () {
    testWidgets('hidden for a customer without debt', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, debt: 0);

      expect(collectDebt, findsNothing);
      expect(find.textContaining('Total a cobrar'), findsNothing);
    });

    testWidgets('hidden for a credit sale even with debt', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.credit, debt: 7200);

      expect(collectDebt, findsNothing);
    });

    testWidgets('offered for cash, transfer and mixed with the current '
        'debt visible', (tester) async {
      for (final method in [
        PaymentMethod.cash,
        PaymentMethod.transfer,
        PaymentMethod.mixed,
      ]) {
        await pumpScreen(tester, method: method, debt: 7200);

        expect(collectDebt, findsOneWidget, reason: method.name);
        expect(
          find.text('Deuda actual \$7.200'),
          findsOneWidget,
          reason: method.name,
        );
        expect(debtField, findsNothing, reason: 'off by default');
      }
    });

    testWidgets('choosing credit turns it off and hides it', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.transfer, debt: 7200);
      await switchOn(tester);

      await tester.tap(find.text(PaymentMethod.credit.label));
      await tester.pumpAndSettle();

      expect(collectDebt, findsNothing);
      expect(debtField, findsNothing);
      expect(find.textContaining('Total a cobrar'), findsNothing);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(useCase.calls.single.debtAmount, 0);
    });
  });

  testWidgets('S9: a 13000 transfer sale with 7200 of debt shows the whole '
      'debt and the 20200 total, and confirms with debtAmount 7200', (
    tester,
  ) async {
    await pumpScreen(tester, method: PaymentMethod.transfer, debt: 7200);

    await switchOn(tester);

    expect(textOf(tester, 'Deuda a cobrar'), '7200');
    expect(find.text('Total a cobrar \$20.200'), findsOneWidget);
    expect(confirmEnabled(tester), isTrue);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    final call = useCase.calls.single;
    expect(call.debtAmount, 7200);
    expect(call.sale.total, 13000);
    expect(call.sale.paymentMethod, PaymentMethod.transfer);
  });

  group('S5: editable debt amount', () {
    testWidgets('a lower amount updates the total', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, debt: 7200);
      await switchOn(tester);

      await tester.enterText(debtField, '3000');
      await tester.pump();

      expect(find.text('Total a cobrar \$16.000'), findsOneWidget);
      expect(confirmEnabled(tester), isTrue);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(useCase.calls.single.debtAmount, 3000);
    });

    testWidgets('an amount above the debt shows why and blocks confirm', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.transfer, debt: 7200);
      await switchOn(tester);

      await tester.enterText(debtField, '8000');
      await tester.pump();

      expect(find.text('No puede superar la deuda de \$7.200'), findsOneWidget);
      expect(confirmEnabled(tester), isFalse);
    });

    testWidgets('0 or an empty amount shows why and blocks confirm', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.transfer, debt: 7200);
      await switchOn(tester);

      for (final text in ['0', '']) {
        await tester.enterText(debtField, text);
        await tester.pump();

        expect(
          find.text('Ingresá un monto mayor a \$0'),
          findsOneWidget,
          reason: '"$text"',
        );
        expect(confirmEnabled(tester), isFalse, reason: '"$text"');
      }
    });

    testWidgets('switching off drops the debt from the operation', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.cash, debt: 7200);
      await switchOn(tester);
      await switchOn(tester);

      expect(debtField, findsNothing);
      expect(find.textContaining('Total a cobrar'), findsNothing);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(useCase.calls.single.debtAmount, 0);
    });
  });

  group('S6: mixed with debt', () {
    testWidgets('cash + transfer must equal the sale plus the debt', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.mixed, debt: 7200);
      await switchOn(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Efectivo'),
        '5000',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Transferencia'),
        '8000',
      );
      await tester.pump();

      expect(find.text('Falta: \$7.200'), findsOneWidget);
      expect(confirmEnabled(tester), isFalse);

      await tester.enterText(
        find.widgetWithText(TextField, 'Transferencia'),
        '15200',
      );
      await tester.pump();

      expect(find.text('Cubierto'), findsOneWidget);
      expect(confirmEnabled(tester), isTrue);
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      final call = useCase.calls.single;
      expect(call.debtAmount, 7200);
      expect((call.sale.cashAmount, call.sale.transferAmount), (5000, 15200));
    });

    testWidgets('quick chips fill against the sale plus the debt', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.mixed, debt: 7200);
      await switchOn(tester);

      await tester.ensureVisible(find.text('Todo por transferencia'));
      await tester.tap(find.text('Todo por transferencia'));
      await tester.pump();

      expect(textOf(tester, 'Efectivo'), '0');
      expect(textOf(tester, 'Transferencia'), '20200');
      expect(confirmEnabled(tester), isTrue);
    });
  });
}
