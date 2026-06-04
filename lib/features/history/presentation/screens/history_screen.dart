import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/core_search_bar.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/features/history/presentation/providers/history_sync_provider.dart';
import 'package:app/features/history/presentation/providers/paginated_history_provider.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedHistoryProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(paginatedHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: paginatedState.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.read(paginatedHistoryProvider.notifier).refresh();
                  ref.read(historySyncProvider.notifier).startSync();
                },
                color: const Color(0xFF1565C0),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount:
                      5 +
                      paginatedState.entries.length +
                      1, // Explicitly safe int compilation
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Column(
                        children: [
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Historial',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F4C81),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      );
                    }
                    if (index == 1) {
                      return const Column(
                        children: [
                          Divider(color: Color(0xFFE2E8F0), height: 1),
                          SizedBox(height: 16),
                        ],
                      );
                    }
                    if (index == 2) {
                      return const Column(
                        children: [_SyncStatusCard(), SizedBox(height: 24)],
                      );
                    }
                    if (index == 3) {
                      return const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Actividad de Hoy',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0D1B3E),
                            ),
                          ),
                          SizedBox(height: 12),
                        ],
                      );
                    }
                    if (index == 4) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: CoreSearchBar(
                          controller: _searchController,
                          onChanged: (query) {
                            // TODO: Implement search filtering
                          },
                          hintText: 'Buscar en historial...',
                        ),
                      );
                    }

                    final entryIndex = index - 5;
                    if (entryIndex < paginatedState.entries.length) {
                      final entry = paginatedState.entries[entryIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: HistoryEntryTile(entry: entry),
                      );
                    }

                    return _buildFooter(paginatedState);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildFooter(PaginatedHistoryState state) {
    if (state.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Cargando más actividad...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (state.hasReachedMax && state.entries.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Column(
          children: const [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF94A3B8),
              size: 24,
            ),
            SizedBox(height: 8),
            Text(
              'Fin del historial operativo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    if (state.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: EmptyState(
          icon: Icons.history_outlined,
          title: 'Sin historial',
          message: 'Las ventas y visitas van a aparecer acá.',
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}

class _SyncStatusCard extends ConsumerWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(historySyncProvider);

    final isCompleted = syncState.isCompleted;
    final isSyncing = syncState.isSyncing;

    final topBorderColor = isCompleted
        ? const Color(0xFF0F975C)
        : const Color(0xFF0F4C81);
    final iconBgColor = isCompleted
        ? const Color(0xFF0F975C)
        : const Color(0xFF0F975C);
    final iconColor = Colors.white;
    final iconData = isCompleted
        ? Icons.cloud_done_rounded
        : Icons.sync_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(historySyncProvider.notifier).startSync();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 4, color: topBorderColor),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCompleted
                            ? 'Datos Sincronizados'
                            : 'Sincronizando Datos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D1B3E),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _AnimatedSyncIcon(
                            isSyncing: isSyncing,
                            bgColor: iconBgColor,
                            iconColor: iconColor,
                            iconData: iconData,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCompleted
                                      ? 'Todo al día'
                                      : 'Datos pendientes de envío',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0D1B3E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isCompleted
                                      ? 'Todos los registros sincronizados'
                                      : '${syncState.pendingCount} registros locales',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isCompleted ? 'Sincronizado' : 'Sincronizando',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: topBorderColor,
                            ),
                          ),
                          Text(
                            '${(syncState.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: topBorderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: syncState.progress,
                          minHeight: 8,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            topBorderColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSyncIcon extends StatefulWidget {
  final bool isSyncing;
  final Color bgColor;
  final Color iconColor;
  final IconData iconData;

  const _AnimatedSyncIcon({
    required this.isSyncing,
    required this.bgColor,
    required this.iconColor,
    required this.iconData,
  });

  @override
  State<_AnimatedSyncIcon> createState() => _AnimatedSyncIconState();
}

class _AnimatedSyncIconState extends State<_AnimatedSyncIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isSyncing) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedSyncIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: widget.bgColor, shape: BoxShape.circle),
      child: widget.isSyncing
          ? RotationTransition(
              turns: _rotationController,
              child: Icon(widget.iconData, color: widget.iconColor, size: 22),
            )
          : Icon(widget.iconData, color: widget.iconColor, size: 22),
    );
  }
}
