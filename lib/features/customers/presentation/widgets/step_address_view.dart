import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/presentation/widgets/neighborhood_search_bottom_sheet.dart';

class StepAddressView extends StatelessWidget {
  final String street;
  final String neighborhood;
  final String apartment;
  final String floor;
  final String visualReference;
  final ValueChanged<String> onStreetChanged;
  final ValueChanged<String> onNeighborhoodChanged;
  final ValueChanged<String> onApartmentChanged;
  final ValueChanged<String> onFloorChanged;
  final ValueChanged<String> onVisualReferenceChanged;

  const StepAddressView({
    super.key,
    required this.street,
    required this.neighborhood,
    required this.apartment,
    required this.floor,
    required this.visualReference,
    required this.onStreetChanged,
    required this.onNeighborhoodChanged,
    required this.onApartmentChanged,
    required this.onFloorChanged,
    required this.onVisualReferenceChanged,
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

  /// The form's fields, in the current theme's colors.
  static InputDecoration _decoration(BuildContext context) => InputDecoration(
    filled: true,
    fillColor: context.marilin.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: _border(context),
    enabledBorder: _border(context),
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
          Text(
            '¿Dónde hacemos las entregas?',
            style: TextStyle(color: context.marilin.inkHint, fontSize: 14),
          ),
          const SizedBox(height: 28),
          TextFormField(
            initialValue: street,
            onChanged: onStreetChanged,
            textCapitalization: TextCapitalization.words,
            // The neighborhood is picked from a list, so the keyboard skips it.
            textInputAction: TextInputAction.next,
            autofocus: true,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'La calle es requerida' : null,
            decoration: _decoration(context).copyWith(
              labelText: 'Calle y altura / Manzana',
              hintText: 'Ej. San Martín 1234 o Mza 45',
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          FormField<String>(
            key: ValueKey(neighborhood),
            initialValue: neighborhood.isEmpty ? null : neighborhood,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'El barrio es requerido' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            builder: (FormFieldState<String> fieldState) {
              return GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (context) => NeighborhoodSearchBottomSheet(
                      onSelected: (val) {
                        onNeighborhoodChanged(val);
                        fieldState.didChange(val);
                      },
                    ),
                  );
                },
                child: InputDecorator(
                  decoration: _decoration(context).copyWith(
                    labelText: 'Barrio',
                    hintText: 'Seleccionar barrio',
                    prefixIcon: const Icon(Icons.home_work_outlined, size: 20),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    errorText: fieldState.errorText,
                  ),
                  child: Text(
                    neighborhood.isEmpty
                        ? 'Seleccionar barrio...'
                        : neighborhood,
                    style: TextStyle(
                      fontSize: 16,
                      color: neighborhood.isEmpty
                          ? context.marilin.inkHint
                          : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: floor,
                  onChanged: onFloorChanged,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    context,
                  ).copyWith(labelText: 'Piso', hintText: 'Ej. 3'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: apartment,
                  onChanged: onApartmentChanged,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _decoration(context).copyWith(
                    labelText: 'Depto / Lote',
                    hintText: 'Ej. A o Lote 12',
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
            decoration: _decoration(context).copyWith(
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
