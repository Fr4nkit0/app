import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';

/// Shows a stop's reschedule link: the original reads "Reprogramada" and
/// the new stop names the time it was rescheduled from.
class StopRescheduleLabel extends StatelessWidget {
  const StopRescheduleLabel({super.key, required this.stop});

  final RouteStop stop;

  /// Null when the stop has no reschedule to show.
  static String? textFor(RouteStop stop) {
    if (stop.status == StopStatus.rescheduled) return 'Reprogramada';
    if (stop.rescheduledFromStopId == null) return null;
    final from = stop.rescheduledFromAt;
    if (from == null) return 'Reprogramada';
    final h = from.hour.toString().padLeft(2, '0');
    final m = from.minute.toString().padLeft(2, '0');
    return 'Reprogramada desde las $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final text = textFor(stop);
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_repeat_rounded,
            size: 14,
            color: MarilinColors.brandBlue,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: MarilinColors.brandBlue,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
