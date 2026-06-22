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

  static const _decoration = InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: _border,
    enabledBorder: _border,
    focusedBorder: _focusBorder,
    errorBorder: _errorBorder,
    focusedErrorBorder: _errorBorder,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dirección',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            '¿Dónde hacemos las entregas?',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 28),
          TextFormField(
            initialValue: street,
            onChanged: onStreetChanged,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'La calle es requerida' : null,
            decoration: _decoration.copyWith(
              labelText: 'Calle y altura',
              hintText: 'Ej. San Martín 1234',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: floor,
                  onChanged: onFloorChanged,
                  keyboardType: TextInputType.number,
                  decoration: _decoration.copyWith(
                    labelText: 'Piso',
                    hintText: 'Ej. 3',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: apartment,
                  onChanged: onApartmentChanged,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration.copyWith(
                    labelText: 'Depto',
                    hintText: 'Ej. A',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: visualReference,
            onChanged: onVisualReferenceChanged,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration.copyWith(
              labelText: 'Referencia visual (opcional)',
              hintText: 'Ej. Portón negro, rejas blancas',
              prefixIcon: const Icon(Icons.remove_red_eye_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
