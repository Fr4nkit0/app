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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Datos Personales',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresá los datos de contacto del cliente.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: name,
            onChanged: onNameChanged,
            decoration: const InputDecoration(
              labelText: 'Nombre Completo',
              hintText: 'Ej. Juan Pérez',
              prefixIcon: Icon(Icons.person_outline),
              filled: true,
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El nombre es requerido';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: phone,
            onChanged: onPhoneChanged,
            decoration: const InputDecoration(
              labelText: 'Teléfono (Opcional)',
              hintText: 'Ej. 1122334455',
              prefixIcon: Icon(Icons.phone_outlined),
              filled: true,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
