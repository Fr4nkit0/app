import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/history/presentation/providers/paginated_history_provider.dart';

class HistoryTodaySummaryRow extends StatelessWidget {
  const HistoryTodaySummaryRow({super.key, required this.summary});

  final HistoryTodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    if (summary.totalActivity == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.border),
        ),
        child: Text(
          'Todavía no hay actividad registrada hoy.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: tokens.textMuted,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: _SummaryChip(
            icon: Icons.shopping_cart_outlined,
            label: 'Ventas',
            value: summary.sales,
            accent: tokens.brandBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryChip(
            icon: Icons.place_outlined,
            label: 'Visitas',
            value: summary.visits,
            accent: tokens.brandBlue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryChip(
            icon: Icons.payments_outlined,
            label: 'Cobros',
            value: summary.payments,
            accent: tokens.destructive,
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: tokens.brandNavy,
              height: 1,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
