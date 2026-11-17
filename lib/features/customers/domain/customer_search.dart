import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer_number.dart';

/// How well a customer matches what the driver typed, best first.
enum CustomerMatch {
  /// The query is the customer's number (`128` or `#128`).
  number,

  /// Every query word begins a word of the name.
  name,

  /// Every query word begins a word of the name, an address or a
  /// neighborhood. The phone is never searched: digits are the customer
  /// number, and a phone with the same digits would get in its way.
  details,

  /// Loose: every query word's letters appear in order inside a single
  /// word ("mao" in "Mayo"). Only offered when nothing matches better.
  loose,
}

/// Ranks customers against a search query. Case and accents are ignored.
abstract final class CustomerSearch {
  /// How [customer] matches [query]; null when it does not.
  static CustomerMatch? match(String query, Customer customer) {
    final words = _words(query);
    if (words.isEmpty) return null;
    if (CustomerNumber.matches(query, customer.number)) {
      return CustomerMatch.number;
    }
    if (CustomerNumber.isExplicit(query)) return null;

    final nameWords = _words(customer.name);
    if (_allBeginWords(words, nameWords)) return CustomerMatch.name;

    final detailWords = [
      ...nameWords,
      for (final a in customer.addresses) ...[
        ..._words(a.street ?? ''),
        ..._words(a.neighborhood ?? ''),
      ],
    ];
    if (_allBeginWords(words, detailWords)) return CustomerMatch.details;

    final loose = words.every(
      (w) => detailWords.any((t) => StringUtils.isSubsequence(w, t)),
    );
    return loose ? CustomerMatch.loose : null;
  }

  /// The customers of [customers] that match [query], best match first and
  /// otherwise in their given order. Loose matches only show when nothing
  /// matches better.
  static List<Customer> filter(String query, List<Customer> customers) {
    final ranked = <(CustomerMatch, int, Customer)>[];
    for (final (i, c) in customers.indexed) {
      final m = match(query, c);
      if (m != null) ranked.add((m, i, c));
    }
    final hasStrong = ranked.any((r) => r.$1 != CustomerMatch.loose);
    final kept = hasStrong
        ? ranked.where((r) => r.$1 != CustomerMatch.loose).toList()
        : ranked;
    kept.sort((a, b) {
      final byMatch = a.$1.index.compareTo(b.$1.index);
      return byMatch != 0 ? byMatch : a.$2.compareTo(b.$2);
    });
    return [for (final r in kept) r.$3];
  }

  /// How [name] matches [query] on its own: [CustomerMatch.name] when
  /// every query word begins a word of it, [CustomerMatch.loose] when each
  /// query word's letters appear in order inside one of its words.
  static CustomerMatch? matchName(String query, String name) {
    final words = _words(query);
    if (words.isEmpty) return null;
    final nameWords = _words(name);
    if (_allBeginWords(words, nameWords)) return CustomerMatch.name;
    final loose = words.every(
      (w) => nameWords.any((t) => StringUtils.isSubsequence(w, t)),
    );
    return loose ? CustomerMatch.loose : null;
  }

  static List<String> _words(String text) => StringUtils.removeDiacritics(
    text,
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  static bool _allBeginWords(List<String> query, List<String> target) =>
      query.every((q) => target.any((t) => t.startsWith(q)));
}
