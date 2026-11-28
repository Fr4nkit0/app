import 'package:flutter/foundation.dart';

import 'package:app/features/sales/domain/same_day.dart';

enum PaymentType {
  cash,
  transfer,
  credit;

  String get dbValue {
    switch (this) {
      case PaymentType.cash:
        return 'EFECTIVO';
      case PaymentType.transfer:
        return 'TRANSFERENCIA';
      case PaymentType.credit:
        return 'CREDIT';
    }
  }

  static PaymentType fromDb(String value) {
    switch (value) {
      case 'TRANSFERENCIA':
        return PaymentType.transfer;
      case 'CREDIT':
        return PaymentType.credit;
      default:
        return PaymentType.cash;
    }
  }
}

@immutable
class Payment {
  const Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    required this.createdAt,
    this.visitId,
    this.saleId,
    this.notes,
    this.isCancelled = false,
    this.transactionUuid,
  });

  final String id;
  final String customerId;
  final int amount;
  final PaymentType type;
  final DateTime createdAt;
  final String? visitId;
  final String? saleId;
  final String? notes;

  /// A cancelled payment stays listed but no longer counts.
  final bool isCancelled;

  /// The money movement this payment is part of, shared with the other
  /// payments of the same method in one operation (a sale paid together
  /// with previous debt); null for a payment on its own. It travels only in
  /// the queued change, so a payment read back from storage has none.
  final String? transactionUuid;

  /// Only a confirmed payment of [now]'s day that did not settle a sale can
  /// be cancelled on its own; a sale's payments go with the sale.
  bool isCancellableOn(DateTime now) =>
      !isCancelled && saleId == null && isSameDay(createdAt, now);
}
