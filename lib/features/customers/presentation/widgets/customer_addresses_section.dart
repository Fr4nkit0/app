import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';
import 'package:app/features/customers/presentation/providers/customer_addresses_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:app/features/customers/presentation/screens/address_form_screen.dart';
import 'package:app/features/customers/presentation/widgets/disable_address_dialog.dart';

/// The customer's delivery addresses in the profile, with add, edit,
/// disable and mark as primary.
class CustomerAddressesSection extends ConsumerWidget {
  const CustomerAddressesSection({super.key, required this.customerId});

  final String customerId;

  void _openForm(BuildContext context, [CustomerAddress? address]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AddressFormScreen(customerId: customerId, address: address),
      ),
    );
  }

  Future<void> _setPrimary(
    BuildContext context,
    WidgetRef ref,
    CustomerAddress address,
  ) async {
    try {
      await ref.read(setPrimaryAddressUseCaseProvider).execute(address.id);
      if (!context.mounted) return;
      TopToast.showSuccess(context, 'Dirección principal actualizada');
    } catch (e) {
      if (!context.mounted) return;
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se pudo cambiar. Reintentá.'),
      );
    }
  }

  Future<void> _disable(
    BuildContext context,
    WidgetRef ref,
    CustomerAddress address,
  ) async {
    final confirmed = await confirmDisableAddress(
      context,
      address: AddressCard.describe(address),
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(disableAddressUseCaseProvider).execute(address.id);
      if (!context.mounted) return;
      TopToast.showSuccess(context, 'Dirección dada de baja');
    } catch (e) {
      if (!context.mounted) return;
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se pudo dar de baja. Reintentá.'),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addresses = ref.watch(customerAddressesProvider(customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: MarilinColors.brandBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Direcciones de entrega',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.marilin.ink,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Agregar dirección'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        addresses.when(
          data: (list) => list.isEmpty
              ? Text(
                  'Sin dirección cargada',
                  style: TextStyle(color: context.marilin.textMuted),
                )
              : Column(
                  children: [
                    for (final a in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AddressCard(
                          key: const ValueKey('address_card'),
                          address: a,
                          onAction: (action) => switch (action) {
                            AddressAction.edit => _openForm(context, a),
                            AddressAction.setPrimary => _setPrimary(
                              context,
                              ref,
                              a,
                            ),
                            AddressAction.disable => _disable(context, ref, a),
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
            title: 'No pudimos cargar las direcciones',
            message:
                'Revisá la conexión y reintentá. '
                'Lo que ya cargaste sigue guardado en el teléfono.',
            onRetry: () =>
                ref.invalidate(customerAddressesProvider(customerId)),
          ),
        ),
      ],
    );
  }
}

/// What the driver can do with one address.
enum AddressAction { edit, setPrimary, disable }

/// Presentational card of one address. The primary offers only editing:
/// another address has to become the primary before it can be disabled.
class AddressCard extends StatelessWidget {
  const AddressCard({super.key, required this.address, required this.onAction});

  final CustomerAddress address;
  final ValueChanged<AddressAction> onAction;

  static String describe(CustomerAddress a) => AddressFormatter.format(
    street: a.street,
    neighborhood: a.neighborhood,
    floor: a.floor,
    apartment: a.apartment,
    visualReference: a.visualReference,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: context.marilin.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: address.isPrimary
              ? MarilinColors.brandBlue.withValues(alpha: 0.4)
              : context.marilin.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.isPrimary) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MarilinColors.brandBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Principal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MarilinColors.brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  describe(address),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.marilin.ink,
                  ),
                ),
                if (address.latitude != null && address.longitude != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: context.marilin.success,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ubicación fijada',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.marilin.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<AddressAction>(
            tooltip: 'Opciones de dirección',
            onSelected: onAction,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: AddressAction.edit,
                child: Text('Editar'),
              ),
              if (!address.isPrimary) ...const [
                PopupMenuItem(
                  value: AddressAction.setPrimary,
                  child: Text('Marcar como principal'),
                ),
                PopupMenuItem(
                  value: AddressAction.disable,
                  child: Text('Dar de baja'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
