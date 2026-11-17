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
    // Same height for both cards, whatever the subtitle length.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _ModeCard(
              title: 'Registrar venta',
              subtitle: 'Cobrás productos ahora',
              icon: Icons.point_of_sale_outlined,
              isSelected: isSaleSelected,
              onTap: onSelectSale,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModeCard(
              title: 'Solo visita',
              subtitle: 'Sin venta: entrega, gestión o ausente',
              icon: Icons.assignment_turned_in_outlined,
              isSelected: !isSaleSelected,
              onTap: onSelectVisit,
            ),
          ),
        ],
      ),
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
    final tokens = context.marilin;
    final activeColor = tokens.brandBlue;

    return Semantics(
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.14)
                  : tokens.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? activeColor : tokens.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  // Top-aligned so icon and title line up across both cards,
                  // even when one subtitle wraps to two lines.
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.18)
                            : tokens.fill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: isSelected ? activeColor : tokens.inkSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // The unselected card stays readable: it is an option,
                    // not a disabled control.
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: tokens.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: tokens.textMuted,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -6,
                  right: -6,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isSelected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: activeColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
