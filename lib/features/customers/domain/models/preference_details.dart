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

  /// Whether this window and [other] share a moment of the same day.
  /// Windows are half-open, so touching edges do not overlap, and a window
  /// without an end lasts until the end of the day.
  bool overlaps(PreferenceDetails other) {
    if (other.dayOfWeek != dayOfWeek) return false;
    return _from(start).compareTo(_until(other.end)) < 0 &&
        _from(other.start).compareTo(_until(end)) < 0;
  }

  /// The window as the driver reads it: `HH:mm–HH:mm`, `desde HH:mm`,
  /// `hasta HH:mm` or `todo el día`.
  String get label {
    final from = hhmm(start) ?? start;
    final until = end == null ? null : hhmm(end) ?? end;
    final hasStart = from != noStart;
    if (until == null) return hasStart ? 'desde $from' : 'todo el día';
    return hasStart ? '$from–$until' : 'hasta $until';
  }

  static String _from(String start) => hhmm(start) ?? start;

  /// `24:00` sorts after every `HH:mm`, standing for the end of the day.
  static String _until(String? end) => end == null ? '24:00' : hhmm(end) ?? end;

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
