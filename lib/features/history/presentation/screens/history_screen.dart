import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/core_search_bar.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/presentation/providers/paginated_history_provider.dart';
import 'package:app/features/history/presentation/widgets/history_date_utils.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:app/features/history/presentation/widgets/history_sync_status_card.dart';
import 'package:app/features/history/presentation/widgets/history_today_summary_row.dart';
import 'package:app/features/history/presentation/widgets/history_type_filter_bar.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';

sealed class _HistoryListItem {}

class _HistorySectionHeaderItem extends _HistoryListItem {
  _HistorySectionHeaderItem(this.label);

  final String label;
}

class _HistoryEntryItem extends _HistoryListItem {
  _HistoryEntryItem(this.entry);

  final HistoryEntry entry;
}

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(paginatedHistoryProvider.notifier).loadMore();
    }
  }

  List<_HistoryListItem> _buildListItems(List<HistoryEntry> entries) {
    if (entries.isEmpty) return [];

    final items = <_HistoryListItem>[];
    int? lastDayKey;

    for (final entry in entries) {
      final key = historyDayKey(entry.date);
      if (lastDayKey != key) {
        items.add(_HistorySectionHeaderItem(historySectionLabelForDate(entry.date)));
        lastDayKey = key;
      }
      items.add(_HistoryEntryItem(entry));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(paginatedHistoryProvider);
    final syncStatus = ref.watch(syncStatusProvider).value ?? const SyncStatus();
    final isSyncRunning = ref.watch(syncRunningProvider).value ?? false;
    final tokens = MarilinTokens.of(context);
    final listItems = _buildListItems(paginatedState.entries);
    final hasActiveFilters = paginatedState.searchQuery.trim().isNotEmpty ||
        paginatedState.typeFilter != null;

    return Scaffold(
      backgroundColor: tokens.scaffoldMuted,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ScreenHeader(
              title: 'Historial',
              subtitle: 'Ventas, visitas y cobros de tu jornada',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: HistorySyncStatusCard(
                status: syncStatus,
                isRunning: isSyncRunning,
                onSync: () => ref.read(syncEngineProvider).runCycle(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HistoryTodaySummaryRow(
                summary: paginatedState.todaySummary,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: HistoryTypeFilterBar(
                selected: paginatedState.typeFilter,
                onSelected: (type) {
                  ref.read(paginatedHistoryProvider.notifier).setTypeFilter(type);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CoreSearchBar(
                controller: _searchController,
                onChanged: (query) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 350),
                    () {
                      ref
                          .read(paginatedHistoryProvider.notifier)
                          .setSearchQuery(query);
                    },
                  );
                },
                hintText: 'Buscar por cliente o detalle…',
              ),
            ),
            Expanded(
              child: paginatedState.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(tokens.brandBlue),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.read(paginatedHistoryProvider.notifier).refresh();
                        if (!isSyncRunning) {
                          await ref.read(syncEngineProvider).runCycle();
                        }
                      },
                      color: tokens.brandBlue,
                      child: paginatedState.entries.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: EmptyState(
                                    icon: hasActiveFilters
                                        ? Icons.search_off_rounded
                                        : Icons.history_outlined,
                                    title: hasActiveFilters
                                        ? 'Sin resultados'
                                        : 'Sin historial',
                                    message: hasActiveFilters
                                        ? 'Probá otro nombre o cambiá el filtro.'
                                        : 'Las ventas y visitas van a aparecer acá.',
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: listItems.length + 1,
                              itemBuilder: (context, index) {
                                if (index == listItems.length) {
                                  return _HistoryListFooter(
                                    state: paginatedState,
                                  );
                                }

                                final item = listItems[index];
                                return switch (item) {
                                  _HistorySectionHeaderItem(:final label) =>
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 16,
                                        bottom: 10,
                                      ),
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                          color: tokens.textMuted,
                                        ),
                                      ),
                                    ),
                                  _HistoryEntryItem(:final entry) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: HistoryEntryTile(entry: entry),
                                    ),
                                };
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryListFooter extends StatelessWidget {
  const _HistoryListFooter({required this.state});

  final PaginatedHistoryState state;

  @override
  Widget build(BuildContext context) {
    final tokens = MarilinTokens.of(context);

    if (state.isLoadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(tokens.brandBlue),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cargando más…',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: tokens.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    if (state.hasReachedMax && state.entries.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Llegaste al final del historial',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tokens.textMuted,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 8);
  }
}
