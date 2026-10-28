import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

/// Sale vs solo-visit mode toggle on the visit stop screen.
class VisitModeSelector extends StatelessWidget {
  const VisitModeSelector({
    super.key,
    required this.isSaleSelected,
    required this.onSelectSale,
    required this.onSelectVisit,
  });

  final bool isSaleSelected;
  final VoidCallback onSelectSale;
  final VoidCallback onSelectVisit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            title: 'Registrar Venta',
            subtitle: 'Facturar bidones',
            icon: Icons.point_of_sale_outlined,
            isSelected: isSaleSelected,
            onTap: onSelectSale,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeCard(
            title: 'Visita',
            subtitle: 'Entrega o gestión',
            icon: Icons.assignment_turned_in_outlined,
            isSelected: !isSaleSelected,
            onTap: onSelectVisit,
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = MarilinColors.brandBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.08)
                : context.marilin.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : context.marilin.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : context.marilin.textMuted,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: isSelected
                      ? context.marilin.ink
                      : context.marilin.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.marilin.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
