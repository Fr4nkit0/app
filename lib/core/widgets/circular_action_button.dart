import 'package:flutter/material.dart';

class CircularActionButton extends StatelessWidget {
  const CircularActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.label,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = color ?? theme.colorScheme.primary;

    final button = GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: baseColor, size: 22),
      ),
    );

    if (label == null) {
      return button;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 6),
        Text(
          label!,
          style: TextStyle(
            color: baseColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
