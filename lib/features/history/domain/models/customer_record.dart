import 'package:flutter/foundation.dart';

import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/same_day.dart';

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
    this.cancelledByAdmin = false,
    this.visitId,
    this.saleId,
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

  /// A sale or payment the office cancelled, not the driver.
  final bool cancelledByAdmin;

  /// The visit (its stop's id) a sale or payment was made in; null for an
  /// off-route one, made from the customer profile.
  final String? visitId;

  /// The sale a payment settled.
  final String? saleId;

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

  /// An off-route sale, or an off-route payment that did not settle a sale,
  /// of [now]'s day that still counts: the driver can cancel it from the
  /// profile. A visit's records are cancelled from the visit.
  bool isCancellableOn(DateTime now) =>
      !isCancelled &&
      visitId == null &&
      switch (type) {
        CustomerRecordType.sale => true,
        CustomerRecordType.payment => saleId == null,
        CustomerRecordType.visit ||
        CustomerRecordType.containerMovement => false,
      } &&
      isSameDay(date, now);
}
