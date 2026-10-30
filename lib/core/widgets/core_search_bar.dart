import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

class CoreSearchBar extends StatelessWidget {
  const CoreSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText,
    this.focusedBorderColor,
    this.fillColor,
    this.prefixIcon,
    this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? hintText;
  final Color? focusedBorderColor;
  final Color? fillColor;
  final Widget? prefixIcon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText ?? 'Buscar por nombre, teléfono o dirección...',
        hintStyle: TextStyle(color: context.marilin.inkHint, fontSize: 14),
        prefixIcon:
            prefixIcon ??
            Icon(Icons.search, color: context.marilin.inkHint, size: 20),
        suffixIcon: onClear != null
            ? IconButton(
                tooltip: 'Limpiar búsqueda',
                icon: Icon(
                  Icons.clear,
                  color: context.marilin.textMuted,
                  size: 20,
                ),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: fillColor ?? context.marilin.fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: focusedBorderColor ?? MarilinColors.brandBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
