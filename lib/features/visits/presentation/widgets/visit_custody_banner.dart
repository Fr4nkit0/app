import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';
import 'package:app/features/inventory/presentation/widgets/register_container_return_dialog.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

class VisitCustodyBanner extends ConsumerWidget {
  const VisitCustodyBanner({super.key, required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(
      customerContainerBalancesProvider(stop.customer.id),
    );
    final containerTypes = ref
        .watch(containerTypesProvider)
        .maybeWhen(data: (types) => types, orElse: () => <ContainerType>[]);

    return balancesAsync.when(
      data: (balances) {
        final custody = custodyByContainerType(balances);

        final isDone = stop.status != StopStatus.pending;
        final canReturn =
            !isDone &&
            containerTypes.any((type) => (custody[type.code] ?? 0) > 0);

        return Material(
          color: MarilinColors.brandBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: canReturn
                ? () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => RegisterContainerReturnDialog(
                        customerId: stop.customer.id,
                        visitId: stop.id,
                      ),
                    );
                  }
                : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: MarilinColors.brandBlue.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              // The badges take the full width of the banner, so their
              // labels are not squeezed by the icon and the chevron.
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: MarilinColors.brandBlue.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: MarilinColors.brandBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Envases bajo custodia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: context.marilin.ink,
                          ),
                        ),
                      ),
                      if (canReturn)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: MarilinColors.brandBlue,
                          size: 22,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  VisitContainerBadges(
                    containerTypes: containerTypes,
                    custody: custody,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Containers the customer holds of each catalog type, side by side; a
/// badge that does not fit moves to the next line instead of shortening.
class VisitContainerBadges extends StatelessWidget {
  const VisitContainerBadges({
    super.key,
    required this.containerTypes,
    required this.custody,
  });

  final List<ContainerType> containerTypes;

  /// Containers held by container code; a type absent here counts as 0.
  final Map<String, int> custody;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (index, type) in containerTypes.indexed)
          VisitContainerBadge(
            icon: containerTypeIcon(index),
            label: type.label,
            count: custody[type.code] ?? 0,
          ),
      ],
    );
  }
}

class VisitContainerBadge extends StatelessWidget {
  const VisitContainerBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final hasStock = count > 0;
    final bgColor = hasStock
        ? MarilinColors.brandBlue.withValues(alpha: 0.08)
        : context.marilin.fill;
    final textColor = hasStock
        ? MarilinColors.brandBlue
        : context.marilin.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasStock
              ? MarilinColors.brandBlue.withValues(alpha: 0.15)
              : context.marilin.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          // Never cut: wider than the row, it breaks into lines.
          Flexible(
            child: Text.rich(
              TextSpan(
                text: '$label · ',
                children: [
                  TextSpan(
                    text: '$count',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
