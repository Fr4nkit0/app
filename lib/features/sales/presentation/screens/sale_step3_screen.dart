import 'package:app/core/utils/money_formatter.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/presentation/widgets/payment_method_icon.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/core/widgets/core_horizontal_stepper.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';
import 'package:app/features/inventory/presentation/widgets/skeleton_exchange.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';
import 'package:app/features/sales/presentation/widgets/partial_payment.dart';
import 'package:app/features/sales/presentation/widgets/received_breakdown_note.dart';

class SaleStep3Screen extends ConsumerWidget {
  const SaleStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(saleDraftProvider);
    // The balance comes from the customer account, unclamped (negative:
    // credit in the customer's favor); the customer's snapshot stands in
    // until it loads.
    final customer = draft.customer;
    final balance = customer == null
        ? 0.0
        : ref.watch(customerBalanceProvider(customer.id)).value ??
              customer.debtAmount;

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      primary: false,
      backgroundColor: context.marilin.surface,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Header: back + title
                  _Header(customerName: draft.customer?.name ?? ''),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: CoreHorizontalStepper(
                              steps: ['Pedido', 'Cobro'],
                              stepDescriptions: [
                                'Elegir productos',
                                'Registrar pago',
                              ],
                              layoutRow: true,
                              currentStep: 1,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _TotalBlock(draft: draft, balance: balance),
                          const SizedBox(height: 24),
                          // Payment method grid + mixed fields
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _SectionLabel('Forma de pago'),
                                const SizedBox(height: 10),
                                _PaymentGrid(draft: draft),
                                const SizedBox(height: 12),
                                _CollectedAmountSection(
                                  draft: draft,
                                  balance: balance,
                                ),
                                // Progressive-disclosure mixed amounts
                                _MixedAmountsSection(
                                  draft: draft,
                                  balance: balance,
                                ),
                                // Live remaining indicator
                                if (draft.paymentMethod == PaymentMethod.mixed)
                                  _RemainingIndicator(draft: draft),
                                const SizedBox(height: 28),
                                const _SectionLabel('Pedido'),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          // Order detail
                          SaleStep3ClientCard(draft: draft),
                          _SkeletonSection(draft: draft),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Footer(draft: draft, balance: balance),
          SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

/// The soda crate lent or taken back with the sale; closed by default, since
/// most sales move none. Hidden while the catalog has no skeleton type.
/// Shows what is left on the truck of today's route, warning when the
/// delivery goes past it without blocking the sale.
class _SkeletonSection extends ConsumerWidget {
  const _SkeletonSection({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSkeleton =
        ref
            .watch(containerTypesProvider)
            .value
            ?.any((t) => t.code == ContainerType.skeletonCode) ??
        false;
    final customerId = draft.customer?.id;
    if (!hasSkeleton || customerId == null) return const SizedBox.shrink();

    final balance =
        ref
            .watch(customerContainerBalancesProvider(customerId))
            .value
            ?.where((b) => b.containerType == ContainerType.skeletonCode)
            .fold<int>(0, (sum, b) => sum + b.quantity) ??
        0;
    final truck = ref.watch(truckSkeletonsProvider).value;
    final notifier = ref.read(saleDraftProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.marilin.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ExpansionTile(
          initiallyExpanded:
              draft.skeletonDelivered > 0 || draft.skeletonReturned > 0,
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(Icons.add_circle_outline),
          title: const Text(
            'Esqueleto',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(skeletonBalanceLabel(balance)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
          children: [
            if (truck != null)
              Align(
                alignment: Alignment.centerLeft,
                child: SkeletonTruckLabel(
                  truck: truck,
                  delivered: draft.skeletonDelivered,
                  returned: draft.skeletonReturned,
                ),
              ),
            SkeletonExchange(
              delivered: draft.skeletonDelivered,
              returned: draft.skeletonReturned,
              onDeliveredChanged: notifier.setSkeletonDelivered,
              onReturnedChanged: notifier.setSkeletonReturned,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.customerName});

  final String customerName;

  @override
  Widget build(BuildContext context) {
    return ScreenHeader(
      title: 'Registrar Cobro',
      subtitle: customerName,
      onBackPressed: () => Navigator.of(context).pop(),
    );
  }
}

// ─── Total block ──────────────────────────────────────────────────────────────

class _TotalBlock extends StatelessWidget {
  const _TotalBlock({required this.draft, required this.balance});

  final SaleDraftState draft;

  /// The customer account before this sale; negative is credit.
  final double balance;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final muted = context.marilin.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A cobrar',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: muted,
            ),
          ),
          Text(
            formatMoney(draft.total),
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: tokens.primary,
              fontFeatures: tokens.tabularStyle.fontFeatures,
            ),
          ),
          // The account before this sale, as context for the money received.
          if (balance != 0)
            Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  balance > 0
                      ? 'Debe ${formatMoney(balance)} de antes'
                      : 'Saldo a favor ${formatMoney(-balance)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: muted,
                    fontFeatures: tokens.tabularStyle.fontFeatures,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── "Monto recibido" for cash and transfer (S2) ──────────────────────────────

/// What the customer hands over: below the total the rest stays as debt,
/// above it the rest pays previous debt and then stays as credit. A
/// customer who owes sees the debt and can collect all of it (S6).
class _CollectedAmountSection extends ConsumerWidget {
  const _CollectedAmountSection({required this.draft, required this.balance});

  final SaleDraftState draft;

  /// The customer account before this sale; negative is credit.
  final double balance;

  String? get _error =>
      draft.collectedAmount <= 0 ? 'Ingresá un monto mayor a \$0' : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = draft.paymentMethod;
    final collects =
        method == PaymentMethod.cash || method == PaymentMethod.transfer;
    if (!collects) return const SizedBox.shrink();
    final owed = balance > 0 ? balance : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CollectedAmountField(
        // A new method starts again at the total.
        key: ValueKey(method),
        initialAmount: draft.collectedAmount,
        unpaid: draft.unpaidAmount,
        errorText: _error,
        owedDebt: owed,
        payoffAmount: draft.total + owed,
        onChanged: ref.read(saleDraftProvider.notifier).setCollectedAmount,
      ),
    );
  }
}

// ─── Client + order summary card ──────────────────────────────────────────────

class SaleStep3ClientCard extends StatelessWidget {
  const SaleStep3ClientCard({super.key, required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.marilin.fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.marilin.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...draft.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 13,
                    color: context.marilin.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${item.quantity}× ${item.product.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    formatMoney(item.subtotal),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: tokens.tabularStyle.fontFeatures,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2×2 Payment grid ─────────────────────────────────────────────────────────

class _PaymentGrid extends ConsumerWidget {
  const _PaymentGrid({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 80,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // Iterate gridMethods (cash, transfer, mixed, credit) — route excluded
      children: PaymentMethod.gridMethods.map((method) {
        final isSelected = draft.paymentMethod == method;
        return _PaymentCard(
          method: method,
          selected: isSelected,
          onTap: () =>
              ref.read(saleDraftProvider.notifier).setPaymentMethod(method),
        );
      }).toList(),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;
    final foreground = selected ? Colors.white : context.marilin.ink;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: selected
          ? BorderSide.none
          : BorderSide(color: context.marilin.border),
    );
    return Semantics(
      button: true,
      selected: selected,
      label: method.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? primary : context.marilin.surface,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(paymentMethodIcon(method), size: 26, color: foreground),
                const SizedBox(height: 4),
                Text(
                  method.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: foreground,
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

// ─── Progressive-disclosure mixed amounts (AnimatedSize ~200ms easeOut) ───────

class _MixedAmountsSection extends ConsumerStatefulWidget {
  const _MixedAmountsSection({required this.draft, required this.balance});

  final SaleDraftState draft;

  /// The customer account before this sale; negative is credit.
  final double balance;

  @override
  ConsumerState<_MixedAmountsSection> createState() =>
      _MixedAmountsSectionState();
}

class _MixedAmountsSectionState extends ConsumerState<_MixedAmountsSection> {
  final _cashController = TextEditingController();
  final _transferController = TextEditingController();

  @override
  void dispose() {
    _cashController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_MixedAmountsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When method changes away from mixed, clear the text fields
    if (oldWidget.draft.paymentMethod == PaymentMethod.mixed &&
        widget.draft.paymentMethod != PaymentMethod.mixed) {
      _cashController.clear();
      _transferController.clear();
    }
  }

  void _onCashChanged(String value) {
    final cash = AmountField.parseAmount(value);
    final transfer = AmountField.parseAmount(_transferController.text);
    ref
        .read(saleDraftProvider.notifier)
        .setMixedAmounts(cash: cash, transfer: transfer);
  }

  void _onTransferChanged(String value) {
    final cash = AmountField.parseAmount(_cashController.text);
    final transfer = AmountField.parseAmount(value);
    ref
        .read(saleDraftProvider.notifier)
        .setMixedAmounts(cash: cash, transfer: transfer);
  }

  /// Fills one field with the whole sale total.
  void _fillAll({required bool cash}) {
    final total = widget.draft.total;
    final text = editableAmount(total);
    _cashController.text = cash ? text : '0';
    _transferController.text = cash ? '0' : text;
    ref
        .read(saleDraftProvider.notifier)
        .setMixedAmounts(cash: cash ? total : 0, transfer: cash ? 0 : total);
  }

  @override
  Widget build(BuildContext context) {
    final isMixed = widget.draft.paymentMethod == PaymentMethod.mixed;
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: isMixed
          ? Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('MONTOS MIXTOS'),
                  // What beyond the sale pays (S6).
                  if (widget.balance > 0) OwedDebtNote(owed: widget.balance),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Todo en efectivo'),
                        onPressed: () => _fillAll(cash: true),
                      ),
                      ActionChip(
                        label: const Text('Todo por transferencia'),
                        onPressed: () => _fillAll(cash: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AmountField(
                    focusColor: primary,
                    label: 'Efectivo',
                    controller: _cashController,
                    onChanged: _onCashChanged,
                  ),
                  const SizedBox(height: 10),
                  AmountField(
                    focusColor: primary,
                    label: 'Transferencia',
                    controller: _transferController,
                    onChanged: _onTransferChanged,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

// ─── Live "Falta: $X" indicator ───────────────────────────────────────────────

class _RemainingIndicator extends StatelessWidget {
  const _RemainingIndicator({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context) {
    // Below the total the rest stays as debt (S2).
    if (draft.isPartialPayment) {
      return UnpaidAmountNote(unpaid: draft.unpaidAmount);
    }
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final remaining = draft.remaining;
    // Beyond the total is covered too: the rest pays previous debt.
    final isCovered = remaining <= SaleDraftState.tolerance;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(
            isCovered ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: isCovered ? tokens.primary : tokens.destructive,
          ),
          const SizedBox(width: 6),
          Text(
            isCovered ? 'Cubierto' : 'Falta: ${formatMoney(remaining)}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: isCovered ? tokens.primary : tokens.destructive,
              fontFeatures: tokens.tabularStyle.fontFeatures,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.marilin.ink,
      ),
    );
  }
}

// ─── Footer with "Confirmar" button ──────────────────────────────────────────

class _Footer extends ConsumerStatefulWidget {
  const _Footer({required this.draft, required this.balance});

  final SaleDraftState draft;

  /// The customer account before this sale; negative is credit.
  final double balance;

  @override
  ConsumerState<_Footer> createState() => _FooterState();
}

class _FooterState extends ConsumerState<_Footer> {
  bool _busy = false;

  SaleDraftState get draft => widget.draft;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    return Container(
      decoration: BoxDecoration(
        color: context.marilin.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Where the money beyond the sale goes, right before confirming
          // it (S2).
          if (draft.extraReceived > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ReceivedBreakdownNote(
                  breakdown: draft.receivedBreakdown(widget.balance),
                ),
              ),
            ),
          Row(
            children: [
              // Botón Atrás
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Atrás',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Botón Confirmar — gated by canConfirm (REQ-COB-06)
              Expanded(
                flex: 6,
                child: Consumer(
                  builder: (context, ref, child) {
                    final balancesAsync = ref.watch(
                      customerContainerBalancesProvider(
                        draft.customer?.id ?? '',
                      ),
                    );
                    final containerTypes = ref
                        .watch(containerTypesProvider)
                        .maybeWhen(
                          data: (types) => types,
                          orElse: () => <ContainerType>[],
                        );

                    return FilledButton(
                      onPressed: draft.canConfirm && !_busy
                          ? () async {
                              // S6: money beyond the sale and the whole
                              // debt asks first, it may be a typing error;
                              // correcting stays here and saves nothing.
                              final breakdown = draft.receivedBreakdown(
                                widget.balance,
                              );
                              if (breakdown.credit > SaleDraftState.tolerance) {
                                final owed = widget.balance > 0
                                    ? widget.balance
                                    : 0.0;
                                final keep = await confirmLeavingCredit(
                                  context,
                                  received: breakdown.received,
                                  covered: draft.total + owed,
                                  hasDebt: owed > 0,
                                  credit: -breakdown.balanceAfter,
                                );
                                if (!keep || !context.mounted) return;
                              }
                              // S4: a partial sale asks first; cancelling
                              // stays on this step and saves nothing.
                              if (draft.isPartialPayment) {
                                final confirmed = await confirmPartialPayment(
                                  context,
                                  draft.unpaidAmount,
                                );
                                if (!confirmed || !context.mounted) return;
                              }
                              final delivered = deliveredByContainerType(
                                draft.containerDeliveries,
                              );
                              final hasContainers = delivered.isNotEmpty;
                              final visitId = draft.visitId;

                              final balances = balancesAsync.maybeWhen(
                                data: (list) => list,
                                orElse: () => <CustomerContainerBalance>[],
                              );
                              final hasActiveCustody = balances.any(
                                (b) => b.quantity > 0,
                              );

                              Future<void> handleCommit() async {
                                if (_busy) return;
                                setState(() => _busy = true);
                                try {
                                  await ref
                                      .read(saleDraftProvider.notifier)
                                      .commit();
                                } catch (e) {
                                  if (context.mounted) {
                                    setState(() => _busy = false);
                                    TopToast.showError(
                                      context,
                                      failureMessage(
                                        e,
                                        fallback:
                                            'No se guardó la venta. Reintentá.',
                                      ),
                                    );
                                  }
                                  return;
                                }
                                if (visitId != null) {
                                  ref.invalidate(
                                    visitMovementsProvider(visitId),
                                  );
                                }
                                if (context.mounted) {
                                  if (visitId != null) {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).pop();
                                  } else {
                                    Navigator.of(
                                      context,
                                    ).popUntil((route) => route.isFirst);

                                    // Show gorgeous premium top toast ONLY for general sales outside routes!
                                    TopToast.showSuccess(
                                      context,
                                      'Venta registrada con éxito',
                                    );
                                  }
                                }
                              }

                              if (hasContainers && hasActiveCustody) {
                                final custody = custodyByContainerType(
                                  balances,
                                );
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) => ContainerReturnDialog(
                                    containerTypes: [
                                      for (final type in containerTypes)
                                        if (delivered.containsKey(type.code))
                                          type,
                                    ],
                                    custody: custody,
                                    // Returned = delivered by default, capped at
                                    // what the customer actually holds.
                                    initialReturns: {
                                      for (final MapEntry(:key, :value)
                                          in delivered.entries)
                                        key:
                                            (draft.returnedContainers[key] ??
                                                    value)
                                                .clamp(0, custody[key] ?? 0),
                                    },
                                    title: 'Retorno de Envases',
                                    message:
                                        'Confirmá o ajustá la cantidad de envases retornados por el cliente.',
                                    confirmLabel: 'Confirmar',
                                    onConfirm: (adjustedReturns) async {
                                      Navigator.of(dialogContext).pop();
                                      for (final entry
                                          in adjustedReturns.entries) {
                                        ref
                                            .read(saleDraftProvider.notifier)
                                            .setReturnedQuantity(
                                              entry.key,
                                              entry.value,
                                            );
                                      }
                                      await handleCommit();
                                    },
                                  ),
                                );
                              } else {
                                for (final type in delivered.keys) {
                                  ref
                                      .read(saleDraftProvider.notifier)
                                      .setReturnedQuantity(type, 0);
                                }
                                await handleCommit();
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: tokens.primary,
                        disabledBackgroundColor: context.marilin.border,
                        minimumSize: const Size(0, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
