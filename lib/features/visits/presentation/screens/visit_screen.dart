import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/presentation/providers/complete_visit_usecase_provider.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/widgets/debt_payment_dialog.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/core/utils/resource.dart';

final stopSalesProvider = StreamProvider.family<List<Sale>, String>((
  ref,
  stopId,
) {
  final repo = ref.watch(saleRepositoryProvider);
  return repo.watchAllSales().map(
    (sales) => sales.where((s) => s.visitId == stopId).toList(),
  );
});

final visitPaymentsProvider = StreamProvider.family<List<Payment>, String>((
  ref,
  stopId,
) {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.watchVisitPayments(stopId);
});

class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({super.key, required this.stopId});

  final String stopId;

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> {
  bool _isSaleSelected = false;
  String? _soloVisitResult; // null initially so they have to select one!
  int _rescheduleDayOffset = 1; // 1 = Mañana, 2 = Siguiente día hábil
  String _rescheduleTimeSlot = 'Mañana (09:00 - 12:00)';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stop = ref.watch(routeStopByIdProvider(widget.stopId));

    if (stop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visita')),
        body: const Center(child: Text('Parada no encontrada')),
      );
    }

    final isDone = stop.status != StopStatus.pending;
    final salesAsync = ref.watch(stopSalesProvider(widget.stopId));
    final visitMovementsAsync = ref.watch(
      visitMovementsProvider(widget.stopId),
    );
    final visitPaymentsAsync = ref.watch(visitPaymentsProvider(widget.stopId));

    return salesAsync.when(
      data: (sales) {
        final hasSales = sales.isNotEmpty;
        final hasReturns = visitMovementsAsync.maybeWhen(
          data: (movements) => movements.any((m) => m.returnedQuantity > 0),
          orElse: () => false,
        );
        final hasPayments = visitPaymentsAsync.maybeWhen(
          data: (payments) => payments.isNotEmpty,
          orElse: () => false,
        );

        if ((hasReturns || hasPayments) && _soloVisitResult == 'absent') {
          _soloVisitResult = null;
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Visita',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDone ? Colors.green : const Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDone ? 'COMPLETADA' : 'EN CURSO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isDone ? Colors.green : const Color(0xFF1565C0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer & Address Details Card
                        _buildCustomerCard(stop),
                        const SizedBox(height: 20),

                        // Custom banners based on state
                        if (stop.customer.debtAmount > 0)
                          _buildDebtBanner(stop.customer.debtAmount, stop),
                        const SizedBox(height: 12),
                        _buildCustodyBanner(stop),
                        const SizedBox(height: 24),

                        if (!isDone) ...[
                          if (hasSales) ...[
                            Text(
                              'REGISTRO',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...sales.map(
                              (sale) => _buildRegisteredSaleCard(sale),
                            ),
                            const SizedBox(height: 16),
                            _buildAddAnotherSaleButton(stop),
                            const SizedBox(height: 20),
                            _buildInfoBanner(),
                          ] else ...[
                            // Interactive Action Mode Selector
                            Text(
                              '¿QUÉ HACEMOS HOY?',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade500,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildModeSelector(stop),
                            const SizedBox(height: 24),

                            // Animated Progressive Disclosure Sub-section
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: !_isSaleSelected
                                  ? _buildSoloVisitSubSection(
                                      hasReturns: hasReturns,
                                      hasPayments: hasPayments,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ] else ...[
                          _buildDoneStateBanner(stop.status),
                        ],
                      ],
                    ),
                  ),
                ),
                // Unified Sticky Footer
                _buildStickyFooter(
                  stop,
                  isDone,
                  hasSales,
                  hasReturns: hasReturns,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Error al cargar la información de la visita'),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(RouteStop stop) {
    final address = stop.customer.addresses.isNotEmpty
        ? stop.customer.addresses.first.street ?? ''
        : 'Sin dirección cargada';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'CLIENTE ACTUAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stop.customer.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0D1B3E),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Beautiful Map Action Button
              /*Material(
                color: const Color(0xFF1565C0).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abriendo mapa para: $address...'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFF1565C0),
                      size: 28,
                    ),
                  ),
                ),
              ),*/
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  address,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          if (stop.customer.phone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366), //.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.whatsapp,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onLongPress: () async {
                      final phone = stop.customer.phone!.replaceAll(
                        RegExp(r'[^\d]'),
                        '',
                      );
                      final uri = Uri.parse('https://wa.me/$phone');
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo abrir WhatsApp'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      stop.customer.phone!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtBanner(double debt, RouteStop stop) {
    final isDone = stop.status != StopStatus.pending;
    return Material(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isDone
            ? null
            : () async {
                final result = await showDialog<DebtPaymentResult>(
                  context: context,
                  builder: (_) => DebtPaymentDialog(totalDebt: debt),
                );
                if (result == null) return;

                final payments = <Payment>[];
                final now = DateTime.now();
                if (result.method == 'Efectivo') {
                  payments.add(
                    Payment(
                      id: const Uuid().v4(),
                      customerId: stop.customer.id,
                      amount: result.cashAmount!,
                      type: PaymentType.cash,
                      createdAt: now,
                      visitId: stop.id,
                    ),
                  );
                } else if (result.method == 'Transferencia') {
                  payments.add(
                    Payment(
                      id: const Uuid().v4(),
                      customerId: stop.customer.id,
                      amount: result.transferAmount!,
                      type: PaymentType.transfer,
                      createdAt: now,
                      visitId: stop.id,
                    ),
                  );
                } else if (result.method == 'Mixto') {
                  if (result.cashAmount != null && result.cashAmount! > 0) {
                    payments.add(
                      Payment(
                        id: const Uuid().v4(),
                        customerId: stop.customer.id,
                        amount: result.cashAmount!,
                        type: PaymentType.cash,
                        createdAt: now,
                        visitId: stop.id,
                      ),
                    );
                  }
                  if (result.transferAmount != null &&
                      result.transferAmount! > 0) {
                    payments.add(
                      Payment(
                        id: const Uuid().v4(),
                        customerId: stop.customer.id,
                        amount: result.transferAmount!,
                        type: PaymentType.transfer,
                        createdAt: now.add(const Duration(milliseconds: 10)),
                        visitId: stop.id,
                      ),
                    );
                  }
                }

                if (payments.isNotEmpty) {
                  final usecase = ref.read(registerPaymentUseCaseProvider);
                  final res = await usecase.execute(payments);
                  if (res is Success) {
                    if (context.mounted) {
                      TopToast.show(
                        context,
                        message: 'Pago registrado con éxito',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF10B981),
                      );
                    }
                  } else if (res is Error) {
                    if (context.mounted) {
                      TopToast.show(
                        context,
                        message: 'Error al registrar pago: ${res.error}',
                        icon: Icons.error_outline,
                        color: const Color(0xFFDC2626),
                      );
                    }
                  }
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFCA5A5).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isDone
                      ? 'Deuda pendiente'
                      : 'Deuda pendiente (Tocar para pagar)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF991B1B),
                  ),
                ),
              ),
              Text(
                '-\$${debt.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                ),
              ),
              if (!isDone) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustodyBanner(RouteStop stop) {
    final balancesAsync = ref.watch(
      customerContainerBalancesProvider(stop.customer.id),
    );

    return balancesAsync.when(
      data: (balances) {
        final bidon = balances
            .firstWhere(
              (b) => b.containerType == 'BIDON_20L',
              orElse: () => CustomerContainerBalance(
                customerId: stop.customer.id,
                containerType: 'BIDON_20L',
                quantity: 0,
              ),
            )
            .quantity;
        final sifon = balances
            .firstWhere(
              (b) => b.containerType == 'SIFON_2L',
              orElse: () => CustomerContainerBalance(
                customerId: stop.customer.id,
                containerType: 'SIFON_2L',
                quantity: 0,
              ),
            )
            .quantity;

        final isDone = stop.status != StopStatus.pending;

        return Material(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: (isDone || (bidon == 0 && sifon == 0))
                ? null
                : () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) =>
                          StandaloneContainerReturnDialog(stop: stop),
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF93C5FD).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF1D4ED8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Envases bajo custodia',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildContainerBadge(
                              icon: Icons.water_drop_outlined,
                              label: 'Bidón 20L',
                              count: bidon,
                            ),
                            const SizedBox(width: 8),
                            _buildContainerBadge(
                              icon: Icons.local_drink_outlined,
                              label: 'Sifón 2L',
                              count: sifon,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isDone)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 22,
                    ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContainerBadge({
    required IconData icon,
    required String label,
    required int count,
  }) {
    final hasStock = count > 0;
    final Color bgColor = hasStock
        ? const Color(0xFF1D4ED8).withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);
    final Color textColor = hasStock
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasStock
              ? const Color(0xFF1D4ED8).withValues(alpha: 0.15)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(RouteStop stop) {
    return Row(
      children: [
        // Mode 1: Registrar Venta
        Expanded(
          child: _buildSelectorCard(
            label: 'Registrar Venta',
            subtitle: 'Facturar bidones',
            icon: Icons.point_of_sale_outlined,
            isSelected: _isSaleSelected,
            isEnabled: true,
            onTap: () => setState(() => _isSaleSelected = true),
          ),
        ),
        const SizedBox(width: 12),
        // Mode 2: Visita
        Expanded(
          child: _buildSelectorCard(
            label: 'Visita',
            subtitle: 'Entrega o gestión',
            icon: Icons.assignment_turned_in_outlined,
            isSelected: !_isSaleSelected,
            isEnabled: true,
            onTap: () => setState(() => _isSaleSelected = false),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectorCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF1565C0);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? activeColor : Colors.grey.shade500,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? activeColor : const Color(0xFF0D1B3E),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoloVisitSubSection({
    required bool hasReturns,
    required bool hasPayments,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RESULTADO DE LA VISITA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        // Toggle Buttons for Results
        Row(
          children: [
            _buildResultButton(
              'Ausente',
              'absent',
              Icons.person_off_outlined,
              isEnabled: !hasReturns && !hasPayments,
            ),
            const SizedBox(width: 8),
            _buildResultButton('No quiso', 'refused', Icons.block_flipped),
            const SizedBox(width: 8),
            _buildResultButton(
              'Reprogramar',
              'reschedule',
              Icons.calendar_today_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Reschedule Form Wheel
        if (_soloVisitResult == 'reschedule') ...[
          Text(
            'SELECCIONAR NUEVO DÍA',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          _buildQuickDateWheel(),
          const SizedBox(height: 16),
          _buildTimeSlotDropdown(),
        ],

        // Notes Text Field
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: _soloVisitResult == 'reschedule'
                ? 'Nota de reprogramación (opcional)'
                : 'Observaciones de la visita (opcional)',
            hintText: 'Ej: No tenía plata / Dejar el lunes sin falta...',
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),

        if (_soloVisitResult == 'reschedule') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF1565C0),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se agendará automáticamente una nueva parada en la fecha seleccionada.',
                    style: TextStyle(
                      fontSize: 11,
                      color: const Color(0xFF1565C0).withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultButton(
    String label,
    String value,
    IconData icon, {
    bool isEnabled = true,
  }) {
    final isSelected = _soloVisitResult == value;
    final activeColor = const Color(0xFF1565C0);

    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: !isEnabled
              ? Colors.grey.shade100
              : (isSelected
                    ? activeColor.withValues(alpha: 0.06)
                    : Colors.white),
          foregroundColor: !isEnabled
              ? Colors.grey.shade400
              : (isSelected ? activeColor : const Color(0xFF4B5563)),
          side: BorderSide(
            color: !isEnabled
                ? Colors.grey.shade300
                : (isSelected ? activeColor : const Color(0xFFD1D5DB)),
            width: isSelected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isEnabled
            ? () => setState(() => _soloVisitResult = value)
            : null,
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: !isEnabled
                  ? Colors.grey.shade400
                  : (isSelected ? activeColor : const Color(0xFF4B5563)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: !isEnabled
                    ? Colors.grey.shade400
                    : (isSelected ? activeColor : const Color(0xFF4B5563)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDateWheel() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final inTwoDays = today.add(const Duration(days: 2));

    String formatDayName(DateTime date) {
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
      return days[date.weekday];
    }

    return Row(
      children: [
        _buildWheelChip('Mañana (${tomorrow.day})', 1),
        const SizedBox(width: 8),
        _buildWheelChip('${formatDayName(inTwoDays)} (${inTwoDays.day})', 2),
      ],
    );
  }

  Widget _buildWheelChip(String label, int offset) {
    final isSelected = _rescheduleDayOffset == offset;
    final activeColor = const Color(0xFF1565C0);

    return Expanded(
      child: ChoiceChip(
        label: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF4B5563),
            ),
          ),
        ),
        selected: isSelected,
        onSelected: (val) {
          if (val) setState(() => _rescheduleDayOffset = offset);
        },
        selectedColor: activeColor,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? activeColor : const Color(0xFFD1D5DB),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildTimeSlotDropdown() {
    final slots = [
      'Mañana (09:00 - 12:00)',
      'Mediodía (12:00 - 14:00)',
      'Tarde (14:00 - 18:00)',
    ];

    return DropdownButtonFormField<String>(
      value: _rescheduleTimeSlot,
      decoration: const InputDecoration(
        labelText: 'HORARIO ESTIMADO',
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: slots
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _rescheduleTimeSlot = val);
      },
    );
  }

  Widget _buildDoneStateBanner(StopStatus status) {
    final isDone = status == StopStatus.done;
    final color = isDone ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bg = isDone ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.person_off_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            isDone
                ? 'Parada completada con éxito'
                : 'Cliente ausente en esta visita',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyFooter(
    RouteStop stop,
    bool isDone,
    bool hasSales, {
    required bool hasReturns,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: isDone
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver a la Ruta'),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasSales &&
                    !_isSaleSelected &&
                    _soloVisitResult == null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      'Seleccioná un resultado primero',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                    ),
                    onPressed:
                        (!hasSales &&
                            !_isSaleSelected &&
                            _soloVisitResult == null)
                        ? null
                        : () async {
                            if (!hasSales && _isSaleSelected) {
                              // Pre-fill customer AND visitId, then launch sales flow!
                              ref
                                  .read(saleDraftProvider.notifier)
                                  .selectCustomer(
                                    stop.customer,
                                    visitId: stop.id,
                                  );

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SaleStep1Screen(),
                                ),
                              );
                            } else {
                              // Visita trigger (either normal solo visit, or closing the visit after sales!)
                              StopStatus nextStatus = StopStatus.done;
                              if (!hasSales) {
                                if (_soloVisitResult == 'absent' &&
                                    !hasReturns) {
                                  nextStatus = StopStatus.absent;
                                } else if (_soloVisitResult == 'refused') {
                                  nextStatus = hasReturns
                                      ? StopStatus.done
                                      : StopStatus.absent;
                                }
                              }

                              String toastMessage;
                              IconData toastIcon;
                              Color toastColor;

                              if (hasSales) {
                                toastMessage =
                                    'Visita finalizada - Venta registrada';
                                toastIcon = Icons.check_circle_rounded;
                                toastColor = const Color(0xFF10B981);
                              } else if (_soloVisitResult == 'absent') {
                                toastMessage =
                                    'Visita finalizada - Cliente Ausente';
                                toastIcon = Icons.person_off_outlined;
                                toastColor = const Color(0xFFEF4444);
                              } else if (_soloVisitResult == 'refused') {
                                toastMessage =
                                    'Visita finalizada - Compra rechazada';
                                toastIcon = Icons.block_flipped;
                                toastColor = const Color(0xFFF59E0B);
                              } else {
                                // reschedule
                                toastMessage = 'Visita reprogramada con éxito';
                                toastIcon = Icons.calendar_today_outlined;
                                toastColor = const Color(0xFF1565C0);
                              }

                              // 1. Pop the sheet immediately to eliminate flicker
                              Navigator.of(context).pop();

                              // 2. Schedule the gorgeous Overlay top toast in the next frame
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                TopToast.show(
                                  context,
                                  message: toastMessage,
                                  icon: toastIcon,
                                  color: toastColor,
                                );
                              });

                              // 4. Update state asynchronously — record visit
                              //    first, then mark stop (spec F2 order).
                              final visitType = _isSaleSelected
                                  ? VisitType.sale
                                  : VisitType.visit;
                              final outcome = _soloVisitResult == 'absent'
                                  ? 'absent'
                                  : _soloVisitResult == 'refused'
                                  ? 'refused'
                                  : 'successful';
                              await ref
                                  .read(completeVisitUseCaseProvider)
                                  .execute(
                                    stopId: stop.id,
                                    customerId: stop.customer.id,
                                    visitType: visitType,
                                    nextStatus: nextStatus,
                                    outcome: outcome,
                                    observations:
                                        _noteController.text.isNotEmpty
                                        ? _noteController.text
                                        : null,
                                  );
                            }
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hasSales
                              ? 'Cerrar Visita'
                              : (_isSaleSelected
                                    ? 'Iniciar Registro de Venta'
                                    : 'Cerrar Visita'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRegisteredSaleCard(Sale sale) {
    // Description of products
    final itemsDesc = sale.items
        .map((item) => '${item.quantity}x ${item.product.name}')
        .join('\n');

    // Payment method text and color
    String methodText = '';
    Color badgeColor = Colors.grey;
    Color badgeBg = Colors.grey.shade100;

    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        methodText = 'EFECTIVO';
        badgeColor = const Color(0xFF10B981);
        badgeBg = const Color(0xFFE8F5E9);
        break;
      case PaymentMethod.transfer:
        methodText = 'TRANSFERENCIA';
        badgeColor = const Color(0xFF8B5CF6);
        badgeBg = const Color(0xFFF3E8FF);
        break;
      case PaymentMethod.credit:
        methodText = 'A CRÉDITO';
        badgeColor = const Color(0xFFF97316);
        badgeBg = const Color(0xFFFFF7ED);
        break;
      case PaymentMethod.mixed:
        methodText = 'MIXTO';
        badgeColor = const Color(0xFF2563EB);
        badgeBg = const Color(0xFFEFF6FF);
        break;
      case PaymentMethod.route:
        methodText = 'RUTA';
        badgeColor = const Color(0xFF0D1B3E);
        badgeBg = const Color(0xFFF1F5F9);
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading with blue checkmark
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF2563EB),
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Venta registrada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B3E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Detailed card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: items + payment badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemsDesc,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B3E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        methodText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: Total amount
              Text(
                '\$${sale.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0D1B3E),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddAnotherSaleButton(RouteStop stop) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Agregar otra venta'),
        onPressed: () {
          ref
              .read(saleDraftProvider.notifier)
              .selectCustomer(stop.customer, visitId: stop.id);

          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SaleStep1Screen()));
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1565C0),
          side: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'La visita se marcará como completada al finalizar.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF1E40AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StandaloneContainerReturnDialog extends ConsumerStatefulWidget {
  const StandaloneContainerReturnDialog({super.key, required this.stop});

  final RouteStop stop;

  @override
  ConsumerState<StandaloneContainerReturnDialog> createState() =>
      _StandaloneContainerReturnDialogState();
}

class _StandaloneContainerReturnDialogState
    extends ConsumerState<StandaloneContainerReturnDialog> {
  final Map<String, int> _returns = {'BIDON_20L': 0, 'SIFON_2L': 0};

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(
      customerContainerBalancesProvider(widget.stop.customer.id),
    );
    final balances = balancesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <CustomerContainerBalance>[],
    );

    return AlertDialog(
      title: const Text(
        'Registrar Retorno de Envases',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...['BIDON_20L', 'SIFON_2L'].map((type) {
              final returned = _returns[type] ?? 0;
              final label = type == 'BIDON_20L' ? 'Bidón 20L' : 'Sifón 2L';
              final balance = balances
                  .firstWhere(
                    (b) => b.containerType == type,
                    orElse: () => CustomerContainerBalance(
                      customerId: widget.stop.customer.id,
                      containerType: type,
                      quantity: 0,
                    ),
                  )
                  .quantity;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: returned > 0
                              ? () {
                                  setState(() {
                                    _returns[type] = returned - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFFEF4444),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$returned',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: returned < balance
                              ? () {
                                  setState(() {
                                    _returns[type] = returned + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final repository = ref.read(inventoryRepositoryProvider);
            for (final type in ['BIDON_20L', 'SIFON_2L']) {
              final returnedQty = _returns[type] ?? 0;
              final movement = ContainerMovement(
                id: const Uuid().v4(),
                customerId: widget.stop.customer.id,
                containerType: type,
                deliveredQuantity: 0,
                returnedQuantity: returnedQty,
                createdAt: DateTime.now(),
                visitId: widget.stop.id,
              );
              await repository.recordContainerMovement(movement);
            }

            ref.invalidate(visitMovementsProvider(widget.stop.id));

            if (context.mounted) {
              Navigator.of(context).pop();
              TopToast.show(
                context,
                message: 'Retorno de envases registrado',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
