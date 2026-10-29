import 'package:app/core/utils/money_formatter.dart';
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
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';

import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

class SaleStep3Screen extends ConsumerWidget {
  const SaleStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(saleDraftProvider);

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
                          _TotalBlock(draft: draft),
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
                                // Progressive-disclosure mixed amounts
                                _MixedAmountsSection(draft: draft),
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Footer(draft: draft),
          SizedBox(height: bottomInset),
        ],
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
  const _TotalBlock({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final muted = context.marilin.textMuted;
    final debt = draft.customer?.debtAmount ?? 0;
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
          // Previous debt is context, display-only (never mutates debtAmount)
          if (debt > 0)
            Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: muted),
                const SizedBox(width: 6),
                Text(
                  'Debe ${formatMoney(debt)} de antes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
            ),
        ],
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
  const _MixedAmountsSection({required this.draft});

  final SaleDraftState draft;

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

  void _fillAll({required bool cash}) {
    final total = widget.draft.total;
    final text = total == total.roundToDouble()
        ? total.toStringAsFixed(0)
        : total.toStringAsFixed(2);
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
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final remaining = draft.remaining;
    final isCovered = remaining.abs() <= 0.01;

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
  const _Footer({required this.draft});

  final SaleDraftState draft;

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
      child: Row(
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
                  customerContainerBalancesProvider(draft.customer?.id ?? ''),
                );

                return FilledButton(
                  onPressed: draft.canConfirm && !_busy
                      ? () async {
                          final hasContainers = draft.items.any(
                            (item) => item.product.containerType != null,
                          );
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
                            } catch (_) {
                              if (context.mounted) {
                                setState(() => _busy = false);
                                TopToast.showError(
                                  context,
                                  'No se guardó la venta. Reintentá.',
                                );
                              }
                              return;
                            }
                            if (visitId != null) {
                              ref.invalidate(visitMovementsProvider(visitId));
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
                            final customerBalancesMap = {
                              for (final b in balances)
                                b.containerType: b.quantity,
                            };
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) =>
                                  ContainerReturnConfirmationDialog(
                                    items: draft.items,
                                    initialReturns: draft.returnedContainers,
                                    customerBalances: customerBalancesMap,
                                    onConfirm: (adjustedReturns) async {
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
                            if (hasContainers) {
                              for (final type in ['BIDON_20L', 'SIFON_2L']) {
                                ref
                                    .read(saleDraftProvider.notifier)
                                    .setReturnedQuantity(type, 0);
                              }
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
    );
  }
}

// ─── Container Return Confirmation Dialog ─────────────────────────────────────

class ContainerReturnConfirmationDialog extends StatefulWidget {
  const ContainerReturnConfirmationDialog({
    super.key,
    required this.items,
    required this.initialReturns,
    required this.customerBalances,
    required this.onConfirm,
  });

  final List<SaleItem> items;
  final Map<String, int> initialReturns;
  final Map<String, int> customerBalances;
  final ValueChanged<Map<String, int>> onConfirm;

  @override
  State<ContainerReturnConfirmationDialog> createState() =>
      _ContainerReturnConfirmationDialogState();
}

class _ContainerReturnConfirmationDialogState
    extends State<ContainerReturnConfirmationDialog> {
  late Map<String, int> _returns;

  @override
  void initState() {
    super.initState();
    _returns = Map<String, int>.from(widget.initialReturns);
    // If the customer has no active balance of a container type,
    // default its return value to 0 since they don't have containers to return yet.
    for (final type in ['BIDON_20L', 'SIFON_2L']) {
      final balance = widget.customerBalances[type] ?? 0;
      if (balance == 0) {
        _returns[type] = 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final containerTypes = <String>[];
    for (final type in ['BIDON_20L', 'SIFON_2L']) {
      final delivered = widget.items
          .where((item) => item.product.containerType == type)
          .fold(0, (sum, item) => sum + item.quantity);
      if (delivered > 0) {
        containerTypes.add(type);
        final balance = widget.customerBalances[type] ?? 0;
        // Fallback default setup
        _returns[type] ??= (balance > 0 ? delivered : 0);
      }
    }

    final tokens = Theme.of(context).extension<SalesTokens>()!;

    return AlertDialog(
      title: const Text(
        'Retorno de Envases',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmá o ajustá la cantidad de envases retornados por el cliente.',
              style: TextStyle(color: context.marilin.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...containerTypes.map((type) {
              final delivered = widget.items
                  .where((item) => item.product.containerType == type)
                  .fold(0, (sum, item) => sum + item.quantity);
              final returned = _returns[type] ?? delivered;
              final balance = widget.customerBalances[type] ?? 0;
              final maxReturns = balance;
              final label = type == 'BIDON_20L' ? 'Bidón 20L' : 'Sifón 1.5L';

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
                          tooltip: 'Restar',
                          onPressed: returned > 0
                              ? () {
                                  setState(() {
                                    _returns[type] = returned - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: tokens.destructive,
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
                          tooltip: 'Sumar',
                          onPressed: returned < maxReturns
                              ? () {
                                  setState(() {
                                    _returns[type] = returned + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: tokens.primary,
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
          onPressed: () {
            widget.onConfirm(_returns);
            Navigator.of(context).pop();
          },
          style: FilledButton.styleFrom(backgroundColor: tokens.primary),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
