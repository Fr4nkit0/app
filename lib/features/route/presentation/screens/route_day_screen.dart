import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/visits/presentation/screens/visit_screen.dart';
import 'package:app/features/route/presentation/widgets/next_stop_card.dart';
import 'package:app/features/route/presentation/widgets/route_downloading_state.dart';
import 'package:app/features/route/domain/models/route_stop_filter.dart';
import 'package:app/features/route/presentation/widgets/neighborhood_picker_sheet.dart';
import 'package:app/features/route/presentation/widgets/route_filter_bar.dart';
import 'package:app/features/route/presentation/widgets/route_progress_line.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/profile/profile_screen.dart';
import 'package:app/features/profile/widgets/profile_avatar.dart';
import 'package:app/features/sync/domain/models/sync_status.dart';
import 'package:app/features/sync/presentation/providers/sync_providers.dart';
import 'package:app/features/sync/presentation/widgets/sync_status_button_container.dart';

class RouteDayScreen extends ConsumerStatefulWidget {
  const RouteDayScreen({super.key});

  static const searchFieldKey = Key('route-search-field');

  @override
  ConsumerState<RouteDayScreen> createState() => _RouteDayScreenState();
}

class _RouteDayScreenState extends ConsumerState<RouteDayScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchController = TextEditingController(
      text: ref.read(routeStopFilterProvider).query,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _searchController.clear();
    ref.read(routeStopFilterProvider.notifier).setQuery('');
  }

  void _clearFilter() {
    _searchController.clear();
    ref.read(routeStopFilterProvider.notifier).clear();
  }

  Future<void> _pickNeighborhood(List<RouteStop> allStops) async {
    final notifier = ref.read(routeStopFilterProvider.notifier);
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: NeighborhoodPickerSheet(
          neighborhoods: RouteNeighborhood.of(allStops),
          selected: ref.read(routeStopFilterProvider).neighborhood,
          onSelected: (neighborhood) {
            notifier.setNeighborhood(neighborhood);
            Navigator.of(sheetContext).pop();
          },
        ),
      ),
    );
  }

  static Map<StopStatus?, int> _statusCounts(List<RouteStop> stops) {
    final counts = <StopStatus?, int>{null: stops.length};
    for (final stop in stops) {
      counts[stop.status] = (counts[stop.status] ?? 0) + 1;
    }
    return counts;
  }

  void _onScroll() => _loadMoreIfAtEnd();

  /// Asks for the next page when the end of the list is on screen.
  ///
  /// Runs on scroll and after a frame that left stops unloaded: a sync can
  /// add stops while the end of the list is already on screen, and no scroll
  /// would come to load them.
  void _loadMoreIfAtEnd() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 200) return;

    final currentLimit = ref.read(routePaginationLimitProvider);
    final totalStopsCount = ref.read(routeAllStopsProvider).value?.length ?? 0;
    // The page asked for last has not arrived yet: one more scroll event
    // must not ask again.
    final loadedCount = ref.read(routeDayProvider).value?.length ?? 0;
    if (loadedCount < currentLimit) return;

    if (currentLimit < totalStopsCount) {
      ref.read(routePaginationLimitProvider.notifier).increment(10);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(routeDayProvider);
    final allStopsAsync = ref.watch(routeAllStopsProvider);
    final nextStop = ref.watch(nextStopProvider);
    final filter = ref.watch(routeStopFilterProvider);
    final filtering = filter.isActive;
    final isSyncRunning = ref.watch(syncRunningProvider).value ?? false;
    // Without a cycle that reached the server, an empty day means today's
    // route was never downloaded, not that the server has none.
    final syncStatus = ref.watch(syncStatusProvider).value;
    final lastSyncResult = syncStatus?.lastResult;
    final heldStopIds = syncStatus?.heldStopIds ?? const <String>{};
    final routeNotDownloaded =
        lastSyncResult == null || lastSyncResult == SyncCycleResult.offline;
    // A running sync is downloading it right now (e.g. the first sync).
    final routeDownloading = routeNotDownloaded && isSyncRunning;
    // The server answered and sent no route: the admin has not dispatched
    // today's route yet.
    final routeNotDispatched = lastSyncResult == SyncCycleResult.success;

    return Scaffold(
      body: SafeArea(
        child: stopsAsync.when(
          // Loading the next page keeps the list (and its scroll) on screen.
          skipLoadingOnReload: true,
          data: (stops) {
            final allStops = allStopsAsync.value ?? [];
            final totalCount = allStops.length;
            // A filter searches the whole day, not only the loaded pages.
            final visible = filtering ? filter.apply(allStops) : stops;
            final isFullyLoaded = filtering || stops.length >= totalCount;
            if (!isFullyLoaded) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _loadMoreIfAtEnd(),
              );
            }

            return RefreshIndicator(
              // Pull-to-refresh asks the server again, e.g. for a route that
              // was not dispatched yet.
              onRefresh: () async {
                if (!isSyncRunning) {
                  await ref.read(syncEngineProvider).runCycle();
                }
              },
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                // Scrollable even when the content fits, so the pull works.
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _RouteHeader(stops: allStops)),
                  if (allStops.isNotEmpty)
                    // Pinned: the filters stay at hand while scrolling.
                    PinnedHeaderSliver(
                      child: ColoredBox(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          child: RouteFilterBar(
                            searchFieldKey: RouteDayScreen.searchFieldKey,
                            controller: _searchController,
                            neighborhood: filter.neighborhood,
                            status: filter.status,
                            statusCounts: _statusCounts(allStops),
                            shownCount: visible.length,
                            totalCount: totalCount,
                            onQueryChanged: ref
                                .read(routeStopFilterProvider.notifier)
                                .setQuery,
                            onClearQuery: _clearQuery,
                            onPickNeighborhood: () =>
                                _pickNeighborhood(allStops),
                            onClearNeighborhood: () => ref
                                .read(routeStopFilterProvider.notifier)
                                .setNeighborhood(null),
                            onStatusChanged: ref
                                .read(routeStopFilterProvider.notifier)
                                .setStatus,
                            onClearAll: _clearFilter,
                          ),
                        ),
                      ),
                    ),
                  // A filtered list stands alone: the next stop and the
                  // progress describe the whole day.
                  if (allStops.isNotEmpty && !filtering)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: nextStop != null
                            ? _NextStopHero(stop: nextStop)
                            : RouteDoneCard(closedCount: allStops.length),
                      ),
                    ),
                  if (!filtering)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: RouteProgressLine(
                          done: allStops
                              .where((s) => s.status != StopStatus.pending)
                              .length,
                          total: allStops.length,
                        ),
                      ),
                    ),
                  if (allStops.isEmpty)
                    SliverFillRemaining(
                      // Taller than what is left on a small phone: scroll instead of overflowing.
                      hasScrollBody: false,
                      child: routeDownloading
                          ? const RouteDownloadingState()
                          : EmptyState(
                              icon: routeNotDownloaded
                                  ? Icons.cloud_off_outlined
                                  : Icons.route_outlined,
                              title: routeNotDownloaded
                                  ? 'Falta la ruta de hoy'
                                  : routeNotDispatched
                                  ? 'Tu ruta todavía no fue despachada'
                                  : 'Sin paradas por ahora',
                              message: routeNotDownloaded
                                  ? 'Conectate a internet para descargar la ruta de hoy.'
                                  : routeNotDispatched
                                  ? 'Se va a cargar cuando administración la despache.'
                                  : 'Cuando la ruta del día esté cargada, va a aparecer acá.',
                              actionLabel: isSyncRunning
                                  ? 'Sincronizando…'
                                  : 'Sincronizar ahora',
                              onAction: isSyncRunning
                                  ? null
                                  : () =>
                                        ref.read(syncEngineProvider).runCycle(),
                            ),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.search_off_outlined,
                        title: 'Ninguna parada coincide',
                        message:
                            'Probá con otro nombre, otro barrio u otro estado.',
                        actionLabel: 'Limpiar filtros',
                        onAction: _clearFilter,
                      ),
                    )
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) => RouteStopCard(
                            stop: visible[i],
                            isFirst: i == 0,
                            isLast: i == visible.length - 1 && isFullyLoaded,
                            isNext: visible[i].id == nextStop?.id,
                            holdsRecords: heldStopIds.contains(visible[i].id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    VisitScreen(stopId: visible[i].id),
                              ),
                            ),
                          ),
                          childCount: visible.length,
                        ),
                      ),
                    ),
                    if (!isFullyLoaded)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      MarilinColors.brandBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Cargando más paradas...',
                                  style: TextStyle(
                                    color: context.marilin.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            title: 'No pudimos cargar la ruta',
            message:
                'Revisá la conexión y reintentá. '
                'Lo que ya cargaste sigue guardado en el teléfono.',
            onRetry: () {
              ref.invalidate(routeDayProvider);
              ref.invalidate(routeAllStopsProvider);
            },
          ),
        ),
      ),
    );
  }
}

