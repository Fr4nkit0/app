import 'package:app/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/widgets/sync_badge.dart';

class HistoryEntryTile extends StatelessWidget {
  const HistoryEntryTile({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);
    final style = _HistoryEntryVisual.forType(entry.type, tokens);
    final timeStr =
        '${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}';
    final avatarColors = AvatarUtils.getColors(
      entry.customerName,
      baseColor: AvatarUtils.getPastelColor(entry.customerName),
    );
    final initials = AvatarUtils.getInitials(entry.customerName);
    final showAmount =
        entry.amount != null &&
        (entry.type == HistoryEntryType.sale ||
            entry.type == HistoryEntryType.payment);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: tokens.border.withValues(alpha: tokens.border.a * 0.85),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: style.iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(style.icon, color: style.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.customerName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: tokens.brandNavy,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    style.typeLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tokens.textMuted,
                    ),
                  ),
                  if (entry.description.trim().isNotEmpty &&
                      entry.description.trim().toLowerCase() !=
                          entry.customerName.toLowerCase()) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tokens.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                  if (entry.status == PendingStatus.rejected &&
                      entry.rejectionReason != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Motivo: ${entry.rejectionReason}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: tokens.destructive,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (showAmount)
                  Text(
                    formatMoney(entry.amount!),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: entry.type == HistoryEntryType.payment
                          ? tokens.destructive
                          : tokens.brandNavy,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColors.background,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: avatarColors.foreground,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SyncStatusPill(status: entry.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntryVisual {
  const _HistoryEntryVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.typeLabel,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String typeLabel;

  static _HistoryEntryVisual forType(
    HistoryEntryType type,
    MarilinTokens tokens,
  ) {
    switch (type) {
      case HistoryEntryType.visit:
        return _HistoryEntryVisual(
          icon: Icons.place_outlined,
          iconColor: tokens.brandBlue,
          iconBackground: tokens.brandBlue.withValues(alpha: 0.1),
          typeLabel: 'Visita',
        );
      case HistoryEntryType.sale:
        return _HistoryEntryVisual(
          icon: Icons.shopping_bag_outlined,
          iconColor: tokens.brandBlue,
          iconBackground: tokens.brandBlue.withValues(alpha: 0.1),
          typeLabel: 'Venta',
        );
      case HistoryEntryType.payment:
        return _HistoryEntryVisual(
          icon: Icons.payments_outlined,
          iconColor: tokens.destructive,
          iconBackground: tokens.destructive.withValues(alpha: 0.08),
          typeLabel: 'Cobro',
        );
      case HistoryEntryType.delivery:
        return _HistoryEntryVisual(
          icon: Icons.water_drop_outlined,
          iconColor: tokens.brandBlue,
          iconBackground: tokens.brandBlue.withValues(alpha: 0.1),
          typeLabel: 'Entrega',
        );
      case HistoryEntryType.customer:
        return _HistoryEntryVisual(
          icon: Icons.person_outline_rounded,
          iconColor: tokens.brandBlue,
          iconBackground: tokens.brandBlue.withValues(alpha: 0.1),
          typeLabel: 'Cliente',
        );
      case HistoryEntryType.agreement:
        return _HistoryEntryVisual(
          icon: Icons.handshake_outlined,
          iconColor: tokens.brandBlue,
          iconBackground: tokens.brandBlue.withValues(alpha: 0.1),
          typeLabel: 'Acuerdo',
        );
      case HistoryEntryType.routeStop:
        return _HistoryEntryVisual(
          icon: Icons.schedule_rounded,
          iconColor: tokens.brandBlue,
          iconBackground: tokens.brandBlue.withValues(alpha: 0.1),
          typeLabel: 'Parada',
        );
    }
  }
}
