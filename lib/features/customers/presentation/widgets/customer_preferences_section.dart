import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/customers/domain/models/preference_details.dart';
import 'package:app/features/customers/presentation/providers/customer_preferences_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:app/features/customers/presentation/widgets/preference_dialog.dart';

/// The customer's delivery preferences in the profile, with add, edit and
/// disable.
class CustomerPreferencesSection extends ConsumerWidget {
  const CustomerPreferencesSection({super.key, required this.customerId});

  final String customerId;

  /// Adds a preference, or edits [existing], with the window the driver
  /// picks in the dialog.
  Future<void> _save(
    BuildContext context,
    WidgetRef ref, [
    CustomerPreference? existing,
  ]) async {
    final picked = await showPreferenceDialog(context, existing: existing);
    if (picked == null || !context.mounted) return;
    final (day, start, end) = picked;
    final details = PreferenceDetails(dayOfWeek: day, start: start, end: end);
    try {
      if (existing == null) {
        await ref
            .read(addPreferenceUseCaseProvider)
            .execute(customerId: customerId, details: details);
      } else {
        await ref
            .read(editPreferenceUseCaseProvider)
            .execute(preferenceId: existing.id, details: details);
      }
      if (!context.mounted) return;
      TopToast.showSuccess(
        context,
        existing == null ? 'Preferencia agregada' : 'Preferencia actualizada',
      );
    } catch (e) {
      if (!context.mounted) return;
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se pudo guardar. Reintentá.'),
      );
    }
  }

  Future<void> _disable(
    BuildContext context,
    WidgetRef ref,
    CustomerPreference preference,
  ) async {
    final confirmed = await _confirmDisable(context, preference);
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(disablePreferenceUseCaseProvider).execute(preference.id);
      if (!context.mounted) return;
      TopToast.showSuccess(context, 'Preferencia dada de baja');
    } catch (e) {
      if (!context.mounted) return;
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se pudo dar de baja. Reintentá.'),
      );
    }
  }

  static Future<bool> _confirmDisable(
    BuildContext context,
    CustomerPreference preference,
  ) async {
    final disable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Dar de baja este horario?'),
        content: Text(
          '${preferenceDayName(preference.dayOfWeek)}, '
          '${preferenceWindowLabel(preference)}\n\n'
          'Deja de aparecer en el perfil del cliente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
    return disable ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(customerPreferencesProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.schedule_outlined,
              color: MarilinColors.brandBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Horarios de Visita Preferidos',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.marilin.ink,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _save(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Agregar preferencia'),
          ),
        ),
        const SizedBox(height: 8),
        preferences.when(
          data: (list) => list.isEmpty
              ? Text(
                  'Este cliente no tiene horarios de entrega configurados.',
                  style: TextStyle(color: context.marilin.textMuted),
                )
              : Column(
                  children: [
                    for (final p in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PreferenceCard(
                          key: const ValueKey('preference_card'),
                          preference: p,
                          onAction: (action) => switch (action) {
                            PreferenceAction.edit => _save(context, ref, p),
                            PreferenceAction.disable => _disable(
                              context,
                              ref,
                              p,
                            ),
                          },
                        ),
                      ),
                  ],
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ErrorState(
            title: 'No pudimos cargar las preferencias',
            message:
                'Revisá la conexión y reintentá. '
                'Lo que ya cargaste sigue guardado en el teléfono.',
            onRetry: () =>
                ref.invalidate(customerPreferencesProvider(customerId)),
          ),
        ),
      ],
    );
  }
}

/// What the driver can do with one preference.
enum PreferenceAction { edit, disable }

/// Presentational card of one delivery preference.
class PreferenceCard extends StatelessWidget {
  const PreferenceCard({
    super.key,
    required this.preference,
    required this.onAction,
  });

  final CustomerPreference preference;
  final ValueChanged<PreferenceAction> onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.marilin.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preferenceDayName(preference.dayOfWeek),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.marilin.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preferenceWindowLabel(preference),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.marilin.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<PreferenceAction>(
            tooltip: 'Opciones de horario',
            onSelected: onAction,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: PreferenceAction.edit,
                child: Text('Editar'),
              ),
              PopupMenuItem(
                value: PreferenceAction.disable,
                child: Text('Dar de baja'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
