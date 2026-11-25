import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/domain/models/route_stop.dart';

/// One pending stop in the reorder list: its position, customer, address,
/// informative scheduled time and the handle the driver drags it by.
///
/// [index] is the stop's index in the list; the handle starts the drag of
/// that index, so the tile must be a direct child of a [ReorderableListView].
class ReorderStopTile extends StatelessWidget {
  const ReorderStopTile({super.key, required this.stop, required this.index});

  final RouteStop stop;
  final int index;

  static Key handleKey(String stopId) => ValueKey('reorder-handle-$stopId');

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final street = _primaryStreet();
    final details = [
      ?street,
      if (stop.hasScheduledTime) '${_formatTime(stop.scheduledAt)} hs',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: tokens.border),
        ),
        child: ConstrainedBox(
          // Compact on purpose: the driver sees more of the stack while
          // dragging; the handle keeps a 48dp touch target.
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              const SizedBox(width: 12),
              _PositionBadge(position: index + 1),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      stop.customer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: tokens.ink,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: tokens.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ReorderableDragStartListener(
                key: handleKey(stop.id),
                index: index,
                child: Semantics(
                  label: 'Mover ${stop.customer.name}',
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      size: 28,
                      color: tokens.inkSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  String? _primaryStreet() {
    final addresses = stop.customer.addresses;
    if (addresses.isEmpty) return null;
    final address =
        addresses.where((a) => a.isPrimary).firstOrNull ?? addresses.first;
    final street = address.street?.trim();
    return (street == null || street.isEmpty) ? null : street;
  }

  static String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position});

  final int position;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: MarilinColors.brandBlue.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        '$position',
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: MarilinColors.brandBlue,
        ),
      ),
    );
  }
}
