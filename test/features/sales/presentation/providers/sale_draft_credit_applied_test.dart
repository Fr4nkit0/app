import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
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

/// Credit in the customer's favor applied to the sale (S2, S9): a sale of
/// 17500 for a customer whose account is at [balance] before it.
void main() {
  const product = Product(
    id: 'p1',
    name: 'Pack',
    unitLabel: 'u',
    price: 17500,
  );
  Customer customerFor(String id) =>
      Customer(id: id, name: id, addresses: const [], preferences: const []);

  late ProviderContainer container;
  late _RecordingRegisterSale useCase;
  late Map<String, StreamController<int>> balances;

  setUp(() {
    useCase = _RecordingRegisterSale();
    balances = {};
    container = ProviderContainer(
      overrides: [
        registerSaleUseCaseProvider.overrideWithValue(useCase),
        customerBalanceProvider.overrideWith(
          (ref, id) => balances
              .putIfAbsent(id, () => StreamController<int>.broadcast())
              .stream,
        ),
      ],
    );
    // The sale screens watch the draft; unwatched, Riverpod pauses it and
    // the balance it follows.
    container.listen(saleDraftProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    for (final c in balances.values) {
      await c.close();
    }
  });

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);
  SaleDraftState state() => container.read(saleDraftProvider);

  Future<void> setBalance(String id, int balance) async {
    balances
        .putIfAbsent(id, () => StreamController<int>.broadcast())
        .add(balance);
    await pumpEventQueue();
  }

  /// Selects customer [id] with one line of 17500 and its account at
  /// [balance].
  Future<void> sellTo(String id, int balance) async {
    notifier()
      ..selectCustomer(customerFor(id))
      ..setQuantity(const SaleItem(product: product, quantity: 0), 1);
    await setBalance(id, balance);
  }

  group('S9: the user example (17500, 500 in favor)', () {
    setUp(() => sellTo('c-1', -500));

    test('500 of credit is applied and 17000 is due', () {
      expect(state().customerBalance, -500);
      expect(state().creditApplied, 500);
      expect(state().amountDue, 17000);
    });

    test('cash and transfer start at the amount due; collecting it leaves '
        'nothing unpaid and is not partial', () {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        notifier().setPaymentMethod(method);
        expect(state().collectedAmount, 17000, reason: method.name);

        notifier().setCollectedAmount(17000);

        expect(state().unpaidAmount, 0, reason: method.name);
        expect(state().isPartialPayment, isFalse, reason: method.name);
        expect(state().extraReceived, 0, reason: method.name);
        expect(state().canConfirm, isTrue, reason: method.name);
      }
    });

    test('collecting 10000 of the 17000 due leaves 7000 unpaid', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(10000);

      expect(state().unpaidAmount, 7000);
      expect(state().isPartialPayment, isTrue);
    });

    test('money beyond the amount due is extra received', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(18000);

      expect(state().extraReceived, 1000);
      expect(state().unpaidAmount, 0);
      expect(state().receivedBreakdown(-500).credit, 1000);
      expect(state().receivedBreakdown(-500).balanceAfter, -1000);
    });

    test('mixed is measured against the amount due', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.mixed)
        ..setMixedAmounts(cash: 10000, transfer: 7000);

      expect(state().remaining, 0);
      expect(state().unpaidAmount, 0);
      expect(state().isPartialPayment, isFalse);
      expect(state().extraReceived, 0);
    });

    test('commit sends the whole total, the credit applied and the 17000 '
        'collected', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(17000);

      await notifier().commit();

      final call = useCase.calls.single;
      expect(call.sale.total, 17500);
      expect(call.sale.creditApplied, 500);
      expect(call.sale.cashAmount, isNull);
      expect(call.sale.settlement.cash, 17000);
      expect(call.debtAmount, 0);
      expect(state().customerBalance, 0, reason: 'the draft starts over');
    });

    test('a partial commit sends the collected amount and the credit', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(10000);

      await notifier().commit();

      final sale = useCase.calls.single.sale;
      expect(sale.creditApplied, 500);
      expect(sale.settlement.cash, 10000);
    });

    test('credit (fiado) also consumes the credit first', () async {
      notifier().setPaymentMethod(PaymentMethod.credit);

      await notifier().commit();

      final sale = useCase.calls.single.sale;
      expect(sale.creditApplied, 500);
      expect(sale.settlement.total, 0);
    });
  });

  group('S2: credit that covers the whole total', () {
    setUp(() => sellTo('c-1', -20000));

    test('nothing is due and the sale confirms with nothing collected', () {
      for (final method in [
        PaymentMethod.cash,
        PaymentMethod.transfer,
        PaymentMethod.mixed,
      ]) {
        notifier().setPaymentMethod(method);

        expect(state().creditApplied, 17500, reason: method.name);
        expect(state().amountDue, 0, reason: method.name);
        expect(state().collectedAmount, 0, reason: method.name);
        expect(state().unpaidAmount, 0, reason: method.name);
        expect(state().isPartialPayment, isFalse, reason: method.name);
        expect(state().isValidPayment, isTrue, reason: method.name);
        expect(state().canConfirm, isTrue, reason: method.name);
      }
    });

    test('commit sends no money', () async {
      notifier().setPaymentMethod(PaymentMethod.cash);

      await notifier().commit();

      final call = useCase.calls.single;
      expect(call.sale.creditApplied, 17500);
      expect(call.sale.settlement.total, 0);
      expect(call.debtAmount, 0);
    });
  });

  group('the balance follows the selected customer', () {
    test('a customer who owes or is even applies no credit', () async {
      await sellTo('c-1', 3000);
      expect(state().creditApplied, 0);
      expect(state().amountDue, 17500);

      await setBalance('c-1', 0);
      expect(state().creditApplied, 0);
    });

    test('the balance updates while the customer is selected and is '
        'dropped when the customer changes or is cleared', () async {
      await sellTo('c-1', -500);
      await setBalance('c-1', -800);
      expect(state().creditApplied, 800);

      notifier().selectCustomer(customerFor('c-2'));
      await setBalance('c-1', -900);
      expect(state().customerBalance, 0, reason: 'c-2 has not loaded');

      await setBalance('c-2', -100);
      expect(state().customerBalance, -100);

      notifier().clearCustomer();
      await setBalance('c-2', -200);
      expect(state().customerBalance, 0);
    });

    test('reset drops the balance subscription', () async {
      await sellTo('c-1', -500);

      notifier().reset();
      await setBalance('c-1', -700);

      expect(state().customerBalance, 0);
    });
  });
}
