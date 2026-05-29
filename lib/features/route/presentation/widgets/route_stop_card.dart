import 'package:flutter/material.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/domain/models/visit_type.dart';

class RouteStopCard extends StatelessWidget {
  const RouteStopCard({super.key, required this.stop, required this.onTap});

  final RouteStop stop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDone = stop.status == StopStatus.done;
    final isAbsent = stop.status == StopStatus.absent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDone
                    ? Colors.green.shade200
                    : isAbsent
                        ? Colors.red.shade100
                        : Colors.grey.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _TimeBlock(
                    time: stop.scheduledAt,
                    done: isDone,
                    absent: isAbsent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stop.customer.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDone || isAbsent
                                    ? Colors.grey.shade400
                                    : const Color(0xFF0D1B3E),
                              ),
                        ),
                        if (stop.customer.addresses.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            stop.customer.addresses.first.street ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade400),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _TypeChip(type: stop.visitType),
                            const SizedBox(width: 6),
                            _StatusBadge(status: stop.status),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isDone && !isAbsent)
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.grey, size: 20),
                  if (isDone)
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.green, size: 20),
                  if (isAbsent)
                    Icon(Icons.cancel_outlined,
                        color: Colors.red.shade300, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeBlock extends StatelessWidget {
  const _TimeBlock(
      {required this.time, required this.done, required this.absent});

  final DateTime time;
  final bool done;
  final bool absent;

  @override
  Widget build(BuildContext context) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final color = done
        ? Colors.green.shade700
        : absent
            ? Colors.red.shade300
            : const Color(0xFF1565C0);
    final bg = done
        ? Colors.green.shade50
        : absent
            ? Colors.red.shade50
            : const Color(0xFF1565C0).withValues(alpha: 0.07);

    return Container(
      width: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(h,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(m,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final VisitType type;

  @override
  Widget build(BuildContext context) {
    final isSale = type == VisitType.sale;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSale
            ? const Color(0xFF1565C0).withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isSale ? 'Venta' : 'Visita',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isSale ? const Color(0xFF1565C0) : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StopStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case StopStatus.pending:
        color = Colors.orange;
        label = 'Pendiente';
      case StopStatus.done:
        color = Colors.green;
        label = 'Listo';
      case StopStatus.absent:
        color = Colors.red;
        label = 'Ausente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
