import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';

/// A payment or a container return recorded in the visit, listed in its
/// REGISTRO section next to the sales.
class VisitRecordTile extends StatelessWidget {
  const VisitRecordTile({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.amount,
  });

  final IconData icon;
  final String title;
  final String detail;

  /// Formatted amount shown on the right, when the record has one.
  final String? amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.marilin.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: MarilinColors.brandBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.marilin.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.marilin.inkSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          if (amount != null) ...[
            const SizedBox(width: 12),
            Text(
              amount!,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: context.marilin.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
