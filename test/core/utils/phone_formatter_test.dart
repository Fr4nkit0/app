import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/phone_formatter.dart';

void main() {
  group('formatPhone', () {
    test('formats a full Salta number as "387 587-4823"', () {
      expect(formatPhone('3875874823'), '387 587-4823');
    });

    test('formats partial input as it grows', () {
      expect(formatPhone(''), '');
      expect(formatPhone('38'), '38');
      expect(formatPhone('387'), '387');
      expect(formatPhone('3875'), '387 5');
      expect(formatPhone('387587'), '387 587');
      expect(formatPhone('3875874'), '387 587-4');
    });

    test('ignores any non-digit character', () {
      expect(formatPhone('387-587 48.23'), '387 587-4823');
    });

    test('drops the country code and a leading zero', () {
      expect(formatPhone('+54 387 421-1001'), '387 421-1001');
      expect(formatPhone('03874211001'), '387 421-1001');
    });

    test('caps the number at ten digits', () {
      expect(formatPhone('387587482399'), '387 587-4823');
    });
  });

  group('PhoneInputFormatter', () {
    TextEditingValue type(String text) => const PhoneInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text));

    test('formats the typed text and keeps the cursor at the end', () {
      final result = type('3875874823');
      expect(result.text, '387 587-4823');
      expect(result.selection, const TextSelection.collapsed(offset: 12));
    });

    test('lets the field be cleared', () {
      expect(type('').text, '');
    });
  });
}
