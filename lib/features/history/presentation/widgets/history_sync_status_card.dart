import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/history/presentation/providers/history_sync_provider.dart';
class HistorySyncStatusCard extends ConsumerWidget {
  const HistorySyncStatusCard({super.key, required this.pendingFromEntries});

  final int pendingFromEntries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(historySyncProvider);
    final tokens = MarilinTokens.of(context);

    final isCompleted = syncState.isCompleted && pendingFromEntries == 0;
    final isSyncing = syncState.isSyncing;
    final pending = pendingFromEntries > 0
        ? pendingFromEntries
        : syncState.pendingCount;
    final accent = isCompleted ? tokens.success : tokens.brandBlue;

    return Material(
      color: tokens.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSyncing
            ? null
            : () => ref.read(historySyncProvider.notifier).startSync(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _SyncIconBadge(
                isSyncing: isSyncing,
                isCompleted: isCompleted,
                tokens: tokens,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted
                          ? 'Registros al día en el dispositivo'
                          : isSyncing
                              ? 'Actualizando cola local…'
                              : 'Pendientes de subir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: tokens.brandNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'La sincronización con el servidor depende de la red'
                          : '$pending registro${pending == 1 ? '' : 's'} en cola',
                      style: tokens.subtitle.copyWith(fontSize: 12),
                    ),
                    if (isSyncing) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: syncState.progress,
                          minHeight: 6,
                          backgroundColor: tokens.border,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isSyncing && !isCompleted)
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
    required this.isCompleted,
    required this.tokens,
  });

  final bool isSyncing;
  final bool isCompleted;
  final MarilinTokens tokens;

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
    final bg = widget.isCompleted
        ? widget.tokens.success.withValues(alpha: 0.15)
        : widget.tokens.brandBlue.withValues(alpha: 0.12);
    final fg = widget.isCompleted
        ? widget.tokens.success
        : widget.tokens.brandBlue;
    final icon = widget.isCompleted
        ? Icons.cloud_done_rounded
        : Icons.sync_rounded;

    final child = Icon(icon, color: fg, size: 22);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: widget.isSyncing
          ? RotationTransition(turns: _controller, child: child)
          : child,
    );
  }
}
