import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/domain/models/visit_type.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step2_screen.dart';

class VisitScreen extends ConsumerWidget {
  const VisitScreen({super.key, required this.stopId});

  final String stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stop = ref.watch(routeStopByIdProvider(stopId));

    if (stop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visita')),
        body: const Center(child: Text('Parada no encontrada')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _VisitAppBar(stop: stop),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: status + hora
                    _StatusSection(stop: stop),
                    const SizedBox(height: 20),
                    // Sección: info del cliente
                    _CustomerSection(stop: stop),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Footer de acciones
      bottomNavigationBar: _ActionFooter(stop: stop, ref: ref),
    );
  }
}

// ─── AppBar con status chip ───────────────────────────────────────────────────

class _VisitAppBar extends StatelessWidget {
  const _VisitAppBar({required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: const Color(0xFF0D1B3E),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.customer.name,
                  style: const TextStyle(
                    color: Color(0xFF0D1B3E),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                _StatusChipInline(status: stop.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChipInline extends StatelessWidget {
  const _StatusChipInline({required this.status});

  final StopStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case StopStatus.pending:
        color = Colors.orange;
        label = 'Pendiente';
      case StopStatus.done:
        color = Colors.green;
        label = 'Visitado';
      case StopStatus.absent:
        color = Colors.red.shade400;
        label = 'Ausente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

// ─── Status + horario ─────────────────────────────────────────────────────────

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final h = stop.scheduledAt.hour.toString().padLeft(2, '0');
    final m = stop.scheduledAt.minute.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(h,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1565C0))),
                Text(m,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0))),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.visitType == VisitType.sale ? 'Visita de venta' : 'Solo visita',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Programado para las $h:$m',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Info del cliente ─────────────────────────────────────────────────────────

class _CustomerSection extends StatelessWidget {
  const _CustomerSection({required this.stop});

  final RouteStop stop;

  @override
  Widget build(BuildContext context) {
    final customer = stop.customer;
    final address = customer.addresses
        .where((a) => a.isPrimary)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CLIENTE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        if (address != null)
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address.street ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        if (customer.phone != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.phone_outlined,
                  size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(customer.phone!,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
        if (customer.debtAmount > 0) ...[
          const SizedBox(height: 10),
          DebtChip(amount: customer.debtAmount),
        ],
        if (customer.productLabels.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                customer.productLabels.map((l) => ProductChip(label: l)).toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Footer de acciones ───────────────────────────────────────────────────────

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({required this.stop, required this.ref});

  final RouteStop stop;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final isDone = stop.status != StopStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: isDone
          ? _DoneState(status: stop.status)
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Registrar venta
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: stop.visitType == VisitType.sale
                        ? () {
                            ref
                                .read(saleDraftProvider.notifier)
                                .selectCustomer(stop.customer);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SaleStep2Screen(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.point_of_sale_outlined),
                    label: const Text('Registrar Venta',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFBF1B1B),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Marcar visitado + Marcar ausente
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(routeRepositoryProvider)
                              .markStop(stop.id, StopStatus.done);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Visitado',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green.shade700,
                          side: BorderSide(color: Colors.green.shade300),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(routeRepositoryProvider)
                              .markStop(stop.id, StopStatus.absent);
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.person_off_outlined, size: 18),
                        label: const Text('Ausente',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          side: BorderSide(color: Colors.red.shade200),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _DoneState extends StatelessWidget {
  const _DoneState({required this.status});

  final StopStatus status;

  @override
  Widget build(BuildContext context) {
    final isDone = status == StopStatus.done;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.person_off_rounded,
            color: isDone ? Colors.green.shade700 : Colors.red.shade400,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            isDone ? 'Parada completada' : 'Marcado como ausente',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDone ? Colors.green.shade700 : Colors.red.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
