import 'package:app/core/errors/domain_failure.dart';

/// The longest reason the server keeps for a cancellation.
const cancellationReasonMaxLength = 500;

/// [reason] trimmed, null when blank. Throws [ValidationFailure] when it is
/// longer than the server accepts.
String? cancellationReason(String? reason) {
  final trimmed = reason?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  if (trimmed.length > cancellationReasonMaxLength) {
    throw const ValidationFailure(
      'El motivo admite hasta $cancellationReasonMaxLength caracteres.',
    );
  }
  return trimmed;
}
