import 'package:flutter/foundation.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';

/// The payments of one operation: those that settle the sale and those that
/// pay previous debt.
typedef SaleDebtPayments = ({List<Payment> sale, List<Payment> debt});

/// How the money of one operation that pays a sale and previous debt is
/// split between them: cash covers the sale first, the transfer completes
/// it and what is left goes to the debt.
@immutable
class SaleDebtAllocation {
  const SaleDebtAllocation._({required this.sale, required this.debt});

  /// Splits [received] between a sale of [saleTotal] and [debtAmount] of
  /// previous debt. Throws [ValidationFailure] for a negative debt or part,
  /// or when [received] does not add up to [saleTotal] plus [debtAmount].
  factory SaleDebtAllocation.of(
    PaymentSplit received, {
    required int saleTotal,
    required int debtAmount,
  }) {
    if (debtAmount < 0) {
      throw const ValidationFailure('La deuda a cobrar no puede ser negativa.');
    }
    if (received.cash < 0 || received.transfer < 0) {
      throw const ValidationFailure('Ingresá montos mayores o iguales a 0.');
    }
    if (received.total != saleTotal + debtAmount) {
      throw const ValidationFailure(
        'Lo cobrado no coincide con la venta más la deuda.',
      );
    }
    if (debtAmount == 0) {
      return SaleDebtAllocation._(sale: received, debt: PaymentSplit.none);
    }
    final saleCash = received.cash < saleTotal ? received.cash : saleTotal;
    final saleTransfer = saleTotal - saleCash;
    return SaleDebtAllocation._(
      sale: PaymentSplit(cash: saleCash, transfer: saleTransfer),
      debt: PaymentSplit(
        cash: received.cash - saleCash,
        transfer: received.transfer - saleTransfer,
      ),
    );
  }

  /// Delay of the debt payments after the sale's, so they are listed after
  /// the sale payments of the same operation.
  static const debtAfterSale = Duration(milliseconds: 20);

  /// What settles the sale; it adds up to the sale total.
  final PaymentSplit sale;

  /// What pays previous debt; none when no debt is paid.
  final PaymentSplit debt;

  /// The payments of this operation. Sale payments are linked to [saleId]
  /// and debt payments to no sale; [saleIdFor] and [debtIdFor] receive each
  /// payment's position in its list. When debt is paid, every payment of a
  /// method shares the uuid [transactionUuidFor] gives for it; without debt
  /// the sale payments are those of a sale on its own, with no transaction
  /// uuid.
  SaleDebtPayments toPayments({
    required String customerId,
    required DateTime at,
    required String saleId,
    required String Function(int index) saleIdFor,
    required String Function(int index) debtIdFor,
    required String Function(PaymentType type) transactionUuidFor,
    String? visitId,
  }) {
    final shared = debt.total > 0 ? transactionUuidFor : null;
    return (
      sale: sale.toPayments(
        customerId: customerId,
        at: at,
        idFor: saleIdFor,
        visitId: visitId,
        saleId: saleId,
        transactionUuidFor: shared,
      ),
      debt: debt.toPayments(
        customerId: customerId,
        at: at.add(debtAfterSale),
        idFor: debtIdFor,
        visitId: visitId,
        transactionUuidFor: shared,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SaleDebtAllocation && other.sale == sale && other.debt == debt;

  @override
  int get hashCode => Object.hash(sale, debt);

  @override
  String toString() => 'SaleDebtAllocation(sale: $sale, debt: $debt)';
}
