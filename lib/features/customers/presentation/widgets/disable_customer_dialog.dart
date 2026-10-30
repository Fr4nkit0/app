import 'package:flutter/material.dart';

/// Asks before disabling [customerName]; only the office can undo it.
/// [hasStopToday] warns that the customer's stop leaves today's route.
/// Returns true when the driver confirms.
Future<bool> confirmDisableCustomer(
  BuildContext context, {
  required String customerName,
  required bool hasStopToday,
}) async {
  final disable = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('¿Dar de baja a $customerName?'),
      content: Text(
        'Deja de aparecer en la lista de clientes. '
        'Solo la oficina puede volver a darlo de alta.'
        '${hasStopToday ? '\n\nTiene una parada en la ruta de hoy, que también deja de aparecer.' : ''}',
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
