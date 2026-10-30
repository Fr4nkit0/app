import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/domain/models/route_stop.dart';

/// Marks a stop that carries a visit the admin scheduled, with its note.
/// Shows nothing for any other stop.
class StopRequestedLabel extends StatelessWidget {
  const StopRequestedLabel({super.key, required this.stop, this.fontSize = 12});

  final RouteStop stop;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (!stop.isRequested) return const SizedBox.shrink();
    final note = stop.note?.trim() ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_available_rounded,
                size: fontSize + 2,
                color: MarilinColors.brandBlue,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'Visita solicitada',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: MarilinColors.brandBlue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize + 1,
                color: context.marilin.inkSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
