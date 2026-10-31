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

/// Saves the window picked in the [PreferenceDialog]: completes with null
/// when stored, or with the reason it was refused.
typedef PreferenceSaver =
    Future<String?> Function(int day, String start, String end);

/// Opens the [PreferenceDialog]; completes with whether [onSave] stored the
/// preference.
Future<bool> showPreferenceDialog(
  BuildContext context, {
  CustomerPreference? existing,
  required PreferenceSaver onSave,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => PreferenceDialog(existing: existing, onSave: onSave),
    ) ??
    false;

/// Picks the day and window of one delivery preference and hands it to
/// [onSave]. Stays open showing the reason when it is refused, so the driver
/// can change it; pops with true once saved, or false when cancelled.
class PreferenceDialog extends StatefulWidget {
  final CustomerPreference? existing;
  final PreferenceSaver onSave;

  const PreferenceDialog({super.key, this.existing, required this.onSave});

  @override
  State<PreferenceDialog> createState() => _PreferenceDialogState();
}

class _PreferenceDialogState extends State<PreferenceDialog> {
  static const _endNotAfterStart =
      'La hora "Hasta" tiene que ser posterior a "Desde".';

  late int _selectedDay;
  late String _startTime;
  late String _endTime;
  String? _errorMessage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _selectedDay = existing?.dayOfWeek ?? 1;
    _startTime = PreferenceDetails.hhmm(existing?.timeWindowStart) ?? '09:00';
    _endTime = PreferenceDetails.hhmm(existing?.timeWindowEnd) ?? '12:00';
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
      // Flutter's es_AR bundle says "Selecciona" and "ACEPTAR".
      helpText: 'Elegí la hora',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MarilinColors.brandBlue,
            ),
          ),
          child: MediaQuery(
            data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
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

  /// Mirrors the server: the window only has to end after it starts.
  /// `HH:mm` strings compare in time order.
  bool get _endsAfterStart => _endTime.compareTo(_startTime) > 0;

  Future<void> _save() async {
    if (!_endsAfterStart) {
      setState(() => _errorMessage = _endNotAfterStart);
      return;
    }
    setState(() {
      _saving = true;
      _errorMessage = null;
    });
    final error = await widget.onSave(_selectedDay, _startTime, _endTime);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                Expanded(
                  child: Text(
                    isEdit ? 'Editar horario' : 'Agregar Preferencia Horaria',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.marilin.ink,
                    ),
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
            // Side by side when both labels fit, stacked otherwise, so a
            // label never touches its button edges.
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 12,
              overflowSpacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              overflowDirection: VerticalDirection.up,
              children: [
                OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: MarilinColors.brandBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
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
              ],
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
