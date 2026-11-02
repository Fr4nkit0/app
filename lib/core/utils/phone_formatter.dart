import 'package:flutter/services.dart';

const _maxDigits = 10;

/// Formats [value] as a Salta phone number, `387 587-4823`: area code, space,
/// three digits, dash, four digits. Non-digits are dropped, as are a leading
/// country code (`54`) and a leading `0`; partial input is formatted as far as
/// it goes (`387 5`).
String formatPhone(String value) {
  var digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('54') && digits.length > _maxDigits) {
    digits = digits.substring(2);
  }
  if (digits.startsWith('0')) digits = digits.substring(1);
  if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i == 3) buffer.write(' ');
    if (i == 6) buffer.write('-');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Formats a phone field with [formatPhone] while the driver types.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = formatPhone(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
