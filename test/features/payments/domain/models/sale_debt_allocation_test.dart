import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/payments/domain/models/sale_debt_allocation.dart';

void main() {
  final at = DateTime(2026, 11, 16, 9, 30);

  SaleDebtPayments paymentsOf(SaleDebtAllocation allocation) =>
      allocation.toPayments(
        customerId: 'c1',
        at: at,
        saleId: 'sale-1',
        visitId: 'v1',
        saleIdFor: (i) => 's$i',
        debtIdFor: (i) => 'd$i',
        transactionUuidFor: (type) => 'tx-${type.name}',
      );

  group('S6 — mixed: cash covers the sale first', () {
    final allocation = SaleDebtAllocation.of(
      const PaymentSplit(cash: 5000, transfer: 15200),
      saleTotal: 13000,
      debtAmount: 7200,
    );

    test('cash 5000 and transfer 8000 to the sale, transfer 7200 to the '
        'debt', () {
      expect(allocation.sale, const PaymentSplit(cash: 5000, transfer: 8000));
      expect(allocation.debt, const PaymentSplit(transfer: 7200));
    });

    test('the transfer payments share one transaction uuid and cash has its '
        'own', () {
      final payments = paymentsOf(allocation);

      expect(payments.sale.map((p) => (p.type, p.amount)), [
        (PaymentType.cash, 5000),
        (PaymentType.transfer, 8000),
      ]);
      expect(payments.sale.map((p) => p.saleId), ['sale-1', 'sale-1']);
      expect(payments.sale.map((p) => p.id), ['s0', 's1']);
      expect(payments.debt.map((p) => (p.type, p.amount)), [
        (PaymentType.transfer, 7200),
      ]);
      expect(payments.debt.single.saleId, isNull);
      expect(payments.debt.single.id, 'd0');
      expect(payments.debt.single.visitId, 'v1');
      expect(payments.debt.single.customerId, 'c1');

      expect(payments.sale[0].transactionUuid, 'tx-cash');
      expect(payments.sale[1].transactionUuid, 'tx-transfer');
      expect(payments.debt.single.transactionUuid, 'tx-transfer');
    });

    test('debt payments are listed after the sale payments', () {
      final payments = paymentsOf(allocation);

      expect(payments.sale[0].createdAt, at);
      expect(
        payments.sale[1].createdAt,
        at.add(PaymentSplit.transferAfterCash),
      );
      expect(
        payments.debt.single.createdAt,
        at.add(SaleDebtAllocation.debtAfterSale),
      );
      expect(
        payments.debt.single.createdAt.isAfter(payments.sale[1].createdAt),
        isTrue,
      );
    });

    test('cash above the sale total leaves its remainder on the debt', () {
      final more = SaleDebtAllocation.of(
        const PaymentSplit(cash: 15000, transfer: 5200),
        saleTotal: 13000,
        debtAmount: 7200,
      );

      expect(more.sale, const PaymentSplit(cash: 13000));
      expect(more.debt, const PaymentSplit(cash: 2000, transfer: 5200));
      final payments = paymentsOf(more);
      expect(payments.sale.single.transactionUuid, 'tx-cash');
      expect(payments.debt.map((p) => p.transactionUuid), [
        'tx-cash',
        'tx-transfer',
      ]);
    });
  });

  test('cash only: the sale part is the total and the debt part is the '
      'debt, sharing one transaction uuid', () {
    final allocation = SaleDebtAllocation.of(
      const PaymentSplit(cash: 20200),
      saleTotal: 13000,
      debtAmount: 7200,
    );

    expect(allocation.sale, const PaymentSplit(cash: 13000));
    expect(allocation.debt, const PaymentSplit(cash: 7200));
    final payments = paymentsOf(allocation);
    expect(payments.sale.single.type, PaymentType.cash);
    expect(payments.debt.single.type, PaymentType.cash);
    expect(payments.sale.single.transactionUuid, 'tx-cash');
    expect(payments.debt.single.transactionUuid, 'tx-cash');
  });

  test('transfer only: the sale part is the total and the debt part is the '
      'debt, sharing one transaction uuid', () {
    final allocation = SaleDebtAllocation.of(
      const PaymentSplit(transfer: 20200),
      saleTotal: 13000,
      debtAmount: 7200,
    );

    expect(allocation.sale, const PaymentSplit(transfer: 13000));
    expect(allocation.debt, const PaymentSplit(transfer: 7200));
    final payments = paymentsOf(allocation);
    expect(payments.sale.single.amount, 13000);
    expect(payments.debt.single.amount, 7200);
    expect(payments.sale.single.transactionUuid, 'tx-transfer');
    expect(payments.debt.single.transactionUuid, 'tx-transfer');
  });

  test('without debt the sale payments are exactly those of the split, with '
      'no transaction uuid and no debt payment', () {
    const received = PaymentSplit(cash: 5000, transfer: 8000);
    final allocation = SaleDebtAllocation.of(
      received,
      saleTotal: 13000,
      debtAmount: 0,
    );

    expect(allocation.sale, received);
    expect(allocation.debt, PaymentSplit.none);
    final payments = paymentsOf(allocation);
    final today = received.toPayments(
      customerId: 'c1',
      at: at,
      idFor: (i) => 's$i',
      visitId: 'v1',
      saleId: 'sale-1',
    );
    expect(payments.debt, isEmpty);
    expect(
      payments.sale.map(
        (p) => (
          p.id,
          p.type,
          p.amount,
          p.createdAt,
          p.saleId,
          p.visitId,
          p.transactionUuid,
        ),
      ),
      today.map(
        (p) => (
          p.id,
          p.type,
          p.amount,
          p.createdAt,
          p.saleId,
          p.visitId,
          p.transactionUuid,
        ),
      ),
    );
    expect(payments.sale.map((p) => p.transactionUuid), everyElement(isNull));
  });

  group('rejects', () {
    void expectRejected(
      PaymentSplit received, {
      double saleTotal = 13000,
      double debtAmount = 7200,
    }) => expect(
      () => SaleDebtAllocation.of(
        received,
        saleTotal: saleTotal,
        debtAmount: debtAmount,
      ),
      throwsA(isA<ValidationFailure>()),
    );

    test('a split that does not add up to the sale total plus the debt', () {
      expectRejected(const PaymentSplit(cash: 5000, transfer: 15000));
      expectRejected(const PaymentSplit(transfer: 13000));
    });

    test('a negative debt amount', () {
      expectRejected(const PaymentSplit(cash: 12000), debtAmount: -1000);
    });

    test('a negative part', () {
      expectRejected(
        const PaymentSplit(cash: -100, transfer: 20300),
        debtAmount: 7200,
      );
    });
  });
}
