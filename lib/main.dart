import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:app/features/history/presentation/screens/history_screen.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/auth/login_screen.dart';
import 'package:app/features/sync/background/background_sync_task.dart';
import 'package:app/features/sync/presentation/widgets/sync_triggers_host.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Best effort: a device that refuses background work still syncs while
  // the app is open.
  unawaited(scheduleBackgroundSync().catchError((Object _) {}));
  runApp(
    ProviderScope(
      // The app and the background job share the cross-isolate cycle lease.
      overrides: [leasedSyncEngineOverride(owner: foregroundLeaseOwner)],
      child: const MarilinApp(),
    ),
  );
}

class MarilinApp extends StatelessWidget {
  const MarilinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marilin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.isAuthenticated) {
      return const _RootShell();
    } else {
      return const LoginScreen();
    }
  }
}

// ─── Shell raíz con NavigationBar (4 tabs, sin AppBar global) ────────────────

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  int _selectedIndex = 0;

  void _onTabChanged(int index) {
    // Resetear el draft de venta al salir del tab Venta (index 2)
    if (_selectedIndex == 2 && index != 2) {
      ref.read(saleDraftProvider.notifier).reset();
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final customerCount = ref.watch(customerCountProvider);

    // The sync cycle (push, then bootstrap or pull) runs on open, on return
    // to the foreground, when connectivity comes back and periodically.
    return SyncTriggersHost(
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: const [
            RouteDayScreen(),
            CustomerListScreen(),
            SaleStep1Screen(),
            HistoryScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabChanged,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Ruta',
            ),
            NavigationDestination(
              icon: _BadgedIcon(
                icon: const Icon(Icons.people_outline),
                count: customerCount.value ?? 0,
              ),
              selectedIcon: _BadgedIcon(
                icon: const Icon(Icons.people),
                count: customerCount.value ?? 0,
              ),
              label: 'Clientes',
            ),
            const NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Venta',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge helper ─────────────────────────────────────────────────────────────

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.count});

  final Widget icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return icon;
    return Badge.count(count: count, child: icon);
  }
}
