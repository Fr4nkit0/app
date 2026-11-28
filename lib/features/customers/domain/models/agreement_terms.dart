import 'package:app/core/errors/domain_failure.dart';
import 'package:flutter/foundation.dart';

/// What the driver sets on a price agreement: the price and the days it
/// applies. Product and customer are not terms: they never change.
///
/// Dates are calendar days as `YYYY-MM-DD`.
@immutable
class AgreementTerms {
  const AgreementTerms({
    required this.unitPrice,
    required this.validFrom,
    this.validTo,
    this.reason,
  });

  /// The longest reason the server stores.
  static const maxReasonLength = 500;

  final int unitPrice;
  final String validFrom;
  final String? validTo;
  final String? reason;

  /// A copy with the reason trimmed, and none when it is blank.
  AgreementTerms normalized() {
    final trimmed = reason?.trim();
    return AgreementTerms(
      unitPrice: unitPrice,
      validFrom: validFrom,
      validTo: validTo,
      reason: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }

  /// Throws [ValidationFailure] for a price that is not positive, an end
  /// before the start, or a reason over
  /// [maxReasonLength]. Call it on [normalized] terms.
  void validate() {
    if (unitPrice <= 0) {
      throw const ValidationFailure('El precio debe ser mayor a 0.');
    }
    final end = validTo;
    if (end != null && end.compareTo(validFrom) < 0) {
      throw const ValidationFailure(
        'La fecha de fin no puede ser anterior al inicio.',
      );
    }
    final why = reason;
    if (why != null && why.length > maxReasonLength) {
      throw const ValidationFailure(
        'El motivo admite hasta $maxReasonLength caracteres.',
      );
    }
  }
}
