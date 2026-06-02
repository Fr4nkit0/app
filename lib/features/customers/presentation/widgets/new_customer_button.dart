import 'package:flutter/material.dart';

class NewCustomerButton extends StatelessWidget {
  const NewCustomerButton({
    super.key,
    required this.onTap,
    this.backgroundColor = const Color(0xFF1565C0),
  });

  final VoidCallback onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withValues(alpha: 0.25),
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
    );
  }
}
