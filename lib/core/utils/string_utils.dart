class StringUtils {
  static String removeDiacritics(String text) {
    var s = text.toLowerCase();
    s = s.replaceAll(RegExp(r'[áàäâ]'), 'a');
    s = s.replaceAll(RegExp(r'[éèëê]'), 'e');
    s = s.replaceAll(RegExp(r'[íìïî]'), 'i');
    s = s.replaceAll(RegExp(r'[óòöô]'), 'o');
    s = s.replaceAll(RegExp(r'[úùüû]'), 'u');
    s = s.replaceAll(RegExp(r'[ñ]'), 'n');
    s = s.replaceAll(RegExp(r'[^a-z0-9\s]'), '');
    return s.trim();
  }

  static bool isSubsequence(String sub, String target) {
    if (sub.isEmpty) return true;
    int subIdx = 0;
    for (int i = 0; i < target.length; i++) {
      if (target[i] == sub[subIdx]) {
        subIdx++;
        if (subIdx == sub.length) return true;
      }
    }
    return false;
  }

  static bool fuzzyMatch(String query, String target) {
    final normalizedQuery = removeDiacritics(query);
    if (normalizedQuery.isEmpty) return true;
    final normalizedTarget = removeDiacritics(target);
    final queryWords = normalizedQuery.split(RegExp(r'\s+'));

    for (final word in queryWords) {
      if (word.isEmpty) continue;
      if (word.length == 1) {
        if (!normalizedTarget.startsWith(word) &&
            !normalizedTarget.contains(' $word')) {
          return false;
        }
      } else {
        if (!isSubsequence(word, normalizedTarget)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Like [fuzzyMatch], but every query word must begin where a target
  /// word begins, so "centro" no longer matches "Servicio Penitenciario".
  static bool wordStartMatch(String query, String target) {
    final normalizedQuery = removeDiacritics(query);
    if (normalizedQuery.isEmpty) return true;
    final normalizedTarget = removeDiacritics(target);
    final wordStarts = RegExp(
      r'\S+',
    ).allMatches(normalizedTarget).map((m) => m.start).toList();

    for (final word in normalizedQuery.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final matches = wordStarts.any(
        (start) =>
            normalizedTarget[start] == word[0] &&
            isSubsequence(word, normalizedTarget.substring(start)),
      );
      if (!matches) return false;
    }
    return true;
  }
}
