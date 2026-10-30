import 'package:app/core/errors/domain_failure.dart';

/// What the driver picks for one delivery preference: a day and a window.
///
/// Days follow the server: 0 is Sunday, 1 Monday ... 6 Saturday. Times are
/// kept as `HH:mm`, the server's `H:i`.
class PreferenceDetails {
  const PreferenceDetails({
    required this.dayOfWeek,
    required this.start,
    this.end,
  });

  /// The stored start of a preference the server holds without one: the
  /// local column is required, and no delivery window starts at midnight.
  static const noStart = '00:00';

  final int dayOfWeek;
  final String start;
  final String? end;

  /// A copy with both times as `HH:mm`; a time that does not parse stays as
  /// typed so [validate] refuses it.
  PreferenceDetails normalized() => PreferenceDetails(
    dayOfWeek: dayOfWeek,
    start: hhmm(start) ?? start,
    end: end == null ? null : hhmm(end) ?? end,
  );

  /// Throws [ValidationFailure] for what the server would refuse. Call it
  /// on a [normalized] copy.
  void validate() {
    if (dayOfWeek < 0 || dayOfWeek > 6) {
      throw const ValidationFailure('Elegí un día de la semana.');
    }
    if (hhmm(start) == null) {
      throw const ValidationFailure('Elegí la hora de inicio.');
    }
    if (end != null && hhmm(end) == null) {
      throw const ValidationFailure('Elegí la hora de fin.');
    }
    if (end != null && end!.compareTo(start) <= 0) {
      throw const ValidationFailure(
        'La hora de fin debe ser posterior a la de inicio.',
      );
    }
  }

  /// Whether a preference on [day] starting at [otherStart] takes this
  /// slot: the server keeps one preference per customer, day and start,
  /// disabled ones included.
  bool sameSlot(int day, String otherStart) =>
      day == dayOfWeek && hhmm(otherStart) == hhmm(start);

  /// [time] (`H:mm`, `HH:mm` or `HH:mm:ss`) as `HH:mm`, or null when it is
  /// not a time of day.
  static String? hhmm(String? time) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::\d{2})?$',
    ).firstMatch(time?.trim() ?? '');
    if (match == null) return null;
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${match[2]}';
  }
}
