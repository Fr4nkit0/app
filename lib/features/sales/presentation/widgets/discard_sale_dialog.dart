import 'package:flutter/material.dart';

/// Asks before throwing away a sale the driver already started.
/// Returns true when the driver chooses to discard it.
Future<bool> confirmDiscardSale(BuildContext context) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Descartar la venta en curso?'),
      content: const Text('Vas a perder los productos cargados.'),
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
