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
    this.statusLabel,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;

  /// Formatted amount shown on the right, when the record has one.
  final String? amount;

  /// Shown for a record that no longer counts (a cancelled payment); its
  /// amount is struck through.
  final String? statusLabel;

  /// What the driver can do with the record, below it.
  final Widget? action;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
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
                    if (statusLabel != null) ...[
                      const SizedBox(height: 6),
                      RecordStatusBadge(label: statusLabel!),
                    ],
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
                    color: statusLabel == null
                        ? context.marilin.ink
                        : context.marilin.inkHint,
                    decoration: statusLabel == null
                        ? null
                        : TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Marks a sale or payment that no longer counts.
class RecordStatusBadge extends StatelessWidget {
  const RecordStatusBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.marilin.soft(
          MarilinColors.destructive.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: context.marilin.vivid(MarilinColors.destructive),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
