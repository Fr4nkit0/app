import 'package:app/core/providers/clock_provider.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/route/domain/models/route_stop.dart';
import 'package:app/features/route/domain/models/stop_status.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/route/presentation/widgets/stop_requested_label.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/cancel_sale_usecase_provider.dart';
import 'package:app/features/sales/presentation/widgets/cancel_record_dialog.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/register_debt_payment.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/sync/domain/models/pending_change.dart';
import 'package:app/features/sync/presentation/widgets/sync_badge_container.dart';
import 'package:app/features/visits/presentation/widgets/visit_section_header.dart';
import 'package:app/features/visits/presentation/visit_outcome_display.dart';
import 'package:app/features/visits/presentation/widgets/visit_sticky_footer.dart';
import 'package:app/features/visits/presentation/widgets/visit_mode_selector.dart';
import 'package:app/features/visits/presentation/widgets/visit_customer_card.dart';
import 'package:app/features/visits/presentation/widgets/visit_debt_banner.dart';
import 'package:app/features/visits/presentation/widgets/visit_custody_banner.dart';
import 'package:app/features/visits/presentation/widgets/visit_outcome_banner.dart';
import 'package:app/features/visits/presentation/widgets/visit_record_tile.dart';
import 'package:app/features/visits/presentation/widgets/visit_reschedule_time_field.dart';
import 'package:app/features/visits/presentation/providers/visit_session.dart';
import 'package:app/features/visits/presentation/providers/edit_visit_usecase_provider.dart';
import 'package:app/features/visits/presentation/widgets/visit_edit_sheet.dart';
import 'package:app/features/visits/domain/models/visit_summary.dart';

class VisitScreen extends ConsumerStatefulWidget {
  const VisitScreen({super.key, required this.stopId});

  final String stopId;

