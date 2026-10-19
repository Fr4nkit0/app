import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/presentation/widgets/visit_container_return_dialog.dart';

class VisitCustodyBanner extends ConsumerWidget {
  const VisitCustodyBanner({
    super.key,
    required this.stop,
  });

  final RouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balancesAsync = ref.watch(
      customerContainerBalancesProvider(stop.customer.id),
    );

    return balancesAsync.when(
      data: (balances) {
        final bidon = balances
            .firstWhere(
              (b) => b.containerType == 'BIDON_20L',
              orElse: () => CustomerContainerBalance(
                customerId: stop.customer.id,
                containerType: 'BIDON_20L',
                quantity: 0,
              ),
            )
            .quantity;
        final sifon = balances
            .firstWhere(
              (b) => b.containerType == 'SIFON_2L',
              orElse: () => CustomerContainerBalance(
                customerId: stop.customer.id,
                containerType: 'SIFON_2L',
                quantity: 0,
              ),
            )
            .quantity;

        final isDone = stop.status != StopStatus.pending;
        final canReturn = !isDone && (bidon > 0 || sifon > 0);

        return Material(
          color: MarilinColors.brandBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: canReturn
                ? () {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          StandaloneContainerReturnDialog(stop: stop),
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MarilinColors.brandBlue.withValues(alpha: 0.12),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Envases bajo custodia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: MarilinColors.brandNavy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            VisitContainerBadge(
                              icon: Icons.water_drop_outlined,
                              label: 'Bidón 20L',
                              count: bidon,
                            ),
                            const SizedBox(width: 8),
                            VisitContainerBadge(
                              icon: Icons.local_drink_outlined,
                              label: 'Sifón 2L',
                              count: sifon,
                            ),
                          ],
                        ),
                      ],
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
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
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
        : const Color(0xFFF1F5F9);
    final textColor =
        hasStock ? MarilinColors.brandBlue : MarilinColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasStock
              ? MarilinColors.brandBlue.withValues(alpha: 0.15)
              : MarilinColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
