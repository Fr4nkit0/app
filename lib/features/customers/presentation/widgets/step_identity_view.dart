import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';

class StepIdentityView extends StatelessWidget {
  final String name;
  final String phone;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;

  /// The keyboard's next action on the phone, the last field of this step.
  final VoidCallback onPhoneSubmitted;

  const StepIdentityView({
    super.key,
    required this.name,
    required this.phone,
    required this.onNameChanged,
    required this.onPhoneChanged,
    required this.onPhoneSubmitted,
  });

  static OutlineInputBorder _border(BuildContext context) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: context.marilin.border),
  );
  static const _focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: MarilinColors.brandBlue, width: 2),
  );
  static const _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: MarilinColors.destructive),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Datos del cliente',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresá los datos de contacto.',
            style: TextStyle(color: context.marilin.inkHint, fontSize: 14),
          ),
          const SizedBox(height: 28),
          TextFormField(
            initialValue: name,
            onChanged: onNameChanged,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Ej. Juan Pérez',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              filled: true,
              fillColor: context.marilin.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: _border(context),
              enabledBorder: _border(context),
              focusedBorder: _focusBorder,
              errorBorder: _errorBorder,
              focusedErrorBorder: _errorBorder,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: phone,
            onChanged: onPhoneChanged,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onEditingComplete: () {
              // Frees the focus so the next step's first field can take it.
              FocusScope.of(context).unfocus();
              onPhoneSubmitted();
            },
            decoration: InputDecoration(
              labelText: 'Teléfono (opcional)',
              hintText: 'Ej. 387-555-0101',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              filled: true,
              fillColor: context.marilin.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: _border(context),
              enabledBorder: _border(context),
              focusedBorder: _focusBorder,
            ),
          ),
        ],
      ),
    );
  }
}
