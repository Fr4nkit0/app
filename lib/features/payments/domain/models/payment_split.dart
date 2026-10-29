import 'package:flutter/foundation.dart';

import 'package:app/features/payments/domain/models/payment.dart';

/// How an amount is paid: a cash part and a transfer part.
@immutable
class PaymentSplit {
  const PaymentSplit({this.cash = 0, this.transfer = 0});

  static const none = PaymentSplit();

  /// Delay of a transfer after the cash of the same split, so cash is listed first.
  static const transferAfterCash = Duration(milliseconds: 10);

  final double cash;
  final double transfer;

  double get total => cash + transfer;

  /// The payments of this split: cash first, then transfer; a part of 0
  /// produces no payment. [idFor] receives the payment's position in the
  /// returned list.
  List<Payment> toPayments({
    required String customerId,
    required DateTime at,
    required String Function(int index) idFor,
    String? visitId,
    String? saleId,
  }) {
    final payments = <Payment>[];
    void add(PaymentType type, double amount, DateTime createdAt) =>
        payments.add(
          Payment(
            id: idFor(payments.length),
            customerId: customerId,
            amount: amount,
            type: type,
            createdAt: createdAt,
            visitId: visitId,
            saleId: saleId,
          ),
        );

    if (cash > 0) add(PaymentType.cash, cash, at);
    if (transfer > 0) {
      add(
        PaymentType.transfer,
        transfer,
        payments.isEmpty ? at : at.add(transferAfterCash),
      );
    }
    return payments;
  }

  @override
  bool operator ==(Object other) =>
      other is PaymentSplit && other.cash == cash && other.transfer == transfer;

  @override
  int get hashCode => Object.hash(cash, transfer);

  @override
  String toString() => 'PaymentSplit(cash: $cash, transfer: $transfer)';
}
