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

/// Partial payment on the draft (S2, S3, S6): a sale of 6500.
void main() {
  const jug = Product(
    id: 'p1',
    name: 'Bidón 20L',
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
      ..setQuantity(const SaleItem(product: jug, quantity: 0), 1);
  });
  tearDown(() => container.dispose());

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);
  SaleDraftState state() => container.read(saleDraftProvider);

  group('S2: cash and transfer collect an editable amount', () {
    test('starts at the sale total with nothing unpaid', () {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        notifier().setPaymentMethod(method);

        expect(state().collectedAmount, 6500, reason: method.name);
        expect(state().unpaidAmount, 0, reason: method.name);
        expect(state().isPartialPayment, isFalse, reason: method.name);
        expect(state().canConfirm, isTrue, reason: method.name);
      }
    });

    test('6000 of 6500 leaves 500 unpaid and confirms', () {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        notifier()
          ..setPaymentMethod(method)
          ..setCollectedAmount(6000);

        expect(state().collectedAmount, 6000, reason: method.name);
        expect(state().unpaidAmount, 500, reason: method.name);
        expect(state().isPartialPayment, isTrue, reason: method.name);
        expect(state().canConfirm, isTrue, reason: method.name);
      }
    });

    test('0 or an invalid amount blocks confirm; above the total confirms '
        '(the rest pays previous debt, S2 of the received split)', () {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        notifier()
          ..setPaymentMethod(method)
          ..setCollectedAmount(7000);
        expect(state().canConfirm, isTrue, reason: method.name);
        for (final amount in [0.0, null]) {
          notifier().setCollectedAmount(amount);
          expect(state().isValidPayment, isFalse, reason: '$method $amount');
          expect(state().canConfirm, isFalse, reason: '$method $amount');
        }
        notifier().setCollectedAmount(6500);
        expect(state().canConfirm, isTrue, reason: method.name);
      }
    });

    test('changing method starts again at the total', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(6000)
        ..setPaymentMethod(PaymentMethod.transfer);

      expect(state().collectedAmount, 6500);
      expect(state().isPartialPayment, isFalse);
    });

    test('changing the lines starts again at the new total', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(6000)
        ..setQuantity(const SaleItem(product: jug, quantity: 1), 2);

      expect(state().collectedAmount, 13000);
      expect(state().unpaidAmount, 0);
    });

    test('credit and route have nothing unpaid on the spot', () {
      for (final method in [PaymentMethod.credit, PaymentMethod.route]) {
        notifier().setPaymentMethod(method);
        expect(state().unpaidAmount, 0, reason: method.name);
        expect(state().isPartialPayment, isFalse, reason: method.name);
        expect(state().canConfirm, isTrue, reason: method.name);
      }
    });
  });

  group('S2: mixed may add up to less than the total', () {
    setUp(() => notifier().setPaymentMethod(PaymentMethod.mixed));

    test('4000 + 2000 of 6500 leaves 500 unpaid and confirms', () {
      notifier().setMixedAmounts(cash: 4000, transfer: 2000);

      expect(state().collectedAmount, 6000);
      expect(state().unpaidAmount, 500);
      expect(state().isPartialPayment, isTrue);
      expect(state().canConfirm, isTrue);
    });

    test('the exact total confirms with nothing unpaid (S6)', () {
      notifier().setMixedAmounts(cash: 4000, transfer: 2500);

      expect(state().unpaidAmount, 0);
      expect(state().isPartialPayment, isFalse);
      expect(state().remaining, 0);
      expect(state().canConfirm, isTrue);
    });

    test('nothing typed blocks confirm; above the total confirms', () {
      notifier().setMixedAmounts(cash: 5000, transfer: 2000);
      expect(state().canConfirm, isTrue);

      notifier().setMixedAmounts(cash: 0, transfer: 0);
      expect(state().canConfirm, isFalse);
      expect(state().isPartialPayment, isFalse, reason: 'nothing typed yet');
    });
  });

  group('S5: commit', () {
    test(
      'a partial cash sale sends its total and the collected cash',
      () async {
        notifier()
          ..setPaymentMethod(PaymentMethod.cash)
          ..setCollectedAmount(6000);

        await notifier().commit();

        final call = useCase.calls.single;
        expect(call.sale.total, 6500);
        expect(call.sale.paymentMethod, PaymentMethod.cash);
        expect(call.sale.settlement.cash, 6000);
        expect(call.sale.settlement.transfer, 0);
        expect(call.debtAmount, 0);
      },
    );

    test('a partial transfer sale sends the collected transfer', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.transfer)
        ..setCollectedAmount(6000);

      await notifier().commit();

      final sale = useCase.calls.single.sale;
      expect(sale.settlement.transfer, 6000);
      expect(sale.settlement.cash, 0);
    });

    test('a partial mixed sale sends both parts', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.mixed)
        ..setMixedAmounts(cash: 4000, transfer: 2000);

      await notifier().commit();

      final sale = useCase.calls.single.sale;
      expect((sale.cashAmount, sale.transferAmount), (4000, 2000));
    });

    test('S6: a full cash or transfer sale is sent as before', () async {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        notifier()
          ..selectCustomer(customer)
          ..setQuantity(const SaleItem(product: jug, quantity: 0), 1)
          ..setPaymentMethod(method)
          ..setCollectedAmount(6500);

        await notifier().commit();

        final sale = useCase.calls.last.sale;
        expect(sale.cashAmount, isNull, reason: method.name);
        expect(sale.transferAmount, isNull, reason: method.name);
        expect(sale.settlement.total, 6500, reason: method.name);
      }
    });
  });
}
