import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';

String _formatArsAmount(double amount) {
  final rounded = amount.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  final body = buffer.toString();
  return rounded < 0 ? '-\$$body' : '\$$body';
}

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
      entry.customer.name,
      baseColor: AvatarUtils.getPastelColor(entry.customer.name),
    );
    final initials = AvatarUtils.getInitials(entry.customer.name);
    final showAmount = entry.amount != null &&
        (entry.type == HistoryEntryType.sale ||
            entry.type == HistoryEntryType.payment);

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border.withValues(alpha: 0.85)),
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
                          entry.customer.name,
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
                          entry.customer.name.toLowerCase()) ...[
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
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: entry.tags.map((tag) {
                        final isMixto = tag.toLowerCase() == 'mixto';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isMixto
                                ? tokens.success.withValues(alpha: 0.12)
                                : tokens.brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: isMixto
                                  ? tokens.success
                                  : tokens.brandBlue,
                              letterSpacing: 0.2,
                            ),
                          ),
                        );
                      }).toList(),
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
                    _formatArsAmount(entry.amount!),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: avatarColors.foreground,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                _SyncBadge(isSynced: entry.isSynced, tokens: tokens),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.isSynced, required this.tokens});

  final bool isSynced;
  final MarilinTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (isSynced) {
      return Tooltip(
        message: 'Sincronizado',
        child: Icon(
          Icons.check_circle_rounded,
          size: 20,
          color: tokens.success,
        ),
      );
    }
    return Tooltip(
      message: 'Pendiente de subir',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: tokens.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 14, color: tokens.accent),
            const SizedBox(width: 3),
            Text(
              'Cola',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: tokens.accent,
              ),
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
    }
  }
}