  @override
  ConsumerState<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends ConsumerState<VisitScreen> {
  final TextEditingController _noteController = TextEditingController();

  VisitSession get _session =>
      ref.read(visitSessionProvider(widget.stopId).notifier);

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

    // The debt comes only from the customer account: 0 until it loads and
    // for a customer without one.
    final balance =
        ref.watch(customerBalanceProvider(stop.customer.id)).value ?? 0.0;

    final isDone = stop.status != StopStatus.pending;
    final salesAsync = ref.watch(stopSalesProvider(widget.stopId));
    final session = ref.watch(visitSessionProvider(widget.stopId));
    // Payments that settle a sale are part of that sale's card.
    final payments = [
      for (final payment
          in ref.watch(visitPaymentsProvider(widget.stopId)).value ??
              const <Payment>[])
        if (payment.saleId == null) payment,
    ];
    final returns = [
      for (final movement
          in ref.watch(visitMovementsProvider(widget.stopId)).value ??
              const <ContainerMovement>[])
        if (movement.returnedQuantity > 0) movement,
    ];
    final now = ref.watch(clockProvider)();
    final canEditVisit =
        stop.status != StopStatus.rescheduled &&
        (stop.visit?.isEditableOn(now) ?? false);
    // A reschedule adds a stop, so it is not an outcome an edit can pick.
    final editOutcomes = canEditVisit
        ? [
            for (final outcome
                in ref.watch(visitOutcomesProvider).value ??
                    const <VisitOutcome>[])
              if (!outcome.triggersReschedule) outcome,
          ]
        : const <VisitOutcome>[];
    final containerLabels = <String, String>{
      for (final type
          in ref.watch(containerTypesProvider).value ?? const <ContainerType>[])
        type.code: type.label,
    };

    return salesAsync.when(
      data: (sales) {
        // A cancelled sale takes back the containers returned with it.
        final cancelledSaleIds = {
          for (final sale in sales)
            if (sale.isCancelled) sale.id,
        };
        final validReturns = [
          for (final movement in returns)
            if (!cancelledSaleIds.contains(movement.saleId)) movement,
        ];
        final cancelledReturns = [
          for (final movement in returns)
            if (cancelledSaleIds.contains(movement.saleId)) movement,
        ];
        final records = [
          for (final sale in sales) _buildRegisteredSaleCard(sale, now),
          for (final payment in payments) _buildPaymentRecord(payment, now),
          if (validReturns.isNotEmpty)
            _buildReturnRecord(validReturns, containerLabels),
          if (cancelledReturns.isNotEmpty)
            _buildReturnRecord(
              cancelledReturns,
              containerLabels,
              isCancelled: true,
            ),
        ];
        const recordsHeader = VisitSectionHeader(
          title: 'Registro',
          subtitle: 'Ventas, cobros y devoluciones de esta parada',
        );
        return Scaffold(
          backgroundColor: context.marilin.scaffoldMuted,
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              tooltip: 'Volver',
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
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: isDone ? Colors.green : MarilinColors.brandBlue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            backgroundColor: context.marilin.surface,
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
                          onWhatsAppLongPress: stop.customer.phone != null
                              ? () => _openWhatsApp(stop.customer.phone!)
                              : null,
                        ),
                        if (stop.isRequested)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: StopRequestedLabel(stop: stop, fontSize: 14),
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
                                : () => registerDebtPayment(
                                    context,
                                    ref,
                                    customer: stop.customer,
                                    debt: balance,
                                    visitId: stop.id,
                                  ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        VisitCustodyBanner(stop: stop),
                        const SizedBox(height: 24),
                        if (!isDone) ...[
                          if (session.hasSales) ...[
                            recordsHeader,
                            ...records,
                            const SizedBox(height: 16),
                            _buildAddAnotherSaleButton(stop),
                            const SizedBox(height: 20),
                            _buildInfoBanner(),
                          ] else ...[
                            if (records.isNotEmpty) ...[
                              recordsHeader,
                              ...records,
                              const SizedBox(height: 12),
                            ],
                            const VisitSectionHeader(
                              title: 'Acción',
                              subtitle: 'Venta o visita sin entrega',
                            ),
                            VisitModeSelector(
                              isSaleSelected: session.isSaleSelected,
                              onSelectSale: _session.selectSaleMode,
                              onSelectVisit: _session.selectVisitMode,
                            ),
                            const SizedBox(height: 20),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              child: !session.isSaleSelected
                                  ? _buildSoloVisitSubSection(session)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ] else ...[
                          const VisitSectionHeader(title: 'Estado'),
                          VisitOutcomeBanner(stop: stop),
                          if (canEditVisit)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Editar resultado'),
                                onPressed: () =>
                                    _editVisit(stop.visit!, editOutcomes),
                              ),
                            ),
                          if (records.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            recordsHeader,
                            ...records,
                          ],
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Unified Sticky Footer
                VisitStickyFooter(
                  isDone: isDone,
                  hasSales: session.hasSales,
                  isSaleSelected: session.isSaleSelected,
                  hasSoloResult: session.canClose,
                  isBusy: session.isClosing,
                  onBackToRoute: () => Navigator.of(context).pop(),
                  onPrimaryPressed: () => _onVisitFooterPrimary(stop),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: context.marilin.surface,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.marilin.surface,
        body: ErrorState(
          title: 'No pudimos cargar la visita',
          message:
              'Revisá la conexión y reintentá. '
              'Lo que ya cargaste sigue guardado en el teléfono.',
          onRetry: () {
            ref.invalidate(stopSalesProvider(widget.stopId));
            ref.invalidate(customerBalanceProvider(stop.customer.id));
            ref.invalidate(visitPaymentsProvider(widget.stopId));
            ref.invalidate(visitMovementsProvider(widget.stopId));
          },
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

  Future<void> _openWhatsApp(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$digits');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        TopToast.showError(context, 'No se pudo abrir WhatsApp');
      }
    }
  }

  Future<void> _onVisitFooterPrimary(RouteStop stop) async {
    if (ref.read(visitSessionProvider(widget.stopId)).startsSale) {
      ref
          .read(saleDraftProvider.notifier)
          .selectCustomer(stop.customer, visitId: stop.id);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SaleStep1Screen()));
      return;
    }

    final customerName = stop.customer.name;
    final result = await _session.close(observations: _noteController.text);
    if (!mounted) return;

    final String toastMessage;
    final IconData toastIcon;
    final Color toastColor;
    switch (result) {
      case VisitCloseRejected():
        return;
      case VisitCloseFailed(:final error):
        TopToast.show(
          context,
          message: failureMessage(
            error,
            fallback: 'No se guardó la visita. Reintentá.',
          ),
          icon: Icons.error_outline,
          color: MarilinColors.destructive,
        );
        return;
      case VisitClosedWithSales():
        toastMessage = 'Venta registrada · $customerName';
        toastIcon = Icons.check_circle_rounded;
        toastColor = MarilinColors.success;
      case VisitRescheduled(:final at):
        final time =
            '${at.hour.toString().padLeft(2, '0')}:'
            '${at.minute.toString().padLeft(2, '0')}';
        toastMessage = 'Reprogramada $time · $customerName';
        toastIcon = Icons.calendar_today_outlined;
        toastColor = MarilinColors.brandBlue;
      case VisitClosed():
        toastMessage = 'Visita cerrada · $customerName';
        toastIcon = Icons.check_circle_rounded;
        toastColor = MarilinColors.success;
    }

    // The toast outlives this screen, so it uses the navigator's context.
    final navigator = Navigator.of(context);
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      TopToast.show(
        navigator.context,
        message: toastMessage,
        icon: toastIcon,
        color: toastColor,
        duration: const Duration(seconds: 4),
      );
    });
  }

