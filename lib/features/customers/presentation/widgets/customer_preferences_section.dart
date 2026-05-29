import 'package:flutter/material.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';

class CustomerPreferencesSection extends StatelessWidget {
  const CustomerPreferencesSection({super.key, required this.preferences});

  final List<CustomerPreference> preferences;

  static const _days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  @override
  Widget build(BuildContext context) {
    if (preferences.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferencias de visita',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...preferences.map(
          (pref) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 16, color: Theme.of(context).colorScheme.outline),
                const SizedBox(width: 8),
                Text(
                  '${_dayName(pref.dayOfWeek)} · ${pref.timeWindowStart}'
                  '${pref.timeWindowEnd != null ? ' – ${pref.timeWindowEnd}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _dayName(int day) =>
      day >= 1 && day <= 7 ? _days[day] : 'Día $day';
}
