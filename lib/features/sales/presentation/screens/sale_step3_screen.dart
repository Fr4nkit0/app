import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/core/widgets/core_horizontal_stepper.dart';

class SaleStep3Screen extends ConsumerWidget {
  const SaleStep3Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(saleDraftProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CoreHorizontalStepper(
                        steps: ['Pedido', 'Cobro'],
                        stepDescriptions: ['Elegir productos', 'Registrar pago'],
                        layoutRow: true,
                        currentStep: 1,
                      ),
                    ),
                    // Previous debt chip (display-only, never mutates debtAmount)
                    if ((draft.customer?.debtAmount ?? 0) > 0)
                      DebtChip(
                        amount: draft.customer!.debtAmount,
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        borderRadius: BorderRadius.circular(10),
                        backgroundColor: Theme.of(context).extension<SalesTokens>()!.destructive.withValues(alpha: 0.08),
                        borderColor: Theme.of(context).extension<SalesTokens>()!.destructive.withValues(alpha: 0.3),
                        borderWidth: 1.0,
                        textColor: Theme.of(context).extension<SalesTokens>()!.destructive,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        icon: Icons.warning_amber_rounded,
                        iconSize: 16,
                        iconColor: Theme.of(context).extension<SalesTokens>()!.destructive,
                        prefixText: 'Deuda previa: \$',
                      ),
                    // Client + order summary card
                    _ClientCard(draft: draft),
                    const SizedBox(height: 20),
                    // Payment method grid + mixed fields
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel('FORMA DE PAGO'),
                          const SizedBox(height: 10),
                          _PaymentGrid(draft: draft),
                          const SizedBox(height: 12),
                          // Progressive-disclosure mixed amounts
                          _MixedAmountsSection(draft: draft),
                          // Live remaining indicator
                          if (draft.paymentMethod == PaymentMethod.mixed)
                            _RemainingIndicator(draft: draft),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _Footer(draft: draft),
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

// ─── Client + order summary card ──────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 15, color: tokens.primary),
              const SizedBox(width: 6),
              Text(
                draft.customer?.name ?? '',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...draft.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.water_drop_outlined,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${item.quantity}× ${item.product.name}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '\$${item.subtotal.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: tokens.tabularStyle.fontFeatures,
                          ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary)),
              Text(
                '\$${draft.total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: tokens.primary,
                  fontSize: 17,
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

// ─── 2×2 Payment grid ─────────────────────────────────────────────────────────

class _PaymentGrid extends ConsumerWidget {
  const _PaymentGrid({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
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
    final brandColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(method.icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              method.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : brandColor,
              ),
            ),
          ],
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

class _MixedAmountsSectionState
    extends ConsumerState<_MixedAmountsSection> {
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
    final cash = double.tryParse(value);
    final transfer = double.tryParse(_transferController.text);
    ref
        .read(saleDraftProvider.notifier)
        .setMixedAmounts(cash: cash, transfer: transfer);
  }

  void _onTransferChanged(String value) {
    final cash = double.tryParse(_cashController.text);
    final transfer = double.tryParse(value);
    ref
        .read(saleDraftProvider.notifier)
        .setMixedAmounts(cash: cash, transfer: transfer);
  }

  @override
  Widget build(BuildContext context) {
    final isMixed = widget.draft.paymentMethod == PaymentMethod.mixed;

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
                  _AmountField(
                    label: 'Efectivo',
                    controller: _cashController,
                    onChanged: _onCashChanged,
                  ),
                  const SizedBox(height: 10),
                  _AmountField(
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

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixText: '\$ ',
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
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
            isCovered
                ? '✓ Cubierto'
                : 'Falta: \$${remaining.toStringAsFixed(2)}',
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Footer with "Confirmar" button ──────────────────────────────────────────

class _Footer extends ConsumerWidget {
  const _Footer({required this.draft});

  final SaleDraftState draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
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
      child: Row(
        children: [
          // Botón Atrás
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1.5),
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Atrás',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          // Botón Confirmar — gated by canConfirm (REQ-COB-06)
          Expanded(
            flex: 6,
            child: FilledButton(
              onPressed: draft.canConfirm
                  ? () async {
                      final visitId = draft.visitId;
                      await ref.read(saleDraftProvider.notifier).commit();
                      if (context.mounted) {
                        if (visitId != null) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                          
                          // Show gorgeous premium top toast ONLY for general sales outside routes!
                          TopToast.showSuccess(context, 'Venta registrada con éxito');
                        }
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.primary,
                disabledBackgroundColor: Colors.grey.shade200,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Confirmar',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