// ─── Header con saludo + fecha ────────────────────────────────────────────────

class _RouteHeader extends ConsumerWidget {
  const _RouteHeader({required this.stops});

  final List<RouteStop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final displayName = auth.displayName;
    final firstName = displayName?.trim().split(RegExp(r'\s+')).first;
    final greeting = (firstName != null && firstName.isNotEmpty)
        ? '¡Hola, $firstName!'
        : '¡Hola!';

    final now = DateTime.now();
    const months = [
      '',
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    const days = [
      '',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. The sync control owns the top row, so its texts never shrink.
          const Align(
            alignment: Alignment.centerRight,
            child: SyncStatusButtonContainer(),
          ),
          const SizedBox(height: 10),
          // 2. Identity row: avatar and greeting; tapping it opens the profile.
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              ),
              child: Semantics(
                button: true,
                label: 'Mi perfil',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfileAvatar(name: displayName ?? 'Repartidor'),
                      const SizedBox(width: 16),
                      // User text details (Greeting + Subtitle)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              greeting,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: context.marilin.ink,
                                    fontSize: 26,
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_outlined,
                                  size: 15,
                                  color: context.marilin.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    '${days[now.weekday]}, ${now.day} de ${months[now.month]}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.marilin.inkSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: context.marilin.fill,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.marilin.border),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: context.marilin.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next stop hero ───────────────────────────────────────────────────────────

class _NextStopHero extends ConsumerWidget {
  const _NextStopHero({required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Loading or error: the custody item is simply absent.
    final custody =
        ref
            .watch(customerContainerBalancesProvider(stop.customer.id))
            .value
            ?.fold<int>(0, (sum, b) => sum + b.quantity) ??
        0;

    return NextStopCard(
      stop: stop,
      custodyCount: custody,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => VisitScreen(stopId: stop.id))),
    );
  }
}
