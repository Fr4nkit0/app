import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';

/// Shows how the last real sync cycle ended and what is left in the queue.
class HistorySyncStatusCard extends StatelessWidget {
  const HistorySyncStatusCard({
    super.key,
    required this.status,
    required this.isRunning,
    required this.onSync,
  });

  final SyncStatus status;
  final bool isRunning;
  final VoidCallback onSync;

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String _count(int n, String singular, String plural) =>
      '$n ${n == 1 ? singular : plural}';

  String get _title {
    if (isRunning) return 'Sincronizando…';
    final at = status.lastCycleAt;
    if (at == null || status.lastResult == null) {
      return 'Todavía no se sincronizó';
    }
    return switch (status.lastResult!) {
      SyncCycleResult.success => 'Sincronizado a las ${_time(at)}',
      SyncCycleResult.offline =>
        'Sin conexión · ${status.pendingCount} '
            '${status.pendingCount == 1 ? 'guardado' : 'guardados'} '
            'en el teléfono',
      SyncCycleResult.failure => 'Falló a las ${_time(at)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);
    final failed = !isRunning && status.lastResult == SyncCycleResult.failure;
    final upToDate = !isRunning &&
        status.lastResult == SyncCycleResult.success &&
        status.pendingCount == 0 &&
        status.rejectedCount == 0;
    final offline = !isRunning && status.lastResult == SyncCycleResult.offline;
    final accent = failed
        ? tokens.destructive
        : offline
        ? tokens.inkSecondary
        : upToDate
        ? tokens.success
        : tokens.brandBlue;
    final error = status.lastError;

    return Material(
      color: tokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isRunning ? null : onSync,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _SyncIconBadge(
                isSyncing: isRunning,
                icon: failed || offline
                    ? Icons.cloud_off_rounded
                    : upToDate
                    ? Icons.cloud_done_rounded
                    : Icons.sync_rounded,
                color: accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tokens.brandNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_count(status.pendingCount, 'pendiente', 'pendientes')}'
                      ' · '
                      '${_count(status.rejectedCount, 'rechazado', 'rechazados')}',
                      style: tokens.subtitle.copyWith(fontSize: 12),
                    ),
                    if (failed && error != null && error.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        error,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: tokens.destructive,
                        ),
                      ),
                    ],
                    if (isRunning) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: tokens.border,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isRunning)
                Icon(Icons.refresh_rounded, color: tokens.brandBlue, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncIconBadge extends StatefulWidget {
  const _SyncIconBadge({
    required this.isSyncing,
    required this.icon,
    required this.color,
  });

  final bool isSyncing;
  final IconData icon;
  final Color color;

  @override
  State<_SyncIconBadge> createState() => _SyncIconBadgeState();
}

class _SyncIconBadgeState extends State<_SyncIconBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isSyncing) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SyncIconBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Icon(widget.icon, color: widget.color, size: 22);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: widget.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: widget.isSyncing
          ? RotationTransition(turns: _controller, child: child)
          : child,
    );
  }
}
