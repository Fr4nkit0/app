import 'package:flutter/material.dart';

class DebtChip extends StatelessWidget {
  const DebtChip({
    super.key,
    required this.amount,
    this.margin,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
    this.backgroundColor,
    this.borderColor = const Color(0xFFBF1B1B),
    this.borderWidth = 1.5,
    this.textColor = const Color(0xFFBF1B1B),
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    this.icon,
    this.iconSize = 16,
    this.iconColor,
    this.prefixText = 'Deuda: \$',
    this.useRawAmountFormatting = false,
  });

  final double amount;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final String prefixText;
  final bool useRawAmountFormatting;

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor != null ? Border.all(color: borderColor!, width: borderWidth) : null,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? textColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            '$prefixText${useRawAmountFormatting ? amount.toString() : _formatAmount(amount)}',
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            ),
          ),
        ],
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
