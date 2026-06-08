import 'package:flutter/foundation.dart';

@immutable
class CustomerAccountEntry {
  const CustomerAccountEntry({
    required this.id,
    required this.customerId,
    required this.entryType,
    required this.amount,
    required this.direction,
    required this.createdAt,
    this.paymentId,
    this.saleId,
    this.description,
  });

  final String id;
  final String customerId;
  final String? paymentId;
  final String? saleId;
  final String entryType; // 'SALE' | 'PAYMENT' | 'ADJUSTMENT' | 'CREDIT_NOTE'
  final double amount;
  final int direction; // -1 credit/payment, +1 debit/sale
  final String? description;
  final DateTime createdAt;
}
