import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/visits/domain/reschedule_time.dart';

/// Picker field for the time of a reschedule, always later today.
class VisitRescheduleTimeField extends StatelessWidget {
  const VisitRescheduleTimeField({
    super.key,
    required this.selected,
    required this.onTap,
    this.error,
  });

  final TimeOfDay? selected;
  final VoidCallback onTap;
  final RescheduleTimeError? error;

  static String? messageFor(RescheduleTimeError? error) =>
      error == null ? null : rescheduleTimeMessage(error);

  @override
  Widget build(BuildContext context) {
    final time = selected;
    final label = time == null
        ? 'Elegir hora'
        : 'Hoy, ${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'HORA DE LA NUEVA PARADA (HOY)',
          errorText: messageFor(error),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: const Icon(
            Icons.schedule_rounded,
            color: MarilinColors.brandBlue,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: time == null ? context.marilin.textMuted : null,
          ),
        ),
      ),
    );
  }
}
