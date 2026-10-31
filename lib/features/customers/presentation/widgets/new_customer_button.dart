import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

class NewCustomerButton extends StatelessWidget {
  const NewCustomerButton({
    super.key,
    required this.onTap,
    this.backgroundColor,
  });

  final VoidCallback onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? MarilinTokens.of(context).brandBlue;

    return Tooltip(
      message: 'Nuevo cliente',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bg.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.person_add_alt_1_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
