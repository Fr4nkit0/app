import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';

/// The day name of a preference day: 0 is Sunday ... 6 Saturday, as the
/// server stores it.
String preferenceDayName(int day) => switch (day) {
  0 => 'Domingo',
  1 => 'Lunes',
  2 => 'Martes',
  3 => 'Miércoles',
  4 => 'Jueves',
  5 => 'Viernes',
  6 => 'Sábado',
  _ => 'Día $day',
};

/// The window of [preference] as the driver reads it.
String preferenceWindowLabel(CustomerPreference preference) {
  final start = PreferenceDetails.hhmm(preference.timeWindowStart);
  final end = PreferenceDetails.hhmm(preference.timeWindowEnd);
  if (start == null || start == PreferenceDetails.noStart) {
    return end == null ? 'Todo el día' : 'hasta $end hs';
  }
  return end == null ? 'desde $start hs' : 'de $start a $end hs';
}

/// Opens the [PreferenceDialog]; returns `(day, start, end)` or null.
Future<(int, String, String)?> showPreferenceDialog(
  BuildContext context, {
  CustomerPreference? existing,
}) => showDialog<(int, String, String)>(
  context: context,
  builder: (_) => PreferenceDialog(existing: existing),
);

/// Picks the day and window of one delivery preference. Pops with
/// `(day, start, end)`, or null when cancelled.
class PreferenceDialog extends StatefulWidget {
  final CustomerPreference? existing;

  const PreferenceDialog({super.key, this.existing});

  @override
  State<PreferenceDialog> createState() => _PreferenceDialogState();
}

class _PreferenceDialogState extends State<PreferenceDialog> {
  late int _selectedDay;
  late String _startTime;
  late String _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.existing?.dayOfWeek ?? 1;
    _startTime = widget.existing?.timeWindowStart ?? '09:00';
    _endTime = widget.existing?.timeWindowEnd ?? '12:00';
  }

  /// Deliveries run Monday to Saturday; a preference the office set on
  /// Sunday is still listed so the dropdown can show it.
  Map<int, String> get _days => {
    for (final day in [1, 2, 3, 4, 5, 6, ?widget.existing?.dayOfWeek])
      day: preferenceDayName(day),
  };

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final parts = initial.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MarilinColors.brandBlue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = formatted;
        } else {
          _endTime = formatted;
        }
        _errorMessage = null;
      });
    }
  }

  bool _isValidTime() {
    final startParts = _startTime.split(':');
    final startHour = int.tryParse(startParts[0]) ?? 0;
    final startMinute = int.tryParse(startParts[1]) ?? 0;

    final endParts = _endTime.split(':');
    final endHour = int.tryParse(endParts[0]) ?? 0;
    final endMinute = int.tryParse(endParts[1]) ?? 0;

    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (endMinutes <= startMinutes) {
      return false;
    }

    // Lunes (1) a Viernes (5)
    if (_selectedDay >= 1 && _selectedDay <= 5) {
      return startHour >= 9 && endHour <= 18;
    }
    // Sábado (6)
    if (_selectedDay == 6) {
      return startHour >= 9 && endHour <= 15;
    }
    // Domingo (7) - No deliveries
    return false;
  }

  void _save() {
    if (!_isValidTime()) {
      setState(() {
        _errorMessage =
            'Horario inválido. La hora "Hasta" debe ser posterior a "Desde". L a V: 9-18hs, Sáb: 9-15hs';
      });
      return;
    }
    Navigator.of(context).pop((_selectedDay, _startTime, _endTime));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'Editar horario' : 'Agregar Preferencia Horaria',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.marilin.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<int>(
              initialValue: _selectedDay,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDay = val;
                    _errorMessage = null;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Día de entrega',
                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                filled: true,
                fillColor: context.marilin.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: context.marilin.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(
                    color: MarilinColors.brandBlue,
                    width: 2,
                  ),
                ),
              ),
              items: _days.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _TimeSelector(
                    label: 'Desde',
                    time: _startTime,
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeSelector(
                    label: 'Hasta',
                    time: _endTime,
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.marilin.soft(
                    MarilinColors.destructive.withValues(alpha: 0.12),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.marilin.soft(
                      MarilinColors.destructive.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: MarilinColors.destructive,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        //foregroundBuilder: Colors.,
                        //backgroundColor: const context.marilin.border,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: MarilinColors.brandBlue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Guardar cambios' : 'Agregar horario',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time_rounded, size: 18),
          filled: true,
          fillColor: context.marilin.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            borderSide: BorderSide(color: context.marilin.border),
          ),
        ),
        child: Text(
          time,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
