import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/core/theme/marilin_tokens.dart';

/// Decimal amount input with a `$` prefix, shared by every payment form.
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

  static final _validAmount = RegExp(r'^\d+([.,]\d{1,2})?$');

  /// Parses an amount typed with either `,` or `.` as the decimal separator.
  /// Returns null for empty or invalid input.
  static double? parseAmount(String text) {
    final trimmed = text.trim();
    if (!_validAmount.hasMatch(trimmed)) return null;
    return double.tryParse(trimmed.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => _buildField(context, value.text),
    );
  }

  Widget _buildField(BuildContext context, String text) {
    // A trailing separator is a number still being typed, not a mistake.
    final inProgress = text.endsWith(',') || text.endsWith('.');
    final isInvalid =
        text.isNotEmpty && !inProgress && parseAmount(text) == null;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
      ],
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
