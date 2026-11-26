import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/utils/money_formatter.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/customer_agreement.dart';
import 'package:app/features/customers/presentation/providers/customer_agreements_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:app/features/customers/presentation/widgets/new_agreement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Acuerdos tab of the customer profile: the customer's price agreements
/// and the entry points to create, edit and delete them.
class CustomerAgreementsTab extends ConsumerWidget {
  const CustomerAgreementsTab({super.key, required this.customerId});

  final String customerId;

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    CustomerAgreement agreement,
    AgreementAction action,
  ) async {
    switch (action) {
      case AgreementAction.edit:
        await showNewAgreementSheet(context, customerId, initial: agreement);
      case AgreementAction.delete:
        await _delete(context, ref, agreement);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CustomerAgreement agreement,
  ) async {
    final confirmed = await confirmDeleteAgreement(
      context,
      productName: agreement.productName,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(deleteAgreementUseCaseProvider).execute(agreement.id);
    } catch (e) {
      if (!context.mounted) return;
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se eliminó el acuerdo. Reintentá.'),
      );
      return;
    }
    if (!context.mounted) return;
    TopToast.showSuccess(context, 'Acuerdo eliminado');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreements = ref.watch(customerAgreementsProvider(customerId));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => showNewAgreementSheet(context, customerId),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo acuerdo'),
            ),
          ),
          const SizedBox(height: 12),
          agreements.when(
            data: (list) => list.isEmpty
                ? const _EmptyAgreements()
                : Column(
                    children: [
                      for (final a in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AgreementCard(
                            agreement: a,
                            // An ended agreement is history: it is not
                            // changed any more.
                            onAction: a.status == AgreementStatus.ended
                                ? null
                                : (action) =>
                                      _onAction(context, ref, a, action),
                          ),
                        ),
                    ],
                  ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorState(
              title: 'No pudimos cargar los acuerdos',
              message:
                  'Revisá la conexión y reintentá. '
                  'Lo que ya cargaste sigue guardado en el teléfono.',
              onRetry: () =>
                  ref.invalidate(customerAgreementsProvider(customerId)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAgreements extends StatelessWidget {
  const _EmptyAgreements();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.handshake_outlined,
            size: 48,
            color: context.marilin.lineStrong,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin acuerdos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.marilin.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Este cliente no tiene acuerdos de precio.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.marilin.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Asks before deleting the agreement for [productName]. Returns true when
/// the driver confirms.
Future<bool> confirmDeleteAgreement(
  BuildContext context, {
  required String productName,
}) async {
  final delete = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Eliminar acuerdo?'),
      content: Text(
        '$productName\n\nDeja de aplicarse en las ventas y no se puede '
        'reactivar.',
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
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  return delete ?? false;
}

enum AgreementAction { edit, delete }

/// Presentational card of one agreement. Offers its actions when
/// [onAction] is given.
class AgreementCard extends StatelessWidget {
  const AgreementCard({super.key, required this.agreement, this.onAction});

  final CustomerAgreement agreement;
  final ValueChanged<AgreementAction>? onAction;

  static String formatDate(String day) {
    final p = day.split('-');
    return '${p[2]}/${p[1]}/${p[0]}';
  }

  static (String, Color) _chip(AgreementStatus status) => switch (status) {
    AgreementStatus.inForce => ('Vigente', MarilinColors.success),
    AgreementStatus.ended => ('Finalizado', MarilinColors.textMuted),
    AgreementStatus.future => ('Futuro', MarilinColors.brandBlue),
  };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _chip(agreement.status);
    final validity = agreement.validTo == null
        ? 'Desde ${formatDate(agreement.validFrom)}'
        : '${formatDate(agreement.validFrom)} al ${formatDate(agreement.validTo!)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.marilin.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  agreement.productName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.marilin.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (onAction != null)
                PopupMenuButton<AgreementAction>(
                  tooltip: 'Opciones de acuerdo',
                  onSelected: onAction,
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: AgreementAction.edit,
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: AgreementAction.delete,
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(agreement.unitPrice),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: context.marilin.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            validity,
            style: TextStyle(fontSize: 13, color: context.marilin.inkSecondary),
          ),
          if (agreement.reason != null) ...[
            const SizedBox(height: 4),
            Text(
              agreement.reason!,
              style: TextStyle(
                fontSize: 13,
                color: context.marilin.inkSecondary,
              ),
            ),
          ],
          if (!agreement.isSynced) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sync_outlined,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  'Pendiente de sincronizar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
