import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';

class DebtChip extends StatelessWidget {
  const DebtChip({
    super.key,
    required this.amount,
    this.margin,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
    this.backgroundColor,
    this.borderColor = MarilinColors.destructive,
    this.borderWidth = 1.5,
    this.textColor = MarilinColors.destructive,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    this.icon,
    this.iconSize = 16,
    this.iconColor,
    this.prefixText = 'Debe ',
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

  @override
  Widget build(BuildContext context) {
    if (amount <= 0) return const SizedBox.shrink();
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: iconColor ?? textColor),
            const SizedBox(width: 4),
          ],
          Text(
            '$prefixText${formatMoney(amount)}',
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
}
