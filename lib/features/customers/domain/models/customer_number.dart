/// The number drivers know a customer by: its server id, shown as "#128".
/// A customer created on the device has none until its first push.
abstract final class CustomerNumber {
  static final _query = RegExp(r'^#?(\d{1,9})$');

  /// The number as shown: `#128`.
  static String format(int number) => '#$number';

  /// The number [query] asks for: only digits, with an optional leading
  /// `#`; null for any other query.
  static int? parse(String query) {
    final match = _query.firstMatch(query.trim());
    return match == null ? null : int.parse(match.group(1)!);
  }

  /// Whether [query] asks for a number and nothing else (`#128`).
  static bool isExplicit(String query) =>
      query.trim().startsWith('#') && parse(query) != null;

  /// Whether [query] asks for exactly [number]. A customer without a
  /// number never matches.
  static bool matches(String query, int? number) {
    if (number == null) return false;
    return parse(query) == number;
  }
}
