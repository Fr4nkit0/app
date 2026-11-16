import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/domain/usecases/register_sale.usecase.dart';
import 'package:app/features/sales/presentation/providers/register_sale_usecase_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

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

void main() {
  // Two of 6500: a sale of 13000.
  const water = Product(
    id: 'p1',
    name: 'Agua 20L',
    unitLabel: 'bidón',
    price: 6500,
  );
  final customer = Customer(
    id: 'c-1',
    name: 'Kiosco Norte',
    addresses: const [],
    preferences: const [],
    debtAmount: 7200,
  );

  late ProviderContainer container;
  late _RecordingRegisterSale useCase;
  setUp(() {
    useCase = _RecordingRegisterSale();
    container = ProviderContainer(
      overrides: [registerSaleUseCaseProvider.overrideWithValue(useCase)],
    );
    container.read(saleDraftProvider.notifier)
      ..selectCustomer(customer)
      ..setQuantity(const SaleItem(product: water, quantity: 0), 2);
  });
  tearDown(() => container.dispose());

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);
  SaleDraftState state() => container.read(saleDraftProvider);

  group('S4: which methods also collect the debt', () {
    test('cash, transfer and mixed take the whole current debt when '
        'switched on', () {
      for (final method in [
        PaymentMethod.cash,
        PaymentMethod.transfer,
        PaymentMethod.mixed,
      ]) {
        notifier()
          ..setPaymentMethod(method)
          ..setCollectDebt(true, currentDebt: 7200);

        final draft = container.read(saleDraftProvider);
        expect(draft.collectsDebt, isTrue, reason: method.name);
        expect(draft.debtAmount, 7200, reason: method.name);
        expect(draft.debtToCollect, 7200, reason: method.name);
        expect(draft.operationTotal, 20200, reason: method.name);
        notifier().setCollectDebt(false, currentDebt: 7200);
      }
    });

    test('credit cannot switch it on and moving to credit or route turns '
        'it off', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.credit)
        ..setCollectDebt(true, currentDebt: 7200);
      expect(state().collectsDebt, isFalse);
      expect(state().operationTotal, 13000);

      for (final method in [PaymentMethod.credit, PaymentMethod.route]) {
        notifier()
          ..setPaymentMethod(PaymentMethod.transfer)
          ..setCollectDebt(true, currentDebt: 7200)
          ..setPaymentMethod(method);
        expect(state().collectsDebt, isFalse, reason: method.name);
        expect(state().debtToCollect, 0, reason: method.name);
        expect(state().operationTotal, 13000, reason: method.name);
      }
    });

    test('a customer without debt cannot switch it on', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectDebt(true, currentDebt: 0);
      expect(state().collectsDebt, isFalse);
      expect(state().canConfirm, isTrue);
    });

    test('changing between cash, transfer and mixed keeps it on', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectDebt(true, currentDebt: 7200)
        ..setDebtAmount(5000)
        ..setPaymentMethod(PaymentMethod.transfer);
      expect(state().collectsDebt, isTrue);
      expect(state().debtToCollect, 5000);
    });

    test('choosing another customer turns it off', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectDebt(true, currentDebt: 7200)
        ..clearCustomer()
        ..selectCustomer(customer);
      expect(state().collectsDebt, isFalse);
      expect(state().debtToCollect, 0);
    });
  });

  group('S5: editable debt amount', () {
    setUp(() {
      notifier()
        ..setPaymentMethod(PaymentMethod.transfer)
        ..setCollectDebt(true, currentDebt: 7200);
    });

    test('can be lowered', () {
      notifier().setDebtAmount(3000);
      expect(state().debtToCollect, 3000);
      expect(state().operationTotal, 16000);
      expect(state().isValidDebtAmount, isTrue);
      expect(state().canConfirm, isTrue);
    });

    test('above the current debt, 0, negative or empty blocks confirm', () {
      for (final amount in [7200.02, 0.0, -1.0, null]) {
        notifier().setDebtAmount(amount);
        expect(state().isValidDebtAmount, isFalse, reason: '$amount');
        expect(state().canConfirm, isFalse, reason: '$amount');
      }
      notifier().setDebtAmount(7200);
      expect(state().canConfirm, isTrue);
    });

    test('switching off and on again starts at the whole debt', () {
      notifier()
        ..setDebtAmount(100)
        ..setCollectDebt(false, currentDebt: 7200);
      expect(state().debtToCollect, 0);
      expect(state().canConfirm, isTrue);

      notifier().setCollectDebt(true, currentDebt: 7200);
      expect(state().debtToCollect, 7200);
    });
  });

  group('S6: mixed covers the sale plus the debt', () {
    setUp(() {
      notifier()
        ..setPaymentMethod(PaymentMethod.mixed)
        ..setCollectDebt(true, currentDebt: 7200);
    });

    test('cash + transfer equal to the sale total alone is not enough', () {
      notifier().setMixedAmounts(cash: 5000, transfer: 8000);
      expect(state().isValidPayment, isFalse);
      expect(state().remaining, 7200);
      expect(state().canConfirm, isFalse);
    });

    test('cash + transfer equal to the sale plus the debt confirms', () {
      notifier().setMixedAmounts(cash: 5000, transfer: 15200);
      expect(state().isValidPayment, isTrue);
      expect(state().remaining, 0);
      expect(state().canConfirm, isTrue);

      notifier().setMixedAmounts(cash: 5000, transfer: 15200.004);
      expect(state().canConfirm, isTrue, reason: 'within the tolerance');

      notifier().setMixedAmounts(cash: 5000, transfer: 15300);
      expect(state().remaining, -100);
      expect(state().canConfirm, isFalse, reason: 'more than both');
    });

    test('without the debt the sale total alone confirms as before', () {
      notifier()
        ..setCollectDebt(false, currentDebt: 7200)
        ..setMixedAmounts(cash: 5000, transfer: 8000);
      expect(state().canConfirm, isTrue);
      expect(state().remaining, 0);
    });
  });

  group('S9: commit', () {
    test('passes the debt amount to the use case and leaves the sale as '
        'is', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.transfer)
        ..setCollectDebt(true, currentDebt: 7200);

      await notifier().commit();

      final call = useCase.calls.single;
      expect(call.debtAmount, 7200);
      expect(call.sale.total, 13000);
      expect(call.sale.paymentMethod, PaymentMethod.transfer);
      expect(container.read(saleDraftProvider).collectsDebt, isFalse);
    });

    test('a mixed sale sends what the customer handed over', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.mixed)
        ..setCollectDebt(true, currentDebt: 7200)
        ..setMixedAmounts(cash: 5000, transfer: 15200);

      await notifier().commit();

      final call = useCase.calls.single;
      expect(call.debtAmount, 7200);
      expect((call.sale.cashAmount, call.sale.transferAmount), (5000, 15200));
    });

    test('sends 0 when it is off', () async {
      notifier().setPaymentMethod(PaymentMethod.cash);

      await notifier().commit();

      expect(useCase.calls.single.debtAmount, 0);
    });

    test('does nothing while the debt amount is invalid', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectDebt(true, currentDebt: 7200)
        ..setDebtAmount(9000);

      await notifier().commit();

      expect(useCase.calls, isEmpty);
    });
  });
}
