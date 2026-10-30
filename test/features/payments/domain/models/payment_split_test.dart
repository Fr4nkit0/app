import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';

void main() {
  final at = DateTime(2026, 10, 28, 9, 30);

  List<Payment> paymentsOf(PaymentSplit split, {String? saleId}) =>
      split.toPayments(
        customerId: 'c1',
        at: at,
        idFor: (index) => 'p$index',
        visitId: 'v1',
        saleId: saleId,
      );

  test('a cash-only split is one cash payment at the given time', () {
    final payments = paymentsOf(const PaymentSplit(cash: 400));

    expect(payments, hasLength(1));
    expect(payments.single.id, 'p0');
    expect(payments.single.type, PaymentType.cash);
    expect(payments.single.amount, 400);
    expect(payments.single.createdAt, at);
  });

  test('a transfer-only split is one transfer payment without offset', () {
    final payments = paymentsOf(const PaymentSplit(transfer: 250));

    expect(payments, hasLength(1));
    expect(payments.single.id, 'p0');
    expect(payments.single.type, PaymentType.transfer);
    expect(payments.single.amount, 250);
    expect(payments.single.createdAt, at);
  });

  test('a mixed split puts cash first and the transfer right after it', () {
    final payments = paymentsOf(const PaymentSplit(cash: 600, transfer: 400));

    expect(payments.map((p) => p.id), ['p0', 'p1']);
    expect(payments.map((p) => p.type), [
      PaymentType.cash,
      PaymentType.transfer,
    ]);
    expect(payments.map((p) => p.amount), [600, 400]);
    expect(payments[0].createdAt, at);
    expect(payments[1].createdAt, at.add(PaymentSplit.transferAfterCash));
    expect(PaymentSplit.transferAfterCash, const Duration(milliseconds: 10));
  });

  test('a zero part produces no payment', () {
    final payments = paymentsOf(const PaymentSplit(cash: 0, transfer: 300));

    expect(payments.single.type, PaymentType.transfer);
    expect(payments.single.id, 'p0');
    expect(payments.single.createdAt, at);
  });

  test('none produces no payments and totals zero', () {
    expect(paymentsOf(PaymentSplit.none), isEmpty);
    expect(PaymentSplit.none.total, 0);
  });

  test('total adds both parts', () {
    expect(const PaymentSplit(cash: 600, transfer: 400.5).total, 1000.5);
  });

  test('payments carry the customer, visit and sale', () {
    final payments = paymentsOf(
      const PaymentSplit(cash: 1, transfer: 1),
      saleId: 's1',
    );

    for (final p in payments) {
      expect(p.customerId, 'c1');
      expect(p.visitId, 'v1');
      expect(p.saleId, 's1');
    }
  });

  test('splits with the same amounts are equal', () {
    expect(
      const PaymentSplit(cash: 1, transfer: 2),
      const PaymentSplit(cash: 1, transfer: 2),
    );
    expect(
      const PaymentSplit(cash: 1, transfer: 2).hashCode,
      const PaymentSplit(cash: 1, transfer: 2).hashCode,
    );
    expect(
      const PaymentSplit(cash: 1),
      isNot(const PaymentSplit(transfer: 1)),
    );
  });
}
