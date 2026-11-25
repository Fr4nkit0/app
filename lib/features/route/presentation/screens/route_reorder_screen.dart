import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/widgets/reorder_stop_tile.dart';

/// Lets the driver put today's pending stops in the order of their stack of
/// delivery cards. Works offline: the repository saves the order locally and
/// queues it for the next sync.
class RouteReorderScreen extends ConsumerStatefulWidget {
  const RouteReorderScreen({super.key});

  @override
  ConsumerState<RouteReorderScreen> createState() => _RouteReorderScreenState();
}

class _RouteReorderScreenState extends ConsumerState<RouteReorderScreen> {
  /// Pending stops in the order the driver is building; null until the day's
  /// stops first arrive.
  List<RouteStop>? _pending;

  /// Closed stops, kept in their current order after the pending ones.
  List<RouteStop> _closed = const [];

  List<String> _initialPendingIds = const [];
  bool _saving = false;
  Object? _loadError;

  /// False while [initState] runs: the first value may arrive synchronously,
  /// before the first build, where [setState] is not needed.
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Snapshot the stops once: a later emission (e.g. a sync) must not undo
    // the order the driver is dragging.
    ref.listenManual<AsyncValue<List<RouteStop>>>(routeAllStopsProvider, (
      _,
      next,
    ) {
      if (_pending != null) return;
      next.when(
        data: _takeSnapshot,
        error: (error, _) => _update(() => _loadError = error),
        loading: () {},
      );
    }, fireImmediately: true);
    _initialized = true;
  }

  void _update(VoidCallback change) =>
      _initialized ? setState(change) : change();

  void _takeSnapshot(List<RouteStop> stops) {
    final pending = stops.where((s) => s.status == StopStatus.pending).toList();
    _update(() {
      _pending = pending;
      _closed = stops.where((s) => s.status != StopStatus.pending).toList();
      _initialPendingIds = pending.map((s) => s.id).toList();
      _loadError = null;
    });
  }

  bool get _changed {
    final pending = _pending;
    if (pending == null) return false;
    for (var i = 0; i < pending.length; i++) {
      if (pending[i].id != _initialPendingIds[i]) return true;
    }
    return false;
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final pending = _pending!;
      // ReorderableListView reports the index before removing the item.
      final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
      pending.insert(target, pending.removeAt(oldIndex));
    });
  }

  Future<void> _save() async {
    final pending = _pending;
    if (pending == null || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(reorderDayStopsUseCaseProvider).execute([
        ...pending.map((s) => s.id),
        ..._closed.map((s) => s.id),
      ]);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No pudimos guardar el orden. Probá de nuevo.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Orden guardado. Se sube en la próxima sincronización.'),
      ),
    );
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar el nuevo orden?'),
        content: const Text('Las paradas quedan en el orden que tenían.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir ordenando'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: MarilinColors.destructive,
            ),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final changed = _changed;
    final pending = _pending;

    return PopScope(
      canPop: !changed || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Ordenar paradas')),
        body: pending == null
            ? _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No pudimos cargar las paradas de hoy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: context.marilin.textMuted),
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Text(
                      pending.isEmpty
                          ? 'No quedan paradas pendientes para ordenar.'
                          : 'Arrastrá cada parada desde la manija para '
                                'ponerlas en el orden de tu pila. '
                                'La hora es solo informativa.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.marilin.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: pending.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, i) => ReorderStopTile(
                        key: ValueKey(pending[i].id),
                        stop: pending[i],
                        index: i,
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: changed && !_saving ? _save : null,
            child: const Text('Guardar'),
          ),
        ),
      ),
    );
  }
}
