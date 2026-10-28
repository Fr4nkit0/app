import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

/// Section label for the visit stop screen (Operate / scan-first hierarchy).
class VisitSectionHeader extends StatelessWidget {
  const VisitSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: tokens.textMuted,
              letterSpacing: 1.0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: tokens.brandNavy.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
