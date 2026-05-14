import 'package:flutter/material.dart';

class StepAddressView extends StatelessWidget {
  final String street;
  final String apartment;
  final String floor;
  final String visualReference;
  final ValueChanged<String> onStreetChanged;
  final ValueChanged<String> onApartmentChanged;
  final ValueChanged<String> onFloorChanged;
  final ValueChanged<String> onVisualReferenceChanged;

  const StepAddressView({
    super.key,
    required this.street,
    required this.apartment,
    required this.floor,
    required this.visualReference,
    required this.onStreetChanged,
    required this.onApartmentChanged,
    required this.onFloorChanged,
    required this.onVisualReferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dirección',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '¿Dónde realizamos las entregas?',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            initialValue: street,
            onChanged: onStreetChanged,
            decoration: const InputDecoration(
              labelText: 'Calle y Altura',
              hintText: 'Ej. San Martín 1234',
              prefixIcon: Icon(Icons.location_on_outlined),
              filled: true,
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La calle es requerida';
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: floor,
                  onChanged: onFloorChanged,
                  decoration: const InputDecoration(
                    labelText: 'Piso',
                    hintText: 'Ej. 3',
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: apartment,
                  onChanged: onApartmentChanged,
                  decoration: const InputDecoration(
                    labelText: 'Depto',
                    hintText: 'Ej. A',
                    filled: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            initialValue: visualReference,
            onChanged: onVisualReferenceChanged,
            decoration: const InputDecoration(
              labelText: 'Referencia visual (Opcional)',
              hintText: 'Ej. Rejas negras, portón blanco',
              prefixIcon: Icon(Icons.remove_red_eye_outlined),
              filled: true,
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
