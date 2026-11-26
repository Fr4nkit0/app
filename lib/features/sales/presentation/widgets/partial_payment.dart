import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

/// [amount] as the driver would type it: no decimals when whole.
String editableAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

/// "Queda debiendo $X": what the customer is left owing from a sale paid
/// in part on the spot.
class UnpaidAmountNote extends StatelessWidget {
  const UnpaidAmountNote({super.key, required this.unpaid});

  final double unpaid;

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
              'Queda debiendo ${formatMoney(unpaid)}',
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

/// "Monto recibido": what the customer hands over on a cash or transfer
/// sale, starting at [initialAmount] (the sale total). Below it shows why
/// the amount cannot be received ([errorText]) or, when [unpaid] is above
/// 0, what the customer is left owing.
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
  });

  final double initialAmount;

  /// What the customer is left owing; nothing is shown while it is 0.
  final double unpaid;

  /// Why the typed amount cannot be received; null when it can.
  final String? errorText;

  /// The typed amount; null when it is not a valid number.
  final ValueChanged<double?> onChanged;

  @override
  State<CollectedAmountField> createState() => _CollectedAmountFieldState();
}

class _CollectedAmountFieldState extends State<CollectedAmountField> {
  late final _controller = TextEditingController(
    text: editableAmount(widget.initialAmount),
  );

  void _onChanged(String text) {
    // A trailing separator is a number still being typed: "60." is 60.
    final inProgress = text.endsWith(',') || text.endsWith('.');
    widget.onChanged(
      AmountField.parseAmount(
        inProgress ? text.substring(0, text.length - 1) : text,
      ),
    );
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
          UnpaidAmountNote(unpaid: widget.unpaid),
      ],
    );
  }
}

/// Asks before saving a sale that leaves the customer owing [unpaid].
/// Returns true when the driver confirms it.
Future<bool> confirmPartialPayment(BuildContext context, double unpaid) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Text(
        'El cliente queda debiendo ${formatMoney(unpaid)}. ¿Confirmás?',
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
