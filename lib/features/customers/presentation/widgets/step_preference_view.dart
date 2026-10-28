import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
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
  })
  onPreferenceChanged;
  final void Function(int day, String start, String end) onNewPreferenceSaved;

  const StepPreferenceView({
    super.key,
    required this.preferences,
    required this.onAddPreference,
    required this.onRemovePreference,
    required this.onPreferenceChanged,
    required this.onNewPreferenceSaved,
  });

  static const _days = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
  };

  void _openPreferenceModal(
    BuildContext context, {
    CustomerPreference? existing,
  }) {
    showDialog<(int, String, String)>(
      context: context,
      builder: (ctx) => _PreferenceDialog(existing: existing),
    ).then((result) {
      if (result != null) {
        if (existing != null) {
          onPreferenceChanged(
            existing.id,
            dayOfWeek: result.$1,
            timeWindowStart: result.$2,
            timeWindowEnd: result.$3,
          );
        } else {
          onNewPreferenceSaved(result.$1, result.$2, result.$3);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preferencias',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            '¿Cuándo entregamos?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.marilin.inkHint),
          ),
          const SizedBox(height: 20),
          if (preferences.isEmpty)
            _EmptyState(onAdd: () => _openPreferenceModal(context))
          else
            ...preferences.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PreferenceSummaryCard(
                  preference: p,
                  dayLabel: _days[p.dayOfWeek] ?? 'Día $p.dayOfWeek',
                  onTap: () => _openPreferenceModal(context, existing: p),
                  onRemove: () => onRemovePreference(p.id),
                ),
              ),
            ),
          const SizedBox(height: 16),
          _AddButton(onTap: () => _openPreferenceModal(context)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.marilin.soft(
            MarilinColors.brandBlue.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: context.marilin.soft(
              MarilinColors.brandBlue.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 32,
              color: MarilinColors.brandBlue.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              'Tocá para agregar un horario de entrega',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: MarilinColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: MarilinColors.brandBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MarilinColors.brandBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: MarilinColors.brandBlue, size: 20),
            const SizedBox(width: 6),
            Text(
              'Agregar otro horario',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: MarilinColors.brandBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceSummaryCard extends StatelessWidget {
  final CustomerPreference preference;
  final String dayLabel;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PreferenceSummaryCard({
    required this.preference,
    required this.dayLabel,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.marilin.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.marilin.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MarilinColors.brandBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.schedule_rounded,
                size: 22,
                color: MarilinColors.brandBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: context.marilin.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${preference.timeWindowStart} — ${preference.timeWindowEnd ?? '--:--'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.marilin.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Quitar',
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.marilin.soft(
                      MarilinColors.destructive.withValues(alpha: 0.12),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: MarilinColors.destructive,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceDialog extends StatefulWidget {
  final CustomerPreference? existing;

  const _PreferenceDialog({this.existing});

  @override
  State<_PreferenceDialog> createState() => _PreferenceDialogState();
}

class _PreferenceDialogState extends State<_PreferenceDialog> {
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

  static const _days = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
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
