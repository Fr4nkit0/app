import 'package:flutter/foundation.dart';

/// Where the money a customer hands over with a sale goes: first the sale,
/// then their previous debt, and whatever is left stays as credit in their
/// favor. Mirrors the server's running account (sale +total, payment
/// −amount; positive = the customer owes).
@immutable
class ReceivedBreakdown {
  const ReceivedBreakdown._({
    required this.received,
    required this.sale,
    required this.debt,
    required this.credit,
    required this.balanceAfter,
  });

  /// Splits [received] for a sale of [saleTotal] booked on an account at
  /// [balance] before the sale (negative: the customer has credit).
  factory ReceivedBreakdown.of({
    required double received,
    required double saleTotal,
    required double balance,
  }) {
    final sale = received < saleTotal ? received : saleTotal;
    final extra = received - sale;
    final owed = balance > 0 ? balance : 0.0;
    final debt = extra < owed ? extra : owed;
    return ReceivedBreakdown._(
      received: received,
      sale: sale,
      debt: debt,
      credit: extra - debt,
      balanceAfter: balance + saleTotal - received,
    );
  }

  /// What the customer handed over.
  final double received;

  /// The part that pays the sale; below its total on a partial payment.
  final double sale;

  /// The part that pays previous debt.
  final double debt;

  /// The part beyond the sale and the whole previous debt: credit in the
  /// customer's favor.
  final double credit;

  /// The account once the sale and the money are booked; negative when the
  /// customer is left with credit.
  final double balanceAfter;

  /// What is received beyond the sale: previous debt plus [credit].
  double get beyondSale => debt + credit;

  @override
  bool operator ==(Object other) =>
      other is ReceivedBreakdown &&
      other.received == received &&
      other.sale == sale &&
      other.debt == debt &&
      other.credit == credit &&
      other.balanceAfter == balanceAfter;

  @override
  int get hashCode => Object.hash(received, sale, debt, credit, balanceAfter);

  @override
  String toString() =>
      'ReceivedBreakdown(received: $received, sale: $sale, debt: $debt, '
      'credit: $credit, balanceAfter: $balanceAfter)';
}
