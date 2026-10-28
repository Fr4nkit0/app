/// Formats [value] as money: `$` + thousands separated by `.`, no decimals for
/// whole amounts (`$12.500`) and two decimals with `,` otherwise (`$12.500,50`).
String formatMoney(double value) {
  final isWhole = value == value.roundToDouble();
  final parts = value.abs().toStringAsFixed(isWhole ? 0 : 2).split('.');
  final digits = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final decimals = parts.length > 1 ? ',${parts[1]}' : '';
  return '${value < 0 ? '-' : ''}\$$buffer$decimals';
}
