import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';

/// Sync control: shows how the last cycle ended and what is still queued,
/// and forces a cycle when tapped.
class SyncStatusButton extends StatelessWidget {
  const SyncStatusButton({
    super.key,
    required this.status,
    required this.isRunning,
    required this.onPressed,
  });

  final SyncStatus status;
  final bool isRunning;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final failed = status.lastResult == SyncCycleResult.failure;
    final color = failed ? MarilinColors.destructive : MarilinColors.brandBlue;

    return Material(
      color: color.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: isRunning ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRunning)
                SizedBox.square(
                  dimension: 13,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  failed ? Icons.sync_problem : Icons.sync,
                  size: 13,
                  color: color,
                ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _headline(),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _count(status.pendingCount, 'pendiente', 'pendientes'),
                        style: const TextStyle(
                          color: MarilinColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _count(status.rejectedCount, 'rechazado', 'rechazados'),
                        style: TextStyle(
                          color: status.rejectedCount > 0
                              ? MarilinColors.destructive
                              : MarilinColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headline() {
    if (isRunning) return 'Sincronizando…';
    final at = status.lastCycleAt;
    if (at == null || status.lastResult == null) return 'Sin sincronizar';
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
    return status.lastResult == SyncCycleResult.success
        ? 'Sincronizado $time'
        : 'Falló $time';
  }

  static String _count(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';
}
