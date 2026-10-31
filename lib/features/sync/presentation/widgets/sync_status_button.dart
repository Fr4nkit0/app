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
    final offline = !isRunning && status.lastResult == SyncCycleResult.offline;
    final color = failed
        ? MarilinColors.destructive
        : offline
        ? context.marilin.inkSecondary
        : MarilinColors.brandBlue;

    return Material(
      color: color.withValues(alpha: 0.06),
      shape: StadiumBorder(
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: isRunning ? null : onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRunning)
                SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  failed
                      ? Icons.sync_problem
                      : offline
                      ? Icons.cloud_off
                      : Icons.sync,
                  size: 18,
                  color: color,
                ),
              const SizedBox(width: 8),
              // On narrow headers the texts shrink with an ellipsis instead of overflowing.
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _headline(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            offline
                                ? _saved(status.pendingCount)
                                : _count(
                                    status.readyCount,
                                    'pendiente',
                                    'pendientes',
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.marilin.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (status.heldLabel case final held?) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              held,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.marilin.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _count(
                              status.rejectedCount,
                              'rechazado',
                              'rechazados',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: status.rejectedCount > 0
                                  ? MarilinColors.destructive
                                  : context.marilin.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    return switch (status.lastResult!) {
      SyncCycleResult.success => 'Sincronizado $time',
      SyncCycleResult.offline => 'Sin conexión',
      SyncCycleResult.failure => 'Falló $time',
    };
  }

  /// Changes kept on the phone while there is no connection.
  static String _saved(int n) =>
      '$n ${n == 1 ? 'guardado' : 'guardados'} en el teléfono';

  static String _count(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';
}
