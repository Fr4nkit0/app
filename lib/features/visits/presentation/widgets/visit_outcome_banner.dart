import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/visits/presentation/visit_outcome_display.dart';

/// How the visit to a closed stop ended: with a sale, with the outcome of a
/// visit without sale, or rescheduled to a new time.
class VisitOutcomeBanner extends StatelessWidget {
  const VisitOutcomeBanner({super.key, required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final (text, icon, tone) = _describe();
    final color = context.marilin.vivid(tone);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.marilin.soft(tone.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, IconData, Color) _describe() {
    if (stop.status == StopStatus.rescheduled) {
      final to = stop.rescheduledToAt;
      return (
        to == null
            ? 'Visita reprogramada'
            : 'Visita reprogramada para las ${formatClockTime(to)}',
        Icons.calendar_today_outlined,
        MarilinColors.brandBlue,
      );
    }
    final visit = stop.visit;
    if (visit != null && visit.hasSales) {
      return (
        'Visita con venta',
        Icons.check_circle_rounded,
        MarilinColors.success,
      );
    }
    final outcome = visit?.outcome;
    if (outcome != null) {
      return (
        'Sin venta · ${outcome.name}',
        visitOutcomeIcon(outcome),
        MarilinColors.destructive,
      );
    }
    // Closed without a visit recorded on this phone.
    return stop.status == StopStatus.absent
        ? (
            'Cliente ausente en esta visita',
            Icons.person_off_rounded,
            MarilinColors.destructive,
          )
        : ('Visita cerrada', Icons.check_circle_rounded, MarilinColors.success);
  }
}
