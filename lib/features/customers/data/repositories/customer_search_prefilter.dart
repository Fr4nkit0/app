import 'package:app/core/services/database.helper.dart';
import 'package:app/core/utils/string_utils.dart';
import 'package:app/features/customers/domain/models/customer_number.dart';
import 'package:drift/drift.dart';

/// Narrows the customer search in SQL to a superset of what
/// `CustomerSearch` would match, so only those candidates are loaded and
/// ranked in Dart. Nothing is stored: the text is folded at query time.
abstract final class CustomerSearchPrefilter {
  /// Pairs replaced while folding, mirroring [StringUtils.removeDiacritics].
  /// SQLite's `lower()` only folds ASCII, so accented capitals are listed
  /// too.
  static const _accents = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', //
    'Á': 'a', 'À': 'a', 'Ä': 'a', 'Â': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'É': 'e', 'È': 'e', 'Ë': 'e', 'Ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'Í': 'i', 'Ì': 'i', 'Ï': 'i', 'Î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o',
    'Ó': 'o', 'Ò': 'o', 'Ö': 'o', 'Ô': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'Ú': 'u', 'Ù': 'u', 'Ü': 'u', 'Û': 'u',
    'ñ': 'n', 'Ñ': 'n',
  };

  /// Punctuation removed while folding, as [StringUtils.removeDiacritics]
  /// does, so "O'Higgins" folds to "ohiggins".
  static const _punctuation = [
    "'", '`', '´', '.', ',', '-', '_', '/', '(', ')', '"', '#', 'º', '°', //
    '&', ';', ':', '!', '?', '¿', '¡', '+', '*',
  ];

  /// [text] lowercased, without accents and without common punctuation:
  /// the SQL counterpart of [StringUtils.removeDiacritics].
  ///
  /// Known, accepted gap: a character outside these lists that Dart turns
  /// into a letter (e.g. the Kelvin sign or a Turkish dotted İ) could make
  /// the SQL side miss a match. Characters Dart only strips are harmless:
  /// the match is a subsequence, so extra characters left in SQL never hide
  /// one. The lists cover Spanish names and addresses.
  static Expression<String> fold(Expression<String> text) {
    var folded = text.lower();
    for (final MapEntry(:key, :value) in _accents.entries) {
      folded = _replace(folded, key, value);
    }
    for (final mark in _punctuation) {
      folded = _replace(folded, mark, '');
    }
    return folded;
  }

  static Expression<String> _replace(
    Expression<String> text,
    String from,
    String to,
  ) => FunctionCallExpression<String>('replace', [
    text,
    Constant(from),
    Constant(to),
  ]);

  /// The folded words of [query], as `CustomerSearch` reads them: only
  /// `[a-z0-9]`, so they need no LIKE escaping.
  static List<String> words(String query) => StringUtils.removeDiacritics(
    query,
  ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

  /// True for a customer row of [customers] that could match [query]: its
  /// number is the one [query] asks for, or every query word's letters
  /// appear in order in its folded name or in the folded street or
  /// neighborhood of one of its enabled addresses. That subsequence test
  /// contains every tier of `CustomerSearch` (number, word prefix and
  /// loose), so ranking the candidates in Dart gives the same result as
  /// ranking every customer.
  static Expression<bool> candidates(
    AppDatabase db,
    $CustomerTableTable customers,
    String query,
  ) {
    final number = CustomerNumber.parse(query);
    final byNumber = number == null
        ? const Constant(false)
        : customers.serverId.equals(number);

    final queryWords = words(query);
    if (queryWords.isEmpty) return byNumber;

    Expression<bool> byWords = const Constant(true);
    for (final word in queryWords) {
      final pattern = '%${word.split('').join('%')}%';
      final addresses = db.select(db.customerAddressTable)
        ..where(
          (a) =>
              a.customerId.equalsExp(customers.customerId) &
              a.enabled.equals(true) &
              (fold(a.street).like(pattern) |
                  fold(a.neighborhood).like(pattern)),
        );
      byWords =
          byWords &
          (fold(customers.name).like(pattern) | existsQuery(addresses));
    }
    return byNumber | byWords;
  }
}
