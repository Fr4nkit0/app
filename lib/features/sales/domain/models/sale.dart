import 'package:app/features/sales/domain/same_day.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/payments/domain/models/payment_split.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';

class Sale {
  final String id;
  final Customer customer;
  final List<SaleItem> items;
  final double total;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final double? cashAmount;
  final double? transferAmount;
  final String? visitId;

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
    this.isCancelled = false,
  });

  /// Only a confirmed sale of [now]'s day can be cancelled.
  bool isCancellableOn(DateTime now) => !isCancelled && isSameDay(date, now);

  /// What the customer pays on the spot; nothing for credit and route sales.
  PaymentSplit get settlement => switch (paymentMethod) {
    PaymentMethod.cash => PaymentSplit(cash: total),
    PaymentMethod.transfer => PaymentSplit(transfer: total),
    PaymentMethod.mixed => PaymentSplit(
      cash: cashAmount ?? 0,
      transfer: transferAmount ?? 0,
    ),
    PaymentMethod.credit || PaymentMethod.route => PaymentSplit.none,
  };
}
