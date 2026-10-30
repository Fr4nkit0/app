import 'package:flutter/material.dart';

/// Asks before disabling one of the customer's addresses. Returns true when
/// the driver confirms.
Future<bool> confirmDisableAddress(
  BuildContext context, {
  required String address,
}) async {
  final disable = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Dar de baja esta dirección?'),
      content: Text('$address\n\nDeja de aparecer en el perfil del cliente.'),
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
