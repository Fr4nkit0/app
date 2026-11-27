import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/products/domain/models/product.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/received_breakdown.dart';
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

/// S2: the driver types what the customer handed over; it pays the sale
/// first, then previous debt, and any surplus stays as customer credit.
void main() {
  // One of 6500: a sale of 6500.
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
    debtAmount: 32500,
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
      ..setQuantity(const SaleItem(product: water, quantity: 0), 1);
  });
  tearDown(() => container.dispose());

  SaleDraft notifier() => container.read(saleDraftProvider.notifier);
  SaleDraftState state() => container.read(saleDraftProvider);

  ({int received, int sale, int debt, int credit, int after}) parts(
    ReceivedBreakdown b,
  ) => (
    received: b.received,
    sale: b.sale,
    debt: b.debt,
    credit: b.credit,
    after: b.balanceAfter,
  );

  group('S2: cash and transfer split the received amount', () {
    test(r'$30.000 on a $6.500 sale pays $23.500 of debt', () {
      for (final method in [PaymentMethod.cash, PaymentMethod.transfer]) {
        notifier()
          ..setPaymentMethod(method)
          ..setCollectedAmount(30000);

        expect(state().extraReceived, 23500, reason: method.name);
        expect(state().isPartialPayment, isFalse, reason: method.name);
        expect(state().unpaidAmount, 0, reason: method.name);
        expect(state().canConfirm, isTrue, reason: method.name);
        expect(parts(state().receivedBreakdown(32500)), (
          received: 30000,
          sale: 6500,
          debt: 23500,
          credit: 0,
          after: 9000,
        ), reason: method.name);
      }
    });

    test(r'$8.000 on $6.500 with $32.500 of debt pays $1.500 and leaves '
        r'$31.000', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.transfer)
        ..setCollectedAmount(8000);

      expect(state().extraReceived, 1500);
      expect(parts(state().receivedBreakdown(32500)), (
        received: 8000,
        sale: 6500,
        debt: 1500,
        credit: 0,
        after: 31000,
      ));
    });

    test('above the sale plus the whole debt the rest is credit', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(40000);

      expect(state().extraReceived, 33500);
      expect(state().canConfirm, isTrue);
      expect(parts(state().receivedBreakdown(32500)), (
        received: 40000,
        sale: 6500,
        debt: 32500,
        credit: 1000,
        after: -1000,
      ));
    });

    test('a customer already in credit keeps all the surplus as credit', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(7000);

      expect(parts(state().receivedBreakdown(-200)), (
        received: 7000,
        sale: 6500,
        debt: 0,
        credit: 500,
        after: -700,
      ));
    });

    test('below the sale total it stays a partial payment', () {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(6000);

      expect(state().extraReceived, 0);
      expect(state().isPartialPayment, isTrue);
      expect(state().unpaidAmount, 500);
      expect(state().canConfirm, isTrue);
      expect(parts(state().receivedBreakdown(32500)), (
        received: 6000,
        sale: 6000,
        debt: 0,
        credit: 0,
        after: 33000,
      ));
    });

    test('exactly the sale total pays nothing else', () {
      notifier().setPaymentMethod(PaymentMethod.cash);

      expect(state().collectedAmount, 6500);
      expect(state().extraReceived, 0);
      expect(state().isPartialPayment, isFalse);
    });

    test('0 or an invalid amount blocks confirm', () {
      notifier().setPaymentMethod(PaymentMethod.transfer);
      for (final amount in [0, null]) {
        notifier().setCollectedAmount(amount);
        expect(state().canConfirm, isFalse, reason: '$amount');
      }
    });
  });

  group('S2: mixed splits cash + transfer the same way', () {
    setUp(() => notifier().setPaymentMethod(PaymentMethod.mixed));

    test(r'$5.000 + $3.000 on $6.500 pays $1.500 of debt', () {
      notifier().setMixedAmounts(cash: 5000, transfer: 3000);

      expect(state().collectedAmount, 8000);
      expect(state().extraReceived, 1500);
      expect(state().remaining, -1500);
      expect(state().canConfirm, isTrue);
      expect(parts(state().receivedBreakdown(32500)), (
        received: 8000,
        sale: 6500,
        debt: 1500,
        credit: 0,
        after: 31000,
      ));
    });

    test('above the sale plus the whole debt the rest is credit', () {
      notifier().setMixedAmounts(cash: 5000, transfer: 5000);

      expect(parts(state().receivedBreakdown(1500)), (
        received: 10000,
        sale: 6500,
        debt: 1500,
        credit: 2000,
        after: -2000,
      ));
      expect(state().canConfirm, isTrue);
    });

    test('below the sale total it stays a partial payment', () {
      notifier().setMixedAmounts(cash: 4000, transfer: 2000);

      expect(state().extraReceived, 0);
      expect(state().isPartialPayment, isTrue);
      expect(state().unpaidAmount, 500);
    });
  });

  test('credit and route receive nothing on the spot', () {
    for (final method in [PaymentMethod.credit, PaymentMethod.route]) {
      notifier().setPaymentMethod(method);
      expect(state().extraReceived, 0, reason: method.name);
      expect(state().canConfirm, isTrue, reason: method.name);
      expect(parts(state().receivedBreakdown(32500)), (
        received: 0,
        sale: 0,
        debt: 0,
        credit: 0,
        after: 39000,
      ), reason: method.name);
    }
  });

  group('S2: commit', () {
    test('a cash or transfer sale sends the surplus as debtAmount and the '
        'sale as paid in full', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(30000);

      await notifier().commit();

      final call = useCase.calls.single;
      expect(call.debtAmount, 23500);
      expect(call.sale.total, 6500);
      expect(call.sale.paymentMethod, PaymentMethod.cash);
      expect(call.sale.cashAmount, isNull);
      expect(state().items, isEmpty);
    });

    test('a surplus above the whole debt is sent unchanged', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.transfer)
        ..setCollectedAmount(40000);

      await notifier().commit();

      expect(useCase.calls.single.debtAmount, 33500);
    });

    test('a mixed sale sends what the customer handed over', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.mixed)
        ..setMixedAmounts(cash: 5000, transfer: 3000);

      await notifier().commit();

      final call = useCase.calls.single;
      expect(call.debtAmount, 1500);
      expect((call.sale.cashAmount, call.sale.transferAmount), (5000, 3000));
    });

    test('a partial or credit sale sends 0', () async {
      notifier()
        ..setPaymentMethod(PaymentMethod.cash)
        ..setCollectedAmount(6000);
      await notifier().commit();
      expect(useCase.calls.last.debtAmount, 0);

      notifier()
        ..selectCustomer(customer)
        ..setQuantity(const SaleItem(product: water, quantity: 0), 1)
        ..setPaymentMethod(PaymentMethod.credit);
      await notifier().commit();
      expect(useCase.calls.last.debtAmount, 0);
    });
  });
}
