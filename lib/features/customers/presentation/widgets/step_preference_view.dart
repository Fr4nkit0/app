import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/domain/usecases/add_preference.usecase.dart';
import 'package:app/features/customers/presentation/widgets/preference_dialog.dart';

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

  /// Opens the dialog for a new preference, or to edit [existing]. A day
  /// and start another preference of the form already takes is refused with
  /// the same reason the create use case gives.
  void _openPreferenceModal(
    BuildContext context, {
    CustomerPreference? existing,
  }) {
    showPreferenceDialog(
      context,
      existing: existing,
      onSave: (day, start, end) async {
        final window = PreferenceDetails(dayOfWeek: day, start: start);
        final taken = preferences.any(
          (p) =>
              p.id != existing?.id &&
              window.sameSlot(p.dayOfWeek, p.timeWindowStart),
        );
        if (taken) return AddPreferenceUseCase.slotTaken;
        if (existing != null) {
          onPreferenceChanged(
            existing.id,
            dayOfWeek: day,
            timeWindowStart: start,
            timeWindowEnd: end,
          );
        } else {
          onNewPreferenceSaved(day, start, end);
        }
        return null;
      },
    );
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
                  dayLabel: preferenceDayName(p.dayOfWeek),
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
