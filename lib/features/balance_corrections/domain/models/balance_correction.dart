import 'package:flutter/foundation.dart';

/// What a balance correction corrects.
enum BalanceTarget {
  /// The customer's money account (positive: the customer owes).
  debt('debt'),

  /// The customer's custody of one container type.
  containers('containers');

  const BalanceTarget(this.wireName);

  final String wireName;

  static BalanceTarget fromWire(String value) =>
      values.firstWhere((t) => t.wireName == value);
}

/// The driver counted the real balance of a customer and corrected the one
/// the device showed ([seenBalance]) to it ([counted]).
@immutable
class BalanceCorrection {
  const BalanceCorrection({
    required this.id,
    required this.customerId,
    required this.target,
    required this.counted,
    required this.seenBalance,
    required this.reason,
    required this.correctedAt,
    this.containerType,
    this.visitId,
  });

  final String id;
  final String customerId;
  final BalanceTarget target;

  /// Catalog code of the corrected container type; only for
  /// [BalanceTarget.containers].
  final String? containerType;
  final double counted;
  final double seenBalance;
  final String reason;
  final DateTime correctedAt;
  final String? visitId;

  /// What the correction moves the balance by.
  double get difference => counted - seenBalance;
}
