import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/domain/models/route_stop.dart';

/// Names the owner driver of a stop the driver is covering. Shows nothing for
/// an own stop or a covered stop without an owner name.
class StopCoverLabel extends StatelessWidget {
  const StopCoverLabel({super.key, required this.stop, this.fontSize = 12});

  final RouteStop stop;
  final double fontSize;

  /// Null when the stop has no cover to show.
  static String? textFor(RouteStop stop) {
    if (!stop.isCover) return null;
    final owner = stop.coveredDriverName?.trim() ?? '';
    return owner.isEmpty ? null : 'Cubriendo a $owner';
  }

  @override
  Widget build(BuildContext context) {
    final text = textFor(stop);
    if (text == null) return const SizedBox.shrink();
    // Orange accent: apart from the blue requested/reschedule marks and from
    // an own stop, which carries no mark.
    final color = context.marilin.vivid(MarilinColors.accent);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.handshake_rounded, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
