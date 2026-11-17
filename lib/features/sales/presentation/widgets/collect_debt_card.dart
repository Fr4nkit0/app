import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/features/payments/presentation/widgets/amount_field.dart';

/// [amount] as the driver would type it: no decimals when whole.
String editableAmount(double amount) => amount == amount.roundToDouble()
    ? amount.toStringAsFixed(0)
    : amount.toStringAsFixed(2);

/// "Cobrar también la deuda": a switch that adds [currentDebt] (or part of
/// it) to the sale being paid, and the amount field shown while it is on.
///
/// Presentational: the caller owns the draft and the validation; this only
/// shows [amount] when switched on and reports edits.
class CollectDebtCard extends StatefulWidget {
  const CollectDebtCard({
    super.key,
    required this.currentDebt,
    required this.enabled,
    required this.amount,
    required this.onToggle,
    required this.onAmountChanged,
    this.errorText,
  });

  /// What the customer owes now.
  final double currentDebt;

  /// Whether the debt is collected with the sale.
  final bool enabled;

  /// The debt amount the draft holds; written into the field when the
  /// switch turns on.
  final double? amount;

  /// Why the typed amount cannot be collected; null when it can.
  final String? errorText;

  final ValueChanged<bool> onToggle;

  /// The typed amount; null when it is not a valid number.
  final ValueChanged<double?> onAmountChanged;

  @override
  State<CollectDebtCard> createState() => _CollectDebtCardState();
}

class _CollectDebtCardState extends State<CollectDebtCard> {
  late final _controller = TextEditingController(
    text: widget.enabled && widget.amount != null
        ? editableAmount(widget.amount!)
        : '',
  );

  @override
  void didUpdateWidget(CollectDebtCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Switching on starts at the amount the draft chose (the whole debt).
    if (!oldWidget.enabled && widget.enabled) {
      _controller.text = editableAmount(widget.amount ?? widget.currentDebt);
    }
  }

  void _onChanged(String text) {
    // A trailing separator is a number still being typed: "72." is 72.
    final inProgress = text.endsWith(',') || text.endsWith('.');
    final amount = AmountField.parseAmount(
      inProgress ? text.substring(0, text.length - 1) : text,
    );
    widget.onAmountChanged(amount);
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
    return Container(
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.marilin.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            value: widget.enabled,
            onChanged: widget.onToggle,
            activeThumbColor: Colors.white,
            activeTrackColor: tokens.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              'Cobrar también la deuda',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.marilin.ink,
              ),
            ),
            subtitle: Text(
              'Deuda actual ${formatMoney(widget.currentDebt)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.marilin.textMuted,
                fontFeatures: tokens.tabularStyle.fontFeatures,
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: widget.enabled
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AmountField(
                          focusColor: tokens.primary,
                          label: 'Deuda a cobrar',
                          controller: _controller,
                          onChanged: _onChanged,
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 16,
                                  color: tokens.destructive,
                                ),
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
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
