import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/features/customers/presentation/widgets/address_picker_map.dart';

class StepAddressView extends StatelessWidget {
  final String street;
  final String apartment;
  final String floor;
  final String visualReference;
  final double? latitude;
  final double? longitude;
  final ValueChanged<String> onStreetChanged;
  final ValueChanged<String> onApartmentChanged;
  final ValueChanged<String> onFloorChanged;
  final ValueChanged<String> onVisualReferenceChanged;
  final void Function(double? lat, double? lng) onCoordinatesChanged;

  const StepAddressView({
    super.key,
    required this.street,
    required this.apartment,
    required this.floor,
    required this.visualReference,
    this.latitude,
    this.longitude,
    required this.onStreetChanged,
    required this.onApartmentChanged,
    required this.onFloorChanged,
    required this.onVisualReferenceChanged,
    required this.onCoordinatesChanged,
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

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (context) => AddressPickerMap(
          initialLatitude: latitude,
          initialLongitude: longitude,
          initialSearchQuery: street.isNotEmpty ? street : null,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      onCoordinatesChanged(result.latitude, result.longitude);
    }
  }

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
              labelText: 'Calle y altura / Manzana',
              hintText: 'Ej. San Martín 1234 o Mza 45',
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
            decoration: _decoration.copyWith(
              labelText: 'Referencia visual (opcional)',
              hintText: 'Ej. Portón negro, rejas blancas',
              prefixIcon: const Icon(Icons.remove_red_eye_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Ubicación Satelital',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (latitude != null && longitude != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ubicación fijada\n(${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)})',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF9CA3AF), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Sin ubicación en el mapa',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _openMapPicker(context),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text(
                  latitude != null && longitude != null
                      ? 'Cambiar'
                      : 'Ubicar en Mapa',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  side: const BorderSide(color: Color(0xFF1565C0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(0, 44),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
