import 'package:flutter/services.dart';

/// Money inputs follow the Argentine convention: amounts are whole pesos and
/// the dot is the thousands separator, never a decimal one.

final _digitsWithDots = RegExp(r'^[\d.]+$');

/// Parses a typed amount in whole pesos ("15.000" -> 15000, "1500" -> 1500).
/// Dots are thousands separators. Returns null for empty or invalid input,
/// such as a comma or a sign.
int? parseMoneyInput(String text) {
  final trimmed = text.trim();
  if (!_digitsWithDots.hasMatch(trimmed)) return null;
  final digits = trimmed.replaceAll('.', '');
  if (digits.isEmpty) return null;
  return int.tryParse(digits);
}

/// The editable text of [value] whole pesos: thousands grouped with dots and
/// no symbol (15000 -> "15.000").
String formatMoneyInput(int value) => _group(value.abs().toString());

String _group(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

int _digitCount(String text) {
  var count = 0;
  for (final unit in text.codeUnits) {
    if (unit >= 0x30 && unit <= 0x39) count++;
  }
  return count;
}

String _digitsOnly(String text) => text.replaceAll(RegExp(r'\D'), '');

/// Keeps a money field to digits and shows them grouped by thousands while
/// typing (typing 15000 shows "15.000"). The cursor stays after the same
/// digit it followed before grouping.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = _digitsOnly(newValue.text);
    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length)
        : newValue.text.length;
    var digitsBeforeCursor = _digitCount(newValue.text.substring(0, cursor));

    // Backspace over a separator only removed the dot: delete the digit
    // before it instead, so the edit is not undone by regrouping.
    // Only a real backspace counts: a collapsed cursor right after the dot.
    // Replacing a selection with the same digits is not one.
    final oldSelection = oldValue.selection;
    final removedOnlySeparator =
        newValue.text.length == oldValue.text.length - 1 &&
        oldSelection.isValid &&
        oldSelection.isCollapsed &&
        oldSelection.extentOffset == cursor + 1 &&
        oldValue.text[cursor] == '.' &&
        digits == _digitsOnly(oldValue.text) &&
        digitsBeforeCursor > 0;
    if (removedOnlySeparator) {
      digits =
          digits.substring(0, digitsBeforeCursor - 1) +
          digits.substring(digitsBeforeCursor);
      digitsBeforeCursor--;
    }

    // Leading zeros carry no value; a lone zero stays.
    var leadingZeros = 0;
    while (leadingZeros < digits.length - 1 && digits[leadingZeros] == '0') {
      leadingZeros++;
    }
    digits = digits.substring(leadingZeros);
    digitsBeforeCursor = (digitsBeforeCursor - leadingZeros).clamp(
      0,
      digits.length,
    );

    final text = _group(digits);
    var offset = 0;
    var seen = 0;
    while (seen < digitsBeforeCursor && offset < text.length) {
      if (text[offset] != '.') seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
