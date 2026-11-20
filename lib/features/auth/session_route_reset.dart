import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/auth/auth_controller.dart';

/// Drops every route pushed above the root when the session ends.
///
/// The root swaps to the login screen on its own, but screens pushed on top
/// (profile, sale steps, ...) would otherwise keep covering it until the
/// driver pressed back.
class SessionRouteReset extends ConsumerWidget {
  const SessionRouteReset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(
      authControllerProvider.select((state) => state.isAuthenticated),
      (wasAuthenticated, isAuthenticated) {
        if (wasAuthenticated == true && !isAuthenticated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
    return child;
  }
}
