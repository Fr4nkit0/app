import 'package:flutter/material.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/widgets/stop_requested_label.dart';
import 'package:app/features/route/presentation/widgets/stop_reschedule_label.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/widgets/sync_badge_container.dart';
import 'package:app/features/visits/presentation/visit_outcome_display.dart';

class RouteStopCard extends StatelessWidget {
  const RouteStopCard({
    super.key,
    required this.stop,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
    this.isNext = false,
  });

  final RouteStop stop;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  /// Marks the stop shown in the next-stop hero with a small pill.
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final isDone = stop.status == StopStatus.done;
    final isRescheduled = stop.status == StopStatus.rescheduled;
    // A rescheduled stop is closed without a delivery, like an absent one.
    final isAbsent = stop.status == StopStatus.absent || isRescheduled;
    final visit = stop.visit;
    final visitLine = visit == null || stop.status == StopStatus.pending
        ? null
        : visitSummaryLine(visit);
    final hasMetaRow =
        stop.hasScheduledTime ||
        isNext ||
        isDone ||
        isAbsent ||
        stop.customer.debtAmount > 0;

    // Timeline color coding
    final Color timelineColor = isDone
        ? context.marilin.vivid(MarilinColors.success) // Green
        : isAbsent
        ? context.marilin.vivid(MarilinColors.destructive) // Red
        : context.marilin.lineStrong; // Gray

    return Stack(
      children: [
        // Gapless timeline connector line
        Positioned(
          left: 32,
          top: isFirst ? 28 : 0,
          bottom: isLast ? 28 : 0,
          child: Container(
            width: 2.5,
            color: timelineColor.withValues(alpha: 0.4),
          ),
        ),
        // Stop row content
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Timeline Status Indicator
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.marilin.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isDone
                          ? context.marilin.vivid(MarilinColors.success)
                          : isAbsent
                          ? context.marilin.vivid(MarilinColors.destructive)
                          : MarilinColors.brandBlue,
                      width: 2.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: MarilinColors.success,
                        )
                      : isRescheduled
                      ? const Icon(
                          Icons.event_repeat_rounded,
                          size: 16,
                          color: MarilinColors.destructive,
                        )
                      : isAbsent
                      ? const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: MarilinColors.destructive,
                        )
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: MarilinColors.brandBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // 2. The Stop Card itself
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.marilin.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isDone
                          ? context.marilin.soft(
                              MarilinColors.success.withValues(alpha: 0.12),
                            )
                          : isAbsent
                          ? context.marilin.soft(
                              MarilinColors.destructive.withValues(alpha: 0.12),
                            )
                          : context.marilin.fill,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.customer.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDone || isAbsent
                                      ? context.marilin.inkHint
                                      : context.marilin.ink,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _addressLabel(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.marilin.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              StopRequestedLabel(stop: stop),
                              StopRescheduleLabel(stop: stop),
                              if (visitLine != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  visitLine,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: context.marilin.inkSecondary,
                                  ),
                                ),
                              ],
                              if (hasMetaRow) ...[
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (stop.hasScheduledTime)
                                      _buildTimeBubble(
                                        context,
                                        stop.scheduledAt,
                                        isDone: isDone,
                                        isAbsent: isAbsent,
                                      ),
                                    if (isNext) _buildNextPill(),
                                    if (isDone || isAbsent)
                                      SyncBadgeContainer(
                                        entity: PendingEntity.routeStop,
                                        entityId: stop.id,
                                      ),
                                    if (stop.customer.debtAmount > 0)
                                      Text(
                                        'Debe ${formatMoney(stop.customer.debtAmount)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: context.marilin.vivid(
                                            MarilinColors.destructive,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _addressLabel() {
    if (stop.customer.addresses.isEmpty) return 'Sin dirección';
    final address = stop.customer.addresses.first;
    return AddressFormatter.format(
      street: address.street,
      neighborhood: address.neighborhood,
      floor: address.floor,
      apartment: address.apartment,
      visualReference: address.visualReference,
    );
  }

  Widget _buildNextPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MarilinColors.brandBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Próxima',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: MarilinColors.brandBlue,
        ),
      ),
    );
  }

  Widget _buildTimeBubble(
    BuildContext context,
    DateTime time, {
    required bool isDone,
    required bool isAbsent,
  }) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');

    final color = isDone
        ? context.marilin.inkHint
        : isAbsent
        ? context.marilin.vivid(MarilinColors.destructive)
        : MarilinColors.brandBlue;
    final bg = isDone
        ? context.marilin.fill
        : isAbsent
        ? MarilinColors.destructive.withValues(alpha: 0.12)
        : MarilinColors.brandBlue.withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$h:$m',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
