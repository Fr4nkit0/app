import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/auth_controller.dart';
import 'package:app/core/widgets/top_toast.dart';

/// Asks for confirmation and closes the session, unless changes are still
/// waiting to sync.
Future<void> confirmAndLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('¿Cerrar sesión?'),
      content: const Text(
        'Vas a volver a la pantalla de ingreso. '
        'Si marcaste Recordarme, tus datos quedan cargados.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final result = await ref.read(authControllerProvider.notifier).logout();
  if (result is LogoutBlocked && context.mounted) {
    TopToast.showError(context, result.message);
  }
}

/// The sign-out icon; see [confirmAndLogout].
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout),
      onPressed: () => confirmAndLogout(context, ref),
    );
  }
}
