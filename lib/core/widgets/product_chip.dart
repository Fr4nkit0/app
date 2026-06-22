import 'package:flutter/material.dart';

class ProductChip extends StatelessWidget {
  const ProductChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.textColor,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
    this.icon = Icons.water_drop_outlined,
    this.iconSize = 13,
    this.iconColor,
    this.showIcon = true,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    final resolvedBackgroundColor =
        backgroundColor ?? (selected ? blue : blue.withValues(alpha: 0.1));
    final resolvedTextColor = textColor ?? (selected ? Colors.white : blue);
    final resolvedIconColor = iconColor ?? (selected ? Colors.white : blue);
    final border = borderColor != null
        ? Border.all(color: borderColor!, width: borderWidth)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: resolvedBackgroundColor,
          border: border,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(icon, size: iconSize, color: resolvedIconColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: resolvedTextColor,
                fontSize: fontSize,
                fontWeight: fontWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
