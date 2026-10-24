import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';

class HistoryTypeFilterBar extends StatelessWidget {
  const HistoryTypeFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final HistoryEntryType? selected;
  final ValueChanged<HistoryEntryType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Todo',
            selected: selected == null,
            onTap: () => onSelected(null),
            tokens: tokens,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Ventas',
            selected: selected == HistoryEntryType.sale,
            onTap: () => onSelected(HistoryEntryType.sale),
            tokens: tokens,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Visitas',
            selected: selected == HistoryEntryType.visit,
            onTap: () => onSelected(HistoryEntryType.visit),
            tokens: tokens,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cobros',
            selected: selected == HistoryEntryType.payment,
            onTap: () => onSelected(HistoryEntryType.payment),
            tokens: tokens,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Entregas',
            selected: selected == HistoryEntryType.delivery,
            onTap: () => onSelected(HistoryEntryType.delivery),
            tokens: tokens,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final MarilinTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? tokens.brandBlue.withValues(alpha: 0.12) : tokens.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tokens.brandBlue : tokens.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: selected ? tokens.brandBlue : tokens.brandNavy,
            ),
          ),
        ),
      ),
    );
  }
}
