/// Why a reschedule time is not allowed (ADR 0002: later the same day).
enum RescheduleTimeError { otherDay, notLater }

class RescheduleTimeException implements Exception {
  const RescheduleTimeException(this.reason);

  final RescheduleTimeError reason;

  @override
  String toString() => 'RescheduleTimeException($reason)';
}

/// Returns why [at] cannot be a reschedule time at [now], or null when it
/// can: it must fall later on the same day.
RescheduleTimeError? checkRescheduleTime({
  required DateTime now,
  required DateTime at,
}) {
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  if (!sameDay) return RescheduleTimeError.otherDay;
  if (!at.isAfter(now)) return RescheduleTimeError.notLater;
  return null;
}
