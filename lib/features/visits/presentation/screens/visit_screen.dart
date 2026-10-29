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
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/sales/domain/models/sale.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/providers/sale_repository_provider.dart';
import 'package:app/features/visits/domain/models/visit_outcome.dart';
import 'package:app/features/visits/domain/models/visit_type.dart';
import 'package:app/features/visits/presentation/providers/visit_repository_provider.dart';
import 'package:app/features/visits/presentation/providers/complete_visit_usecase_provider.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/register_debt_payment.dart';
import 'package:app/features/payments/domain/models/payment.dart';
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
import 'package:app/features/visits/presentation/widgets/visit_reschedule_time_field.dart';
import 'package:app/features/visits/domain/reschedule_time.dart';

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
  VisitOutcome? _selectedOutcome; // null initially so they have to select one!
  // Reschedules happen later the same day (ADR 0002).
  TimeOfDay? _rescheduleTime;
  RescheduleTimeError? _rescheduleError;
  bool _isClosing = false;
  final TextEditingController _noteController = TextEditingController();

  bool get _isRescheduleSelected =>
      _selectedOutcome?.triggersReschedule ?? false;

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

        if ((hasReturns || hasPayments) && _isRescheduleSelected) {
          _selectedOutcome = null;
        }

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
                  hasSoloResult: _selectedOutcome != null,
                  isBusy: _isClosing,
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

  Future<void> _onVisitFooterPrimary(
    RouteStop stop, {
    required bool hasSales,
    required bool hasReturns,
  }) async {
    if (!hasSales && _isSaleSelected) {
      ref
          .read(saleDraftProvider.notifier)
          .selectCustomer(stop.customer, visitId: stop.id);
      if (!mounted) return;
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const SaleStep1Screen()));
      return;
    }

    if (_isClosing) return;

    final outcome = _selectedOutcome;
    final triggersReschedule =
        !hasSales && (outcome?.triggersReschedule ?? false);
    final nextStatus = triggersReschedule ? StopStatus.absent : StopStatus.done;

    DateTime? rescheduleAt;
    if (triggersReschedule) {
      rescheduleAt = _rescheduleDateTime(DateTime.now());
      final error = rescheduleAt == null
          ? RescheduleTimeError.notLater
          : checkRescheduleTime(now: DateTime.now(), at: rescheduleAt);
      if (error != null) {
        setState(() => _rescheduleError = error);
        return;
      }
    }

    final customerName = stop.customer.name;
    late final String toastMessage;
    late final IconData toastIcon;
    late final Color toastColor;

    if (hasSales) {
      toastMessage = 'Venta registrada · $customerName';
      toastIcon = Icons.check_circle_rounded;
      toastColor = MarilinColors.success;
    } else if (triggersReschedule) {
      final at = rescheduleAt!;
      final time =
          '${at.hour.toString().padLeft(2, '0')}:'
          '${at.minute.toString().padLeft(2, '0')}';
      toastMessage = 'Reprogramada $time · $customerName';
      toastIcon = Icons.calendar_today_outlined;
      toastColor = MarilinColors.brandBlue;
    } else {
      toastMessage = 'Visita cerrada · $customerName';
      toastIcon = Icons.check_circle_rounded;
      toastColor = MarilinColors.success;
    }

    final visitType = _isSaleSelected ? VisitType.sale : VisitType.visit;

    setState(() => _isClosing = true);
    try {
      await ref
          .read(completeVisitUseCaseProvider)
          .execute(
            stopId: stop.id,
            customerId: stop.customer.id,
            visitType: visitType,
            nextStatus: nextStatus,
            outcomeId: hasSales ? null : outcome?.id,
            observations: _noteController.text.isNotEmpty
                ? _noteController.text
                : null,
            rescheduleAt: rescheduleAt,
          );
    } on RescheduleTimeException catch (error) {
      if (!mounted) return;
      setState(() {
        _isClosing = false;
        _rescheduleError = error.reason;
      });
      return;
    } catch (error) {
      if (!mounted) return;
      setState(() => _isClosing = false);
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
    }
    if (!mounted) return;

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

  /// The chosen reschedule time on [now]'s day, or null when none is chosen.
  DateTime? _rescheduleDateTime(DateTime now) {
    final time = _rescheduleTime;
    if (time == null) return null;
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _pickRescheduleTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _rescheduleTime ??
          TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: 'Hora de la nueva parada (hoy)',
    );
    if (picked == null || !mounted) return;
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    setState(() {
      _rescheduleTime = picked;
      _rescheduleError = checkRescheduleTime(now: DateTime.now(), at: at);
    });
  }

  Widget _buildSoloVisitSubSection({
    required bool hasReturns,
    required bool hasPayments,
  }) {
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
                      isEnabled: isVisitOutcomeEnabled(
                        outcome,
                        hasReturns: hasReturns,
                        hasPayments: hasPayments,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Reschedule Form Wheel
        if (_isRescheduleSelected) ...[
          VisitRescheduleTimeField(
            selected: _rescheduleTime,
            error: _rescheduleError,
            onTap: _pickRescheduleTime,
          ),
        ],

        // Notes Text Field
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            labelText: _isRescheduleSelected
                ? 'Nota de reprogramación (opcional)'
                : 'Observaciones de la visita (opcional)',
            hintText: 'Ej: No tenía plata / Dejar el lunes sin falta...',
            alignLabelWithHint: true,
          ),
          maxLines: 2,
        ),

        if (_isRescheduleSelected) ...[
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

  Widget _buildResultButton(VisitOutcome outcome, {bool isEnabled = true}) {
    final label = outcome.name;
    final icon = visitOutcomeIcon(outcome);
    final isSelected = _selectedOutcome?.id == outcome.id;
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
        onPressed: isEnabled
            ? () => setState(() => _selectedOutcome = outcome)
            : null,
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

  Widget _buildDoneStateBanner(StopStatus status) {
    final isDone = status == StopStatus.done;
    final color = isDone
        ? context.marilin.vivid(MarilinColors.success)
        : context.marilin.vivid(MarilinColors.destructive);
    final bg = isDone
        ? context.marilin.soft(MarilinColors.success.withValues(alpha: 0.12))
        : context.marilin.soft(
            MarilinColors.destructive.withValues(alpha: 0.12),
          );

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
                : status == StopStatus.rescheduled
                ? 'Visita reprogramada para hoy'
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
              'Venta registrada',
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
                  color: context.marilin.ink,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: SyncBadgeContainer(
            entity: PendingEntity.sale,
            entityId: sale.id,
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
