import 'package:app/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

class VisitDebtBanner extends StatelessWidget {
  const VisitDebtBanner({
    super.key,
    required this.debtAmount,
    required this.onTap,
  });

  final double debtAmount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final interactive = onTap != null;

    return Material(
      color: MarilinColors.destructive.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MarilinColors.destructive.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: MarilinColors.destructive,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Deuda pendiente',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MarilinColors.destructive.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Text(
                formatMoney(-debtAmount),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: MarilinColors.destructive,
                ),
              ),
              if (interactive) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: MarilinColors.destructive,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
