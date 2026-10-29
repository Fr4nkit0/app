import 'package:flutter/material.dart';

/// Asks before throwing away a new customer the driver already started.
/// Returns true when the driver chooses to discard it.
Future<bool> confirmDiscardCustomer(BuildContext context) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Descartar el cliente nuevo?'),
      content: const Text('Vas a perder los datos cargados.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Seguir editando'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  return discard ?? false;
}
