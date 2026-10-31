import 'package:flutter/foundation.dart';

import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';

enum CustomerRecordType { visit, sale, payment, containerMovement }

/// A product line of a sale, e.g. 8 × Agua 20L.
@immutable
class CustomerRecordItem {
  const CustomerRecordItem({required this.productName, required this.quantity});

  final String productName;
  final int quantity;
}

/// One record of a customer stored on the device, whoever made it: a visit,
/// a sale, a payment or a container movement, from this device or from the
/// server.
@immutable
class CustomerRecord {
  const CustomerRecord({
    required this.id,
    required this.type,
    required this.date,
    this.amount,
    this.isCancelled = false,
    this.outcomeName,
    this.observations,
    this.saleMethod,
    this.saleItems = const [],
    this.paymentType,
    this.containerType,
    this.deliveredQuantity = 0,
    this.returnedQuantity = 0,
  });

  /// Local id of the record in its own table.
  final String id;
  final CustomerRecordType type;
  final DateTime date;

  /// Total of a sale or amount of a payment.
  final double? amount;

  /// A cancelled sale or payment, or a movement of a cancelled sale.
  final bool isCancelled;

  /// Visit outcome as the catalog names it.
  final String? outcomeName;
  final String? observations;

  final PaymentMethod? saleMethod;
  final List<CustomerRecordItem> saleItems;

  final PaymentType? paymentType;

  /// Catalog code of the moved container.
  final String? containerType;
  final int deliveredQuantity;
  final int returnedQuantity;
}
