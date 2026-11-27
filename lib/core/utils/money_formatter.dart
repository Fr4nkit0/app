/// Formats [value] whole pesos as money: `$` + thousands separated by `.`
/// (`$12.500`). Money never has cents, so no decimals are printed.
String formatMoney(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}\$$buffer';
}

/// A customer account [balance] in driver copy: `Debe $1.500` when the
/// customer owes, `Saldo a favor: $200` when they hold credit, `Al día`
/// otherwise. Never a negative amount.
String formatAccountBalance(int balance) => balance > 0
    ? 'Debe ${formatMoney(balance)}'
    : balance == 0
    ? 'Al día'
    : 'Saldo a favor: ${formatMoney(-balance)}';
