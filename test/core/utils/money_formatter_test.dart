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
    test('takes whole pesos and never prints decimals', () {
      const String Function(int) format = formatMoney;
      expect(format(12500), '\$12.500');
      expect(format(1), '\$1');
    });
    test('keeps the sign before the symbol for negative amounts', () {
      expect(formatMoney(-1500), '-\$1.500');
    });
  });

  group('formatAccountBalance', () {
    test('a debt reads "Debe"', () {
      expect(formatAccountBalance(1500), r'Debe $1.500');
    });
    test('zero reads "Al día"', () {
      expect(formatAccountBalance(0), 'Al día');
    });
    test('a credit reads "Saldo a favor" without a sign', () {
      const String Function(int) format = formatAccountBalance;
      expect(format(-200), r'Saldo a favor: $200');
    });
  });
}
