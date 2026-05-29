import 'package:flutter/material.dart';

class DebtChip extends StatelessWidget {
  const DebtChip({super.key, required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBF1B1B), width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Deuda: \$${_formatAmount(amount)}',
        style: const TextStyle(
          color: Color(0xFFBF1B1B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatAmount(double value) {
    final intVal = value.toInt();
    final str = intVal.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
