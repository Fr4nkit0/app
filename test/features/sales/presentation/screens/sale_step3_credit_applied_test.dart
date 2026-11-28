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

/// One line of 17500 for a customer whose account is at [_balance].
class _PreparedDraft extends SaleDraft {
  _PreparedDraft(this._method, this._balance);

  final PaymentMethod _method;
  final int _balance;

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
        product: Product(id: 'p-1', name: 'Pack', unitLabel: 'u', price: 17500),
        quantity: 1,
      ),
    ],
    paymentMethod: _method,
    customerBalance: _balance,
  );
}

/// Sale step 3 with the customer's account (S9, S11) on a 360dp phone.
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
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          saleDraftProvider.overrideWith(() => _PreparedDraft(method, balance)),
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

  final collectedField = find.widgetWithText(TextField, 'Monto recibido');
  final confirmButton = find.widgetWithText(FilledButton, 'Confirmar');

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextField>(field).controller!.text;

  Future<void> tapConfirm(WidgetTester tester) async {
    await tester.ensureVisible(confirmButton);
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();
  }

  group('S9: 500 in favor on a sale of 17500', () {
    testWidgets('shows the credit applied and 17000 to collect, with no '
        'unpaid note', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: -500);

      expect(find.text('Saldo a favor aplicado -\$500'), findsOneWidget);
      expect(find.text('\$17.000'), findsOneWidget);
      expect(textOf(tester, collectedField), '17.000');
      expect(find.textContaining('debiendo'), findsNothing);
      expect(find.textContaining('Suma'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing 17000 and confirming saves without asking about a '
        'partial payment', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: -500);
      // Same digits as shown: typed with its separator, as the field shows it.
      await tester.enterText(collectedField, '17.000');
      await tester.pump();

      expect(find.textContaining('debiendo'), findsNothing);
      await tapConfirm(tester);

      expect(find.byType(AlertDialog), findsNothing);
      final sale = useCase.calls.single.sale;
      expect(sale.creditApplied, 500);
      expect(sale.settlement.cash, 17000);
    });

    testWidgets('credit covering the total says it is paid with credit and '
        'confirms with nothing collected', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: -20000);

      expect(find.text('Se paga con saldo a favor'), findsOneWidget);
      expect(collectedField, findsNothing);
      await tapConfirm(tester);

      expect(find.byType(AlertDialog), findsNothing);
      final sale = useCase.calls.single.sale;
      expect(sale.creditApplied, 17500);
      expect(sale.settlement.total, 0);
    });
  });

  group('S11: a partial payment of a customer who already owes 500', () {
    const added = 'Suma \$500 a su deuda de \$500. Deuda total: \$1.000';

    testWidgets('the note says it adds to the debt', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 500);
      await tester.enterText(collectedField, '17000');
      await tester.pump();

      expect(find.text(added), findsOneWidget);
      expect(find.textContaining('Queda debiendo'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mixed shows the same note', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.mixed, balance: 500);
      await tester.enterText(
        find.widgetWithText(TextField, 'Efectivo'),
        '17000',
      );
      await tester.pump();

      expect(find.text(added), findsOneWidget);
    });

    testWidgets('the confirmation says it adds to the debt', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 500);
      await tester.enterText(collectedField, '17000');
      await tester.pump();

      await tapConfirm(tester);

      expect(find.text('$added. ¿Confirmás?'), findsOneWidget);
      expect(useCase.calls, isEmpty);
    });

    testWidgets('without previous debt the wording stays', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 0);
      await tester.enterText(collectedField, '17000');
      await tester.pump();

      expect(find.text('Queda debiendo \$500'), findsOneWidget);
      await tapConfirm(tester);
      expect(
        find.text('El cliente queda debiendo \$500. ¿Confirmás?'),
        findsOneWidget,
      );
    });
  });
}
