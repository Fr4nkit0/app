import 'package:app/core/errors/domain_failure.dart';

/// The driver-facing text for a failed write: a [ValidationFailure] carries
/// its own copy; anything else shows the action's [fallback].
String failureMessage(Object error, {required String fallback}) =>
    switch (error) {
      ValidationFailure(:final message) => message,
      _ => fallback,
    };
