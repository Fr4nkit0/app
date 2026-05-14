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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
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
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¿Cuándo entregamos?',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: onAddPreference,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Agregar horario',
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...preferences.map((preference) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _PreferenceCard(
                  preference: preference,
                  onRemove: () => onRemovePreference(preference.id),
                  onChanged: (day, start, end) => onPreferenceChanged(
                    preference.id,
                    dayOfWeek: day,
                    timeWindowStart: start,
                    timeWindowEnd: end,
                  ),
                ),
              )),
          if (preferences.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'Agregá al menos un horario de entrega',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final CustomerPreference preference;
  final VoidCallback onRemove;
  final Function(int? day, String? timeWindowStart, String? timeWindowEnd) onChanged;

  const _PreferenceCard({
    required this.preference,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: preference.dayOfWeek,
                    onChanged: (val) => onChanged(val, null, null),
                    decoration: InputDecoration(
                      labelText: 'Día',
                      prefixIcon: const Icon(Icons.calendar_today_rounded),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
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
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: colorScheme.error,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Desde',
                    initialValue: preference.timeWindowStart,
                    onChanged: (val) => onChanged(null, val, null),
                  ),
                ),
                const SizedBox(width: 12),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.access_time_rounded),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