  /// Lets the driver change the outcome and notes of the closed visit.
  Future<void> _editVisit(
    VisitSummary visit,
    List<VisitOutcome> outcomes,
  ) async {
    final edit = await showModalBottomSheet<VisitEdit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => VisitEditSheet(
        outcomes: outcomes,
        initialOutcome: visit.outcome,
        initialNotes: visit.notes,
      ),
    );
    if (edit == null || !mounted) return;
    try {
      await ref
          .read(editVisitUseCaseProvider)
          .execute(
            visitId: visit.visitId!,
            outcomeId: edit.outcome.id,
            notes: edit.notes,
          );
    } catch (error) {
      if (!mounted) return;
      TopToast.show(
        context,
        message: failureMessage(
          error,
          fallback: 'No se guardó el cambio. Reintentá.',
        ),
        icon: Icons.error_outline,
        color: MarilinColors.destructive,
      );
      return;
    }
    if (!mounted) return;
    TopToast.show(
      context,
      message: 'Resultado actualizado',
      icon: Icons.check_circle_rounded,
      color: MarilinColors.success,
    );
  }

  /// Cancels a sale of today, with the payments that settled it.
  Future<void> _cancelSale(Sale sale) async {
    final confirmation = await confirmCancelRecord(
      context,
      title: '¿Anular la venta?',
      message:
          'También se anulan los cobros de esta venta: la deuda vuelve a '
          'como estaba antes y los productos vuelven al camión.',
    );
    if (confirmation == null || !mounted) return;
    await _runCancellation(
      () => ref
          .read(cancelSaleUseCaseProvider)
          .execute(sale.id, reason: confirmation.reason),
      done: 'Venta anulada',
    );
  }

  /// Cancels a payment of today that did not settle a sale.
  Future<void> _cancelPayment(Payment payment) async {
    final confirmation = await confirmCancelRecord(
      context,
      title: '¿Anular el cobro?',
      message: 'El monto vuelve a sumarse a la deuda del cliente.',
    );
    if (confirmation == null || !mounted) return;
    await _runCancellation(
      () => ref
          .read(cancelPaymentUseCaseProvider)
          .execute(payment.id, reason: confirmation.reason),
      done: 'Cobro anulado',
    );
  }

  Future<void> _runCancellation(
    Future<void> Function() cancel, {
    required String done,
  }) async {
    try {
      await cancel();
    } catch (error) {
      if (!mounted) return;
      TopToast.show(
        context,
        message: failureMessage(error, fallback: 'No se anuló. Reintentá.'),
        icon: Icons.error_outline,
        color: MarilinColors.destructive,
      );
      return;
    }
    if (!mounted) return;
    TopToast.show(
      context,
      message: done,
      icon: Icons.check_circle_rounded,
      color: MarilinColors.success,
    );
  }

  Widget _cancelAction(String label, VoidCallback onPressed) => TextButton.icon(
    style: TextButton.styleFrom(foregroundColor: MarilinColors.destructive),
    icon: const Icon(Icons.block, size: 18),
    label: Text(label),
    onPressed: onPressed,
  );

  Future<void> _pickRescheduleTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _session.initialRescheduleTime(),
      helpText: 'Hora de la nueva parada (hoy)',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted) return;
    _session.setRescheduleTime(picked);
  }

  Widget _buildSoloVisitSubSection(VisitSessionState session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VisitSectionHeader(
          title: '¿Qué pasó?',
          subtitle: 'Elegí el motivo de la visita sin venta',
        ),
        // Toggle Buttons for Results (catalog driven)
        Consumer(
          builder: (context, ref, _) {
            final outcomes = ref.watch(visitOutcomesProvider).value ?? const [];
            if (outcomes.isEmpty) {
              return Text(
                'No hay resultados disponibles. Sincronizá la ruta.',
                style: TextStyle(
                  fontSize: 13,
                  color: context.marilin.inkSecondary,
                ),
              );
            }
            return Row(
              children: [
                for (final (index, outcome) in outcomes.indexed) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildResultButton(
                      outcome,
                      isSelected: session.selectedOutcome?.id == outcome.id,
                      isEnabled: session.isOutcomeEnabled(outcome),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Reschedule Form Wheel
        if (session.isRescheduleSelected) ...[
          VisitRescheduleTimeField(
            selected: session.rescheduleTime,
            error: session.rescheduleError,
            onTap: _pickRescheduleTime,
          ),
        ],

        // Notes Text Field
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: session.isRescheduleSelected
                ? 'Nota de reprogramación (opcional)'
                : 'Observaciones de la visita (opcional)',
            hintText: 'Ej: No tenía plata / Dejar el lunes sin falta...',
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),

        if (session.isRescheduleSelected) ...[
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
                    'Se agregará una nueva parada a la ruta de hoy a la hora elegida.',
                    style: TextStyle(
                      fontSize: 12,
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
    VisitOutcome outcome, {
    required bool isSelected,
    bool isEnabled = true,
  }) {
    final label = outcome.name;
    final icon = visitOutcomeIcon(outcome);
    final activeColor = MarilinColors.brandBlue;

    return SizedBox(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: !isEnabled
              ? context.marilin.fill
              : (isSelected
                    ? activeColor.withValues(alpha: 0.06)
                    : context.marilin.surface),
          foregroundColor: !isEnabled
              ? context.marilin.inkHint
              : (isSelected ? activeColor : context.marilin.inkSecondary),
          side: BorderSide(
            color: !isEnabled
                ? context.marilin.lineStrong
                : (isSelected ? activeColor : context.marilin.lineStrong),
            width: isSelected ? 1.5 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isEnabled ? () => _session.selectOutcome(outcome) : null,
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: !isEnabled
                  ? context.marilin.inkHint
                  : (isSelected ? activeColor : context.marilin.inkSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: !isEnabled
                    ? context.marilin.inkHint
                    : (isSelected ? activeColor : context.marilin.inkSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRecord(Payment payment, DateTime now) {
    return VisitRecordTile(
      statusLabel: payment.isCancelled ? 'Anulado' : null,
      action: payment.isCancellableOn(now)
          ? _cancelAction('Anular cobro', () => _cancelPayment(payment))
          : null,
      icon: Icons.payments_outlined,
      title: 'Cobro registrado',
      detail: switch (payment.type) {
        PaymentType.cash => 'Efectivo',
        PaymentType.transfer => 'Transferencia',
        PaymentType.credit => 'Crédito',
      },
      amount: formatMoney(payment.amount),
    );
  }

  Widget _buildReturnRecord(
    List<ContainerMovement> returns,
    Map<String, String> containerLabels, {
    bool isCancelled = false,
  }) {
    final returnedByType = <String, int>{};
    for (final movement in returns) {
      returnedByType.update(
        movement.containerType,
        (quantity) => quantity + movement.returnedQuantity,
        ifAbsent: () => movement.returnedQuantity,
      );
    }
    return VisitRecordTile(
      statusLabel: isCancelled ? 'Anulada' : null,
      icon: Icons.inventory_2_outlined,
      title: 'Devolución de envases',
      detail: [
        for (final MapEntry(key: type, value: quantity)
            in returnedByType.entries)
          '$quantity × ${containerLabels[type] ?? type}',
      ].join('\n'),
    );
  }

  Widget _buildRegisteredSaleCard(Sale sale, DateTime now) {
    // Description of products
    final itemsDesc = sale.items
        .map((item) => '${item.quantity}x ${item.product.name}')
        .join('\n');

    // Payment method text and color
    String methodText = '';
    Color badgeColor = context.marilin.textMuted;
    Color badgeBg = context.marilin.fill;

    switch (sale.paymentMethod) {
      case PaymentMethod.cash:
        methodText = 'EFECTIVO';
        badgeColor = context.marilin.vivid(MarilinColors.success);
        badgeBg = context.marilin.soft(
          MarilinColors.success.withValues(alpha: 0.12),
        );
        break;
      case PaymentMethod.transfer:
        methodText = 'TRANSFERENCIA';
        badgeColor = context.marilin.inkSecondary;
        badgeBg = context.marilin.soft(
          MarilinColors.brandNavy.withValues(alpha: 0.08),
        );
        break;
      case PaymentMethod.credit:
        methodText = 'A CRÉDITO';
        badgeColor = context.marilin.vivid(MarilinColors.accent);
        badgeBg = context.marilin.soft(
          MarilinColors.accent.withValues(alpha: 0.12),
        );
        break;
      case PaymentMethod.mixed:
        methodText = 'MIXTO';
        badgeColor = context.marilin.vivid(MarilinColors.brandBlue);
        badgeBg = context.marilin.soft(
          MarilinColors.brandBlue.withValues(alpha: 0.12),
        );
        break;
      case PaymentMethod.route:
        methodText = 'RUTA';
        badgeColor = context.marilin.ink;
        badgeBg = context.marilin.fill;
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
              decoration: BoxDecoration(
                color: context.marilin.soft(
                  MarilinColors.brandBlue.withValues(alpha: 0.12),
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: MarilinColors.brandBlue,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              sale.isCancelled ? 'Venta anulada' : 'Venta registrada',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.marilin.ink,
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
            color: context.marilin.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.marilin.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.marilin.isDark ? 0.3 : 0.02,
                ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.marilin.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
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
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (sale.isCancelled)
                          const RecordStatusBadge(label: 'Anulada'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: Total amount
              Text(
                formatMoney(sale.total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: sale.isCancelled
                      ? context.marilin.inkHint
                      : context.marilin.ink,
                  letterSpacing: -0.5,
                  decoration: sale.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SyncBadgeContainer(
                  entity: PendingEntity.sale,
                  entityId: sale.id,
                ),
              ),
            ),
            if (sale.isCancellableOn(now))
              _cancelAction('Anular venta', () => _cancelSale(sale)),
          ],
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
        color: context.marilin.soft(
          MarilinColors.brandBlue.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.marilin.soft(
            MarilinColors.brandBlue.withValues(alpha: 0.3),
          ),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: MarilinColors.brandBlue, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'La visita se marcará como completada al finalizar.',
              style: TextStyle(
                fontSize: 12,
                color: MarilinColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
