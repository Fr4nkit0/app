import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/string_utils.dart';

void main() {
  group('StringUtils.removeDiacritics', () {
    test('removes accents and lowercases', () {
      expect(StringUtils.removeDiacritics('ÁÉÍÓÚüñ'), 'aeiouun');
      expect(StringUtils.removeDiacritics('San Ramón'), 'san ramon');
      expect(StringUtils.removeDiacritics('17 de Mayo'), '17 de mayo');
    });

    test('removes non-alphanumeric except space', () {
      expect(StringUtils.removeDiacritics('Hello, World! 123'), 'hello world 123');
    });
  });

  group('StringUtils.fuzzyMatch', () {
    test('empty query matches everything', () {
      expect(StringUtils.fuzzyMatch('', 'any target'), isTrue);
      expect(StringUtils.fuzzyMatch('  ', 'any target'), isTrue);
    });

    test('exact matching with diacritics', () {
      expect(StringUtils.fuzzyMatch('ramon', 'San Ramón'), isTrue);
      expect(StringUtils.fuzzyMatch('San Ramón', 'ramon'), isFalse);
    });

    test('single character query matches start of word or sub-word start', () {
      expect(StringUtils.fuzzyMatch('s', 'San Ramón'), isTrue);
      expect(StringUtils.fuzzyMatch('r', 'San Ramón'), isTrue);
      expect(StringUtils.fuzzyMatch('a', 'San Ramón'), isFalse);
    });

    test('tokenized subsequence matches', () {
      expect(StringUtils.fuzzyMatch('1 mao', '17 de Mayo'), isTrue);
      expect(StringUtils.fuzzyMatch('17 mayo', '17 de Mayo'), isTrue);
      expect(StringUtils.fuzzyMatch('may 17', '17 de Mayo'), isTrue);
      expect(StringUtils.fuzzyMatch('1 mao', '1 de Mayo'), isTrue);
      expect(StringUtils.fuzzyMatch('2 abr', '2 de Abril'), isTrue);
    });

    test('negative matches', () {
      expect(StringUtils.fuzzyMatch('17 oct', '17 de Mayo'), isFalse);
      expect(StringUtils.fuzzyMatch('xyz', 'San Ramón'), isFalse);
    });
  });
}
