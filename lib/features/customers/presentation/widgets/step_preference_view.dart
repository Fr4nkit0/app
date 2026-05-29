import 'package:flutter/material.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';

class StepPreferenceView extends StatelessWidget {
  final List<CustomerPreference> preferences;
  final VoidCallback onAddPreference;
  final ValueChanged<String> onRemovePreference;
  final Function(
    String id, {
    int? dayOfWeek,
    String? timeWindowStart,
    String? timeWindowEnd,
  }) onPreferenceChanged;

  const StepPreferenceView({
    super.key,
    required this.preferences,
    required this.onAddPreference,
    required this.onRemovePreference,
    required this.onPreferenceChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferencias',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '¿Cuándo entregamos?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF9CA3AF),
                        ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: onAddPreference,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (preferences.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE0E0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFBF1B1B), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Agregá al menos un horario',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFBF1B1B),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            )
          else
            ...preferences.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PreferenceCard(
                    preference: p,
                    onRemove: () => onRemovePreference(p.id),
                    onChanged: (day, start, end) => onPreferenceChanged(
                      p.id,
                      dayOfWeek: day,
                      timeWindowStart: start,
                      timeWindowEnd: end,
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final CustomerPreference preference;
  final VoidCallback onRemove;
  final Function(int? day, String? start, String? end) onChanged;

  const _PreferenceCard({
    required this.preference,
    required this.onRemove,
    required this.onChanged,
  });

  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: preference.dayOfWeek,
                  onChanged: (val) => onChanged(val, null, null),
                  decoration: const InputDecoration(
                    labelText: 'Día',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: _inputBorder,
                    enabledBorder: _inputBorder,
                    focusedBorder: _focusedBorder,
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Lunes')),
                    DropdownMenuItem(value: 2, child: Text('Martes')),
                    DropdownMenuItem(value: 3, child: Text('Miércoles')),
                    DropdownMenuItem(value: 4, child: Text('Jueves')),
                    DropdownMenuItem(value: 5, child: Text('Viernes')),
                    DropdownMenuItem(value: 6, child: Text('Sábado')),
                    DropdownMenuItem(value: 7, child: Text('Domingo')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFBF1B1B),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Desde',
                  initialValue: preference.timeWindowStart,
                  onChanged: (val) => onChanged(null, val, null),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeField(
                  label: 'Hasta',
                  initialValue: preference.timeWindowEnd ?? '',
                  onChanged: (val) => onChanged(null, null, val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _TimeField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  static const _border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFFE5E7EB)),
  );

  static const _focusedBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: Color(0xFF1565C0), width: 2),
  );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: _border,
        enabledBorder: _border,
        focusedBorder: _focusedBorder,
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF1565C0),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
