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

  @override
  ConsumerState<RouteDayScreen> createState() => _RouteDayScreenState();
}

class _RouteDayScreenState extends ConsumerState<RouteDayScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final currentLimit = ref.read(routePaginationLimitProvider);
      final allStopsAsync = ref.read(routeAllStopsProvider);
      final totalStopsCount = allStopsAsync.value?.length ?? 0;

      if (currentLimit < totalStopsCount) {
        ref.read(routePaginationLimitProvider.notifier).increment(10);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(routeDayProvider);
    final allStopsAsync = ref.watch(routeAllStopsProvider);
    final nextStop = ref.watch(nextStopProvider);
    final isSyncRunning = ref.watch(syncRunningProvider).value ?? false;
    // Without a cycle that reached the server, an empty day means today's
    // route was never downloaded, not that the server has none.
    final lastSyncResult = ref.watch(syncStatusProvider).value?.lastResult;
    final routeNotDownloaded =
        lastSyncResult == null || lastSyncResult == SyncCycleResult.offline;
    // A running sync is downloading it right now (e.g. the first sync).
    final routeDownloading = routeNotDownloaded && isSyncRunning;

    return Scaffold(
      body: SafeArea(
        child: stopsAsync.when(
          data: (stops) {
            final allStops = allStopsAsync.value ?? [];
            final totalCount = allStops.length;
            final isFullyLoaded = stops.length >= totalCount;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _RouteHeader(stops: allStops)),
                if (allStops.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: nextStop != null
                          ? _NextStopHero(stop: nextStop)
                          : RouteDoneCard(closedCount: allStops.length),
                    ),
                  ),
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
                                : 'Sin paradas por ahora',
                            message: routeNotDownloaded
                                ? 'Conectate a internet para descargar la ruta de hoy.'
                                : 'Cuando la ruta del día esté cargada, va a aparecer acá.',
                            actionLabel: isSyncRunning
                                ? 'Sincronizando…'
                                : 'Sincronizar ahora',
                            onAction: isSyncRunning
                                ? null
                                : () => ref.read(syncEngineProvider).runCycle(),
                          ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => RouteStopCard(
                          stop: stops[i],
                          isFirst: i == 0,
                          isLast: i == stops.length - 1 && isFullyLoaded,
                          isNext: stops[i].id == nextStop?.id,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VisitScreen(stopId: stops[i].id),
                            ),
                          ),
                        ),
                        childCount: stops.length,
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
