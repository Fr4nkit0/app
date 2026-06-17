import 'package:flutter/material.dart';

class StepIdentityView extends StatelessWidget {
  final String name;
  final String phone;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;

  const StepIdentityView({
    super.key,
    required this.name,
    required this.phone,
    required this.onNameChanged,
    required this.onPhoneChanged,
  });

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
  );
  static const _focusBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
  );
  static const _errorBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFFBF1B1B)),
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ingresá los datos de contacto.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 28),
          TextFormField(
            initialValue: name,
            onChanged: onNameChanged,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'El nombre es requerido' : null,
            decoration: const InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Ej. Juan Pérez',
              prefixIcon: Icon(Icons.person_outline, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: _border,
              enabledBorder: _border,
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
            decoration: const InputDecoration(
              labelText: 'Teléfono (opcional)',
              hintText: 'Ej. 387-555-0101',
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: _border,
              enabledBorder: _border,
              focusedBorder: _focusBorder,
            ),
          ),
        ],
      ),
    );
  }
}
