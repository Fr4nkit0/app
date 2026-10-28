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

  @override
  Widget build(BuildContext context) {
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
