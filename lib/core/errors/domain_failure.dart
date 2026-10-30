/// Why a use case or repository could not do what was asked.
///
/// The only failure types the domain throws; the presentation layer turns
/// them into driver-facing copy with `failureMessage`.
sealed class DomainFailure implements Exception {
  const DomainFailure();
}

/// The input breaks a business rule; [message] is driver-facing copy.
final class ValidationFailure extends DomainFailure {
  const ValidationFailure(this.message);

  final String message;

  @override
  String toString() => 'ValidationFailure($message)';
}

/// [what] the operation needs does not exist.
final class NotFoundFailure extends DomainFailure {
  const NotFoundFailure(this.what);

  final String what;

  @override
  String toString() => 'NotFoundFailure($what)';
}

/// The local store failed; [cause] is the underlying error.
final class StorageFailure extends DomainFailure {
  const StorageFailure(this.cause);

  final Object cause;

  @override
  String toString() => 'StorageFailure($cause)';
}
