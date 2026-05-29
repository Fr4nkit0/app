import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/screens/visit_screen.dart';
import 'package:app/features/route/presentation/widgets/route_stop_card.dart';

class RouteDayScreen extends ConsumerWidget {
  const RouteDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsAsync = ref.watch(routeDayProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: stopsAsync.when(
          data: (stops) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _RouteHeader(stops: stops),
              ),
              SliverToBoxAdapter(
                child: _ProgressSection(stops: stops),
              ),
              if (stops.isEmpty)
                const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.route_outlined,
                    title: 'Sin paradas',
                    message: 'No hay visitas programadas para hoy.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => RouteStopCard(
                        stop: stops[i],
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
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) =>
              const Center(child: Text('Error al cargar la ruta')),
        ),
      ),
    );
  }
}

// ─── Header con saludo + fecha ────────────────────────────────────────────────

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.stops});

  final List<RouteStop> stops;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      '', 'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    const days = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${days[now.weekday]}, ${now.day} de ${months[now.month]}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ruta del Día',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stops.length} parada${stops.length != 1 ? 's' : ''} programadas',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Barra de progreso ────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.stops});

  final List<RouteStop> stops;

  @override
  Widget build(BuildContext context) {
    final done =
        stops.where((s) => s.status != StopStatus.pending).length;
    final total = stops.length;
    final progress = total == 0 ? 0.0 : done / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '$done / $total',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1565C0)),
            ),
          ),
        ],
      ),
    );
  }
}
