import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/money_formatter.dart';

void main() {
  group('formatMoney', () {
    test('formats zero', () => expect(formatMoney(0), '\$0'));
    test('formats amounts below one thousand', () {
      expect(formatMoney(999), '\$999');
    });
    test('separates thousands with dots', () {
      expect(formatMoney(1000), '\$1.000');
      expect(formatMoney(12500), '\$12.500');
      expect(formatMoney(1234567), '\$1.234.567');
    });
    test('uses two decimals with a comma for non-whole amounts', () {
      expect(formatMoney(12500.5), '\$12.500,50');
    });
    test('keeps the sign before the symbol for negative amounts', () {
      expect(formatMoney(-1500), '-\$1.500');
    });
  });
}
