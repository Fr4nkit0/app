import 'package:app/features/sales/domain/same_day.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

class Sale {
  final String id;
  final Customer customer;
  final List<SaleItem> items;
  final int total;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final int? cashAmount;
  final int? transferAmount;
  final String? visitId;

  /// The customer's credit in favor this sale consumes, from 0 to [total];
  /// the rest, [amountDue], is what is collected or owed (S2).
  final int creditApplied;

  /// A cancelled sale stays listed but no longer counts.
  final bool isCancelled;

  const Sale({
    required this.id,
    required this.customer,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.date,
    this.cashAmount,
    this.transferAmount,
    this.visitId,
    this.creditApplied = 0,
    this.isCancelled = false,
  });

  /// What is left of [total] once the [creditApplied] is consumed.
  int get amountDue => total - creditApplied;

  /// Only a confirmed sale of [now]'s day can be cancelled.
  bool isCancellableOn(DateTime now) => !isCancelled && isSameDay(date, now);

  /// What the customer pays on the spot; nothing for credit and route sales.
  /// A cash or transfer sale pays its [cashAmount] or [transferAmount] when
  /// it holds one (a partial payment) and its whole [amountDue] otherwise;
  /// what is left unpaid stays on the customer's account.
  PaymentSplit get settlement => switch (paymentMethod) {
    PaymentMethod.cash => PaymentSplit(cash: cashAmount ?? amountDue),
    PaymentMethod.transfer => PaymentSplit(
      transfer: transferAmount ?? amountDue,
    ),
    PaymentMethod.mixed => PaymentSplit(
      cash: cashAmount ?? 0,
      transfer: transferAmount ?? 0,
    ),
    PaymentMethod.credit || PaymentMethod.route => PaymentSplit.none,
  };
}
