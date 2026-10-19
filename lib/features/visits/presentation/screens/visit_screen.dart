import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';
import 'package:app/features/customers/presentation/widgets/address_picker_map.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:latlong2/latlong.dart';
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
import 'package:uuid/uuid.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/widgets/debt_payment_dialog.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/visits/presentation/widgets/visit_section_header.dart';
import 'package:app/features/visits/presentation/widgets/visit_sticky_footer.dart';
import 'package:app/features/visits/presentation/widgets/visit_mode_selector.dart';
import 'package:app/features/visits/presentation/widgets/visit_customer_card.dart';
import 'package:app/features/visits/presentation/widgets/visit_debt_banner.dart';
import 'package:app/features/visits/presentation/widgets/visit_custody_banner.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';

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

    final balanceAsync = ref.watch(customerBalanceProvider(stop.customer.id));
    final balance = balanceAsync.value ?? stop.customer.debtAmount;

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
          backgroundColor: MarilinColors.scaffoldMuted,
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
                    color: MarilinColors.brandBlue,
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
                        color: isDone ? Colors.green : MarilinColors.brandBlue,
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
                        color: isDone ? Colors.green : MarilinColors.brandBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: MarilinColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          body: SafeArea(
            bottom: false,
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
                        const VisitSectionHeader(
                          title: 'Parada',
                          subtitle: 'Cliente y ubicación de entrega',
                        ),
                        VisitCustomerCard(
                          customerName: stop.customer.name,
                          formattedAddress: _formatStopAddress(stop),
                          phone: stop.customer.phone,
                          onMapPressed: stop.customer.addresses.isNotEmpty
                              ? () => _openCustomerMap(stop)
                              : null,
                          onWhatsAppLongPress: stop.customer.phone != null
                              ? () => _openWhatsApp(stop.customer.phone!)
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const VisitSectionHeader(
                          title: 'Cuenta y envases',
                          subtitle: 'Deuda y bidones en poder del cliente',
                        ),
                        if (balance > 0) ...[
                          VisitDebtBanner(
                            debtAmount: balance,
                            onTap: isDone
                                ? null
                                : () => _registerDebtPayment(balance, stop),
                          ),
                          const SizedBox(height: 12),
                        ],
                        VisitCustodyBanner(stop: stop),
                        const SizedBox(height: 24),
                        if (!isDone) ...[
                          if (hasSales) ...[
                            const VisitSectionHeader(
                              title: 'Registro',
                              subtitle: 'Ventas cargadas en esta parada',
                            ),
                            ...sales.map(
                              (sale) => _buildRegisteredSaleCard(sale),
                            ),
                            const SizedBox(height: 16),
                            _buildAddAnotherSaleButton(stop),
                            const SizedBox(height: 20),
                            _buildInfoBanner(),
                          ] else ...[
                            const VisitSectionHeader(
                              title: 'Acción',
                              subtitle: 'Venta o visita sin entrega',
                            ),
                            VisitModeSelector(
                              isSaleSelected: _isSaleSelected,
                              onSelectSale: () =>
                                  setState(() => _isSaleSelected = true),
                              onSelectVisit: () =>
                                  setState(() => _isSaleSelected = false),
                            ),
                            const SizedBox(height: 20),
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
                          const VisitSectionHeader(title: 'Estado'),
                          _buildDoneStateBanner(stop.status),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Unified Sticky Footer
                VisitStickyFooter(
                  isDone: isDone,
                  hasSales: hasSales,
                  isSaleSelected: _isSaleSelected,
                  soloVisitResult: _soloVisitResult,
                  onBackToRoute: () => Navigator.of(context).pop(),
                  onPrimaryPressed: () => _onVisitFooterPrimary(
                    stop,
                    hasSales: hasSales,
                    hasReturns: hasReturns,
                  ),
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

  String _formatStopAddress(RouteStop stop) {
    if (stop.customer.addresses.isEmpty) {
      return 'Sin dirección cargada';
    }
    final addr = stop.customer.addresses.first;
    return AddressFormatter.format(
      street: addr.street,
      neighborhood: addr.neighborhood,
      floor: addr.floor,
      apartment: addr.apartment,
      visualReference: addr.visualReference,
    );
  }

  Future<void> _openCustomerMap(RouteStop stop) async {
    final addr = stop.customer.addresses.firstOrNull;
    if (addr == null) return;

    await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => AddressPickerMap(
          initialLatitude: addr.latitude,
          initialLongitude: addr.longitude,
          initialSearchQuery:
              (addr.neighborhood != null && addr.neighborhood!.trim().isNotEmpty)
                  ? '${addr.street}, ${addr.neighborhood}, Salta'
                  : '${addr.street}, Salta',
          onSave: (latLng) async {
            final repository = ref.read(customerRepositoryProvider);
            final updateResult = await repository.updateAddressCoordinates(
              addr.id,
              latLng.latitude,
              latLng.longitude,
            );
            if (!mounted) return;
            switch (updateResult) {
              case Success():
                TopToast.showSuccess(
                  context,
                  'Ubicación del cliente guardada',
                );
                ref.invalidate(customerByIdProvider(stop.customer.id));
              case Error(:final error):
                TopToast.showError(
                  context,
                  'Error al guardar ubicación: $error',
                );
            }
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
  }

  Future<void> _registerDebtPayment(double debt, RouteStop stop) async {
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
      if (result.transferAmount != null && result.transferAmount! > 0) {
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

    if (payments.isEmpty) return;

    final res = await ref.read(registerPaymentUseCaseProvider).execute(payments);
    if (!context.mounted) return;
    switch (res) {
      case Success():
        TopToast.show(
          context,
          message: 'Pago registrado con éxito',
          icon: Icons.check_circle_rounded,
          color: MarilinColors.success,
        );
      case Error(:final error):
        TopToast.show(
          context,
          message: 'Error al registrar pago: $error',
          icon: Icons.error_outline,
          color: MarilinColors.destructive,
        );
    }
  }

  Future<void> _onVisitFooterPrimary(
    RouteStop stop, {
    required bool hasSales,
    required bool hasReturns,
  }) async {
    if (!hasSales && _isSaleSelected) {
      ref.read(saleDraftProvider.notifier).selectCustomer(
            stop.customer,
            visitId: stop.id,
          );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SaleStep1Screen()),
      );
      return;
    }

    StopStatus nextStatus = StopStatus.done;
    if (!hasSales) {
      if (_soloVisitResult == 'absent' && !hasReturns) {
        nextStatus = StopStatus.absent;
      } else if (_soloVisitResult == 'refused') {
        nextStatus = hasReturns ? StopStatus.done : StopStatus.absent;
      }
    }

    late final String toastMessage;
    late final IconData toastIcon;
    late final Color toastColor;

    if (hasSales) {
      toastMessage = 'Visita finalizada - Venta registrada';
      toastIcon = Icons.check_circle_rounded;
      toastColor = MarilinColors.success;
    } else if (_soloVisitResult == 'absent') {
      toastMessage = 'Visita finalizada - Cliente Ausente';
      toastIcon = Icons.person_off_outlined;
      toastColor = const Color(0xFFEF4444);
    } else if (_soloVisitResult == 'refused') {
      toastMessage = 'Visita finalizada - Compra rechazada';
      toastIcon = Icons.block_flipped;
      toastColor = const Color(0xFFF59E0B);
    } else {
      toastMessage = 'Visita reprogramada con éxito';
      toastIcon = Icons.calendar_today_outlined;
      toastColor = MarilinColors.brandBlue;
    }

    if (!mounted) return;
    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      TopToast.show(
        context,
        message: toastMessage,
        icon: toastIcon,
        color: toastColor,
      );
    });

    final visitType =
        _isSaleSelected ? VisitType.sale : VisitType.visit;
    final outcome = _soloVisitResult == 'absent'
        ? 'absent'
        : _soloVisitResult == 'refused'
            ? 'refused'
            : 'successful';

    await ref.read(completeVisitUseCaseProvider).execute(
          stopId: stop.id,
          customerId: stop.customer.id,
          visitType: visitType,
          nextStatus: nextStatus,
          outcome: outcome,
          observations:
              _noteController.text.isNotEmpty ? _noteController.text : null,
        );
  }

  Widget _buildSoloVisitSubSection({
    required bool hasReturns,
    required bool hasPayments,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VisitSectionHeader(
          title: 'Resultado',
          subtitle: 'Motivo si no hubo venta',
        ),
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
              color: MarilinColors.brandBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: MarilinColors.brandBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se agendará automáticamente una nueva parada en la fecha seleccionada.',
                    style: TextStyle(
                      fontSize: 11,
                      color: MarilinColors.brandBlue.withValues(alpha: 0.9),
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
    final activeColor = MarilinColors.brandBlue;

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
    final activeColor = MarilinColors.brandBlue;

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
          foregroundColor: MarilinColors.brandBlue,
          side: const BorderSide(color: MarilinColors.brandBlue, width: 1.5),
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
