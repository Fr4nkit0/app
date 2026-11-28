import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/core/utils/money_input.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

/// [amount] as the driver would type it: thousands grouped with dots.
String editableAmount(int amount) => formatMoneyInput(amount);

/// What the customer is left owing from a sale paid in part on the spot:
/// "Queda debiendo $X" or, when they already owed [previousDebt], that it
/// adds to it and the resulting debt (S11).
String unpaidNoteText(int unpaid, {int previousDebt = 0}) => previousDebt > 0
    ? 'Suma ${formatMoney(unpaid)} a su deuda de '
          '${formatMoney(previousDebt)}. '
          'Deuda total: ${formatMoney(previousDebt + unpaid)}'
    : 'Queda debiendo ${formatMoney(unpaid)}';

/// The question before saving a sale that leaves [unpaid] owed, added to
/// the [previousDebt] when there is one (S11).
String partialPaymentQuestion(int unpaid, {int previousDebt = 0}) =>
    previousDebt > 0
    ? '${unpaidNoteText(unpaid, previousDebt: previousDebt)}. ¿Confirmás?'
    : 'El cliente queda debiendo ${formatMoney(unpaid)}. ¿Confirmás?';

/// [unpaidNoteText]: what the customer is left owing from a sale paid in
/// part on the spot.
class UnpaidAmountNote extends StatelessWidget {
  const UnpaidAmountNote({
    super.key,
    required this.unpaid,
    this.previousDebt = 0,
  });

  final int unpaid;

  /// What the customer owed before this sale; 0 when nothing.
  final int previousDebt;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final color = context.marilin.warning;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              unpaidNoteText(unpaid, previousDebt: previousDebt),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
                fontFeatures: tokens.tabularStyle.fontFeatures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Debe $32.500 · si te da más, el resto va a la deuda": the customer's
/// previous debt next to the money received (S6), so the driver sees what
/// an amount above the sale pays.
class OwedDebtNote extends StatelessWidget {
  const OwedDebtNote({super.key, required this.owed});

  /// The customer's previous debt; above 0.
  final int owed;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final color = context.marilin.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Debe ${formatMoney(owed)} · si te da más, el resto va a la deuda',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: color,
                fontFeatures: tokens.tabularStyle.fontFeatures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Monto recibido": what the customer hands over on a cash or transfer
/// sale, starting at [initialAmount] (what is due of the sale). Below it
/// shows why the amount cannot be received ([errorText]) or, when [unpaid]
/// is above 0, what the customer is left owing, added to the [owedDebt]
/// when there is one (S11). When the customer owes [owedDebt],
/// it shows that debt and a «Cobrar toda la deuda» shortcut that fills
/// [payoffAmount] (the sale plus the whole debt).
///
/// Presentational: the caller owns the draft and the validation. Give it a
/// new key to start again from [initialAmount].
class CollectedAmountField extends StatefulWidget {
  const CollectedAmountField({
    super.key,
    required this.initialAmount,
    required this.unpaid,
    required this.onChanged,
    this.errorText,
    this.owedDebt = 0,
    this.payoffAmount = 0,
  });

  final int initialAmount;

  /// The customer's previous debt; no debt line or shortcut while it is 0.
  final int owedDebt;

  /// What «Cobrar toda la deuda» fills: the sale plus [owedDebt].
  final int payoffAmount;

  /// What the customer is left owing; nothing is shown while it is 0.
  final int unpaid;

  /// Why the typed amount cannot be received; null when it can.
  final String? errorText;

  /// The typed amount; null when it is not a valid number.
  final ValueChanged<int?> onChanged;

  @override
  State<CollectedAmountField> createState() => _CollectedAmountFieldState();
}

class _CollectedAmountFieldState extends State<CollectedAmountField> {
  late final _controller = TextEditingController(
    text: editableAmount(widget.initialAmount),
  );

  void _onChanged(String text) =>
      widget.onChanged(AmountField.parseAmount(text));

  void _collectAllDebt() {
    _controller.text = editableAmount(widget.payoffAmount);
    widget.onChanged(widget.payoffAmount);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final error = widget.errorText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AmountField(
          focusColor: tokens.primary,
          label: 'Monto recibido',
          controller: _controller,
          onChanged: _onChanged,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: tokens.destructive),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    error,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tokens.destructive,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (widget.unpaid > 0)
          UnpaidAmountNote(
            unpaid: widget.unpaid,
            previousDebt: widget.owedDebt,
          ),
        if (widget.owedDebt > 0) ...[
          OwedDebtNote(owed: widget.owedDebt),
          ActionChip(
            avatar: const Icon(Icons.price_check_rounded, size: 18),
            label: const Text('Cobrar toda la deuda'),
            onPressed: _collectAllDebt,
          ),
        ],
      ],
    );
  }
}

/// Asks before saving a sale that leaves the customer owing [unpaid], on
/// top of their [previousDebt] when they had one ([partialPaymentQuestion]).
/// Returns true when the driver confirms it.
Future<bool> confirmPartialPayment(
  BuildContext context,
  int unpaid, {
  int previousDebt = 0,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(
        partialPaymentQuestion(unpaid, previousDebt: previousDebt),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// Asks before saving money that leaves the customer with credit in their
/// favor (S6): [received] goes beyond [covered], the sale plus the whole
/// previous debt ([hasDebt]), and the customer is left with [credit].
/// Returns true when the driver keeps the credit on purpose.
Future<bool> confirmLeavingCredit(
  BuildContext context, {
  required int received,
  required int covered,
  required bool hasDebt,
  required int credit,
}) async {
  final target = hasDebt
      ? 'la venta más la deuda suman ${formatMoney(covered)}'
      : 'la venta suma ${formatMoney(covered)}';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Dejar saldo a favor?'),
      content: Text(
        'Recibiste ${formatMoney(received)} y $target. '
        'Le quedan ${formatMoney(credit)} a favor al cliente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Corregir monto'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Dejar a favor'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
