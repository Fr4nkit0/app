import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/services/database.helper.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/data/repositories/payment.repository.dart';
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

  // One jug of 6500.
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

/// Lets the in-memory database answer; its queries run outside fake time.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Widget _opener() => MaterialApp(
  theme: AppTheme.lightTheme,
  home: Builder(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SaleStep3Screen()),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

/// S6: the customer's debt next to «Monto recibido», a shortcut to collect
/// all of it, and a question before leaving credit by mistake. Sale of
/// $6.500 on a 360dp phone.
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
    required double balance,
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
        child: _opener(),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final receivedField = find.widgetWithText(TextField, 'Monto recibido');
  final confirmButton = find.widgetWithText(FilledButton, 'Confirmar');
  final collectAllChip = find.widgetWithText(
    ActionChip,
    'Cobrar toda la deuda',
  );
  const debtLine = 'Debe \$30.000 · si te da más, el resto va a la deuda';
  const creditTitle = '¿Dejar saldo a favor?';
  const creditBody =
      'Recibiste \$40.000 y la venta más la deuda suman \$36.500. '
      'Le quedan \$3.500 a favor al cliente.';

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

  group('S6.1: the debt next to the received amount', () {
    testWidgets('cash and transfer show the debt under «Monto recibido»', (
      tester,
    ) async {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        await pumpScreen(tester, method: method, balance: 30000);

        expect(find.text(debtLine), findsOneWidget, reason: method.name);
      }
    });

    testWidgets('mixed shows the debt near the mixed amounts', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.mixed, balance: 30000);

      expect(find.text(debtLine), findsOneWidget);
      expect(collectAllChip, findsNothing);
    });

    testWidgets('no debt line or shortcut without debt or with credit', (
      tester,
    ) async {
      for (final balance in [0.0, -200.0]) {
        for (final method in [
          PaymentMethod.cash,
          PaymentMethod.transfer,
          PaymentMethod.mixed,
        ]) {
          await pumpScreen(tester, method: method, balance: balance);

          final reason = '${method.name} at $balance';
          expect(
            find.textContaining('si te da más'),
            findsNothing,
            reason: reason,
          );
          expect(collectAllChip, findsNothing, reason: reason);
        }
      }
      // The credit context line stays.
      expect(find.text('Saldo a favor \$200'), findsOneWidget);
    });

    testWidgets('credit (fiado) shows neither the line nor the shortcut', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.credit, balance: 30000);

      expect(find.textContaining('si te da más'), findsNothing);
      expect(collectAllChip, findsNothing);
    });
  });

  group('S6.2: «Cobrar toda la deuda»', () {
    testWidgets('fills the sale plus the whole debt, the account is left '
        'clear and confirms without asking', (tester) async {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        await pumpScreen(tester, method: method, balance: 30000);

        await tester.ensureVisible(collectAllChip);
        await tester.tap(collectAllChip);
        await tester.pump();

        expect(textOf(tester, receivedField), '36500', reason: method.name);
        expect(find.text('Recibido \$36.500'), findsOneWidget);
        expect(find.text('Venta \$6.500 · Deuda \$30.000'), findsOneWidget);
        expect(find.text('Queda al día'), findsOneWidget);

        await tapConfirm(tester);

        expect(find.text(creditTitle), findsNothing);
        final call = useCase.calls.single;
        expect(call.debtAmount, 30000, reason: method.name);
        expect(call.sale.paymentMethod, method);
      }
    });
  });

  group('S6.3: asking before leaving credit', () {
    testWidgets('above the sale plus the debt asks naming the amounts and '
        'shows the credit in a warning color', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 30000);

      await receive(tester, '40000');

      final creditLine = tester.widget<Text>(
        find.text('Saldo a favor \$3.500'),
      );
      expect(creditLine.style?.color, MarilinColors.warning);

      await tapConfirm(tester);

      expect(find.text(creditTitle), findsOneWidget);
      expect(find.text(creditBody), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Corregir monto'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Dejar a favor'),
        findsOneWidget,
      );
      expect(useCase.calls, isEmpty);
    });

    testWidgets('a customer without debt is asked with the sale alone', (
      tester,
    ) async {
      await pumpScreen(tester, method: PaymentMethod.transfer, balance: 0);

      await receive(tester, '7000');
      await tapConfirm(tester);

      expect(find.text(creditTitle), findsOneWidget);
      expect(
        find.text(
          'Recibiste \$7.000 y la venta suma \$6.500. '
          'Le quedan \$500 a favor al cliente.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('mixed above the sale plus the debt asks too', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.mixed, balance: 30000);

      await tester.enterText(
        find.widgetWithText(TextField, 'Efectivo'),
        '30000',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Transferencia'),
        '10000',
      );
      await tester.pump();
      await tapConfirm(tester);

      expect(find.text(creditBody), findsOneWidget);
      expect(useCase.calls, isEmpty);
    });

    testWidgets('equal to or below the sale plus the debt does not ask', (
      tester,
    ) async {
      for (final amount in ['36500', '20000']) {
        await pumpScreen(tester, method: PaymentMethod.cash, balance: 30000);

        await receive(tester, amount);
        await tapConfirm(tester);

        expect(find.text(creditTitle), findsNothing, reason: amount);
        expect(useCase.calls, hasLength(1), reason: amount);
      }
    });

    testWidgets('below the sale still asks the partial payment question '
        'only', (tester) async {
      await pumpScreen(tester, method: PaymentMethod.cash, balance: 30000);

      await receive(tester, '6000');
      await tapConfirm(tester);

      expect(find.text(creditTitle), findsNothing);
      expect(
        find.text('El cliente queda debiendo \$500. ¿Confirmás?'),
        findsOneWidget,
      );
    });
  });

  group('S6.3 against the database', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db
          .into(db.customerTable)
          .insert(
            CustomerTableCompanion.insert(
              customerId: const drift.Value('c-1'),
              name: 'Kiosco Norte',
            ),
          );
      await db
          .into(db.customerBalanceTable)
          .insert(
            CustomerBalanceTableCompanion.insert(
              customerId: 'c-1',
              currentBalance: const drift.Value(30000),
            ),
          );
    });
    tearDown(() => db.close());

    Future<ProviderContainer> pumpWithDb(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          saleDraftProvider.overrideWith(
            () => _PreparedDraft(PaymentMethod.cash),
          ),
          customerContainerBalancesProvider.overrideWith(
            (ref, id) => Stream.value(const <CustomerContainerBalance>[]),
          ),
          containerTypesProvider.overrideWith(
            (ref) => Stream.value(const <ContainerType>[]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: _opener()),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);
      return container;
    }

    Future<double> balance() =>
        DriftPaymentRepository(db).watchCustomerBalance('c-1').first;

    Future<void> unmount(WidgetTester tester) async {
      // Drift schedules a zero-duration timer when a watched query is
      // cancelled.
      await tester.pumpWidget(const SizedBox());
      await tester.pump(Duration.zero);
    }

    testWidgets('«Corregir monto» saves nothing and keeps the draft', (
      tester,
    ) async {
      final container = await pumpWithDb(tester);
      expect(find.text(debtLine), findsOneWidget);

      await receive(tester, '40000');
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await _settle(tester);
      expect(find.text(creditBody), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Corregir monto'));
      await _settle(tester);

      expect(find.text(creditTitle), findsNothing);
      expect(find.byType(SaleStep3Screen), findsOneWidget);
      expect(textOf(tester, receivedField), '40000');
      expect(container.read(saleDraftProvider).collectedAmount, 40000);
      await tester.runAsync(() async {
        expect(await db.select(db.saleTable).get(), isEmpty);
        expect(await db.select(db.paymentTable).get(), isEmpty);
        expect(await balance(), 30000);
      });
      await unmount(tester);
    });

    testWidgets('«Dejar a favor» saves and leaves the customer in credit', (
      tester,
    ) async {
      final container = await pumpWithDb(tester);

      await receive(tester, '40000');
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Dejar a favor'));
      await _settle(tester);

      expect(find.byType(SaleStep3Screen), findsNothing);
      expect(container.read(saleDraftProvider).items, isEmpty);
      await tester.runAsync(() async {
        expect(await db.select(db.saleTable).get(), hasLength(1));
        expect(await db.select(db.paymentTable).get(), isNotEmpty);
        expect(await balance(), -3500);
      });
      // Let the success toast go.
      await tester.pump(const Duration(seconds: 4));
      await unmount(tester);
    });
  });
}
