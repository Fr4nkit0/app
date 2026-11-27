import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/money_input.dart';

TextEditingValue _typed(String text, [int? cursor]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

void main() {
  group('parseMoneyInput', () {
    test('reads dots as thousands separators', () {
      expect(parseMoneyInput('15.000'), 15000);
      expect(parseMoneyInput('340.000'), 340000);
      expect(parseMoneyInput('1.234.567'), 1234567);
    });

    test('reads plain digits as whole pesos', () {
      expect(parseMoneyInput(' 1500 '), 1500);
      expect(parseMoneyInput('0'), 0);
    });

    test('a dot is never a decimal separator', () {
      expect(parseMoneyInput('1.5'), 15);
    });

    test('returns null for empty or invalid input', () {
      expect(parseMoneyInput(''), isNull);
      expect(parseMoneyInput('.'), isNull);
      expect(parseMoneyInput('abc'), isNull);
      expect(parseMoneyInput('1500,50'), isNull);
      expect(parseMoneyInput('-100'), isNull);
    });
  });

  group('formatMoneyInput', () {
    test('groups thousands with dots, without symbol', () {
      expect(formatMoneyInput(0), '0');
      expect(formatMoneyInput(999), '999');
      expect(formatMoneyInput(15000), '15.000');
      expect(formatMoneyInput(340000), '340.000');
      expect(formatMoneyInput(1234567), '1.234.567');
    });
  });

  group('MoneyInputFormatter', () {
    const formatter = MoneyInputFormatter();

    TextEditingValue apply(TextEditingValue oldValue, TextEditingValue next) =>
        formatter.formatEditUpdate(oldValue, next);

    test('groups thousands while typing and keeps the cursor at the end', () {
      final result = apply(_typed('1.500'), _typed('1.5000'));
      expect(result.text, '15.000');
      expect(result.selection, const TextSelection.collapsed(offset: 6));

      final big = apply(_typed('34.000'), _typed('34.0000'));
      expect(big.text, '340.000');
      expect(big.selection, const TextSelection.collapsed(offset: 7));
    });

    test('groups a pasted number', () {
      final result = apply(_typed(''), _typed('340000'));
      expect(result.text, '340.000');
      expect(result.selection.baseOffset, 7);
    });

    test('drops anything that is not a digit', () {
      expect(apply(_typed(''), _typed('1500,50')).text, '150.050');
      expect(apply(_typed(''), _typed('15.000')).text, '15.000');
      expect(apply(_typed(''), _typed('abc')).text, '');
    });

    test(
      'keeps the cursor after the same digit when editing in the middle',
      () {
        // "1.500" with the cursor after "1": typing "2" gives "12.500" with
        // the cursor after the "2".
        final result = apply(_typed('1.500', 1), _typed('12.500', 2));
        expect(result.text, '12.500');
        expect(result.selection, const TextSelection.collapsed(offset: 2));

        // "15.000" with the cursor after "15.0": typing "9" gives "150.900"
        // with the cursor after the "9".
        final regrouped = apply(_typed('15.000', 4), _typed('15.0900', 5));
        expect(regrouped.text, '150.900');
        expect(regrouped.selection, const TextSelection.collapsed(offset: 5));
      },
    );

    test('backspace over a separator deletes the digit before it', () {
      // "15.000" with the cursor after the dot: backspace removes the dot.
      final result = apply(_typed('15.000', 3), _typed('15000', 2));
      expect(result.text, '1.000');
      expect(result.selection, const TextSelection.collapsed(offset: 1));
    });

    test('drops leading zeros', () {
      expect(apply(_typed('0'), _typed('05')).text, '5');
      expect(apply(_typed(''), _typed('0')).text, '0');
    });

    test('clearing the field leaves it empty', () {
      final result = apply(_typed('5'), _typed(''));
      expect(result.text, '');
      expect(result.selection, const TextSelection.collapsed(offset: 0));
    });
  });
}
