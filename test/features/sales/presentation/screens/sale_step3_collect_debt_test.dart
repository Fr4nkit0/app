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
  final calls = <({Sale sale, int debtAmount})>[];

  @override
  Future<void> execute(
    Sale sale, {
    Payment? payment,
    List<ContainerMovement>? containerMovements,
    int debtAmount = 0,
  }) async {
    calls.add((sale: sale, debtAmount: debtAmount));
  }
}

class _PreparedDraft extends SaleDraft {
  _PreparedDraft(this._method);

  final PaymentMethod _method;

  // One of 6500: a sale of 6500.
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
        quantity: 1,
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
    required int balance,
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
          customerBalanceProvider.overrideWith(
            (ref, id) => Stream.value(balance),
          ),
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

  final receivedField = find.widgetWithText(TextField, 'Monto recibido');
  final confirmButton = find.widgetWithText(FilledButton, 'Confirmar');

  bool confirmEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(confirmButton).onPressed != null;

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;

  Future<void> receive(WidgetTester tester, String text) async {
    await tester.enterText(receivedField, text);
    await tester.pump();
  }

  Future<void> tapConfirm(WidgetTester tester) async {
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  }

  group('S2: the received amount replaces the debt switch', () {
    testWidgets('cash and transfer start at the sale total with no '
        'breakdown and no debt switch', (tester) async {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        await pumpScreen(tester, method: method, balance: 32500);

        expect(find.text('Cobrar también la deuda'), findsNothing);
        expect(find.widgetWithText(TextField, 'Deuda a cobrar'), findsNothing);
        expect(textOf(tester, receivedField), '6.500', reason: method.name);
        expect(find.text('Debe \$32.500 de antes'), findsOneWidget);
        expect(find.textContaining('Recibido'), findsNothing);
        expect(confirmEnabled(tester), isTrue, reason: method.name);
      }
    });

    testWidgets(r'$8.000 on $6.500 with $32.500 of debt shows the breakdown '
        'and confirms with debtAmount 1500', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.transfer, balance: 32500);

      await receive(tester, '8000');

      expect(find.text('Recibido \$8.000'), findsOneWidget);
      expect(find.text('Venta \$6.500 · Deuda \$1.500'), findsOneWidget);
      expect(find.text('Deuda restante \$31.000'), findsOneWidget);
      expect(find.textContaining('Queda debiendo'), findsNothing);
      expect(confirmEnabled(tester), isTrue);
      expect(tester.takeException(), isNull);

      await tapConfirm(tester);

      expect(find.byType(AlertDialog), findsNothing);
      final call = useCase.calls.single;
      expect(call.debtAmount, 1500);
      expect(call.sale.total, 6500);
      expect(call.sale.paymentMethod, PaymentMethod.transfer);
    });

    testWidgets(r'$30.000 on $6.500 pays $23.500 of debt', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 32500);

      await receive(tester, '30000');

      expect(find.text('Recibido \$30.000'), findsOneWidget);
      expect(find.text('Venta \$6.500 · Deuda \$23.500'), findsOneWidget);
      expect(find.text('Deuda restante \$9.000'), findsOneWidget);
      await tapConfirm(tester);
      expect(useCase.calls.single.debtAmount, 23500);
    });

    testWidgets('above the sale plus the whole debt shows the customer '
        'credit', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 1500);

      await receive(tester, '10000');

      expect(find.text('Venta \$6.500 · Deuda \$1.500'), findsOneWidget);
      expect(find.text('Saldo a favor \$2.000'), findsOneWidget);
      expect(find.textContaining('Deuda restante'), findsNothing);
      expect(confirmEnabled(tester), isTrue);
      await tapConfirm(tester);
      // S6: leaving credit asks first; keep it on purpose.
      await tester.tap(find.widgetWithText(FilledButton, 'Dejar a favor'));
      await tester.pumpAndSettle(const Duration(seconds: 4));
      expect(useCase.calls.single.debtAmount, 3500);
    });

    testWidgets('a customer without debt keeps the surplus as credit', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.transfer, balance: 0);

      await receive(tester, '7000');

      expect(find.text('Venta \$6.500'), findsOneWidget);
      expect(find.text('Saldo a favor \$500'), findsOneWidget);
    });

    testWidgets('below the sale total keeps the partial payment', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 32500);

      await receive(tester, '6000');

      expect(find.text('Queda debiendo \$500'), findsOneWidget);
      expect(find.textContaining('Recibido'), findsNothing);
    });

    testWidgets('0 shows why and blocks confirm', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 32500);

      await receive(tester, '0');

      expect(find.text('Ingresá un monto mayor a \$0'), findsOneWidget);
      expect(confirmEnabled(tester), isFalse);
    });

    testWidgets('credit shows no received amount and sends no debt', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.credit, balance: 32500);

      expect(receivedField, findsNothing);
      expect(find.textContaining('Recibido'), findsNothing);
      await tapConfirm(tester);
      expect(useCase.calls.single.debtAmount, 0);
    });
  });

  testWidgets(r'S2: mixed $5.000 + $3.000 on $6.500 splits the same way', (
    tester,
  ) async {
    await pumpScreen(tester, method: PaymentMethod.mixed, balance: 32500);

    await tester.enterText(find.widgetWithText(TextField, 'Efectivo'), '5000');
    await tester.enterText(
      find.widgetWithText(TextField, 'Transferencia'),
      '3000',
    );
    await tester.pump();

    expect(find.text('Cubierto'), findsOneWidget);
    expect(find.text('Recibido \$8.000'), findsOneWidget);
    expect(find.text('Venta \$6.500 · Deuda \$1.500'), findsOneWidget);
    expect(find.text('Deuda restante \$31.000'), findsOneWidget);
    expect(confirmEnabled(tester), isTrue);

    await tapConfirm(tester);

    final call = useCase.calls.single;
    expect(call.debtAmount, 1500);
    expect((call.sale.cashAmount, call.sale.transferAmount), (5000, 3000));
  });

  testWidgets('a customer in credit shows "Saldo a favor", never a negative '
      'debt', (tester) async {
    await pumpScreen(tester, method: PaymentMethod.cash, balance: -200);

    expect(find.text('Saldo a favor \$200'), findsOneWidget);
    expect(find.textContaining('Debe'), findsNothing);
    expect(find.textContaining('-\$'), findsNothing);
  });
}
