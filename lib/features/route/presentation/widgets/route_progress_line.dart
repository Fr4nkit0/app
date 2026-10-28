import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

/// One-line summary of the day's progress with a thin bar below it.
class RouteProgressLine extends StatelessWidget {
  const RouteProgressLine({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final pending = total - done;
    final progress = total == 0 ? 0.0 : done / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$done de $total paradas · $pending pendientes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.marilin.ink,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: context.marilin.border,
            valueColor: const AlwaysStoppedAnimation(MarilinColors.brandBlue),
          ),
        ),
      ],
    );
  }
}
