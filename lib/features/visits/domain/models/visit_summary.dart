import 'package:flutter/foundation.dart';

import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';

/// What the visit to a closed stop recorded: how it ended, its sales, the
/// payments outside a sale and the containers returned.
@immutable
class VisitSummary {
  const VisitSummary({
    this.outcome,
    this.salesTotal = 0,
    this.saleMethods = const [],
    this.collected = 0,
    this.returned = 0,
  });

  /// Why the visit ended without a sale; null for a sale visit.
  final VisitOutcome? outcome;

  final double salesTotal;

  /// Payment methods of the sales, in sale order, without repeats.
  final List<PaymentMethod> saleMethods;

  /// Payments not tied to a sale, such as a debt payment.
  final double collected;

  /// Containers returned, of every type.
  final int returned;

  bool get hasSales => saleMethods.isNotEmpty;
}
