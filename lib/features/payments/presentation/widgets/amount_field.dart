import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/money_input.dart';

/// Whole-peso amount input, grouped by thousands while typing with a `$` prefix, shared by every payment form.
class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.focusColor = MarilinColors.brandBlue,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final Color focusColor;

  /// Parses an amount in whole pesos; dots are thousands separators
  /// ("15.000" -> 15000). Returns null for empty or invalid input.
  static int? parseAmount(String text) => parseMoneyInput(text);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => _buildField(context, value.text),
    );
  }

  Widget _buildField(BuildContext context, String text) {
    final isInvalid = text.isNotEmpty && parseAmount(text) == null;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: const [MoneyInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        errorText: isInvalid ? 'Ingresá un monto válido' : null,
        prefixText: '\$ ',
        filled: true,
        fillColor: context.marilin.fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.marilin.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.marilin.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: focusColor, width: 1.5),
        ),
      ),
    );
  }
}
