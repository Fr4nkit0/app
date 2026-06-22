import 'package:flutter/material.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onBackPressed,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Title (always centered)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 56),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(
                          0xFF0F4C81,
                        ), // Elegant blue matching Historial exactly
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Back button (left aligned)
                if (onBackPressed != null)
                  Positioned(
                    left: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onBackPressed,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Slate 100
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0), // Slate 200
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 14,
                            color: Color(0xFF0F4C81),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Trailing widget (right aligned)
                if (trailing != null) Positioned(right: 0, child: trailing!),
              ],
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B), // Muted slate text
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
      ],
    );
  }
}
