import 'package:flutter/foundation.dart';

enum AgreementStatus { inForce, ended, future }

/// A price agreed with one customer for one product.
@immutable
class CustomerAgreement {
  const CustomerAgreement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.validFrom,
    required this.status,
    required this.isSynced,
    this.validTo,
    this.reason,
  });

  final String id;
  final String productId;
  final String productName;
  final double unitPrice;

  /// Calendar days as `YYYY-MM-DD`.
  final String validFrom;
  final String? validTo;
  final String? reason;
  final AgreementStatus status;

  /// Whether the server already knows the agreement.
  final bool isSynced;

  /// Status on [today] (`YYYY-MM-DD`); server dates may carry a time.
  static AgreementStatus statusOn(String today, String from, String? to) {
    if (from.substring(0, 10).compareTo(today) > 0) return AgreementStatus.future;
    if (to != null && to.substring(0, 10).compareTo(today) < 0) {
      return AgreementStatus.ended;
    }
    return AgreementStatus.inForce;
  }
}
