import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/core/theme/theme_mode_controller.dart';
import 'package:app/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:app/features/history/presentation/screens/history_screen.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/sales/presentation/widgets/discard_sale_dialog.dart';

import 'package:app/features/auth/auth_controller.dart';
import 'package:app/features/auth/login_screen.dart';
import 'package:app/features/sync/background/background_sync_task.dart';
import 'package:app/features/sync/presentation/widgets/sync_triggers_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The theme is known before the first frame, so a dark choice does not flash light.
  ThemeModeController.initial = await ThemeModeController.readSaved(
    const FlutterSecureStorage(),
  );
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

class MarilinApp extends ConsumerWidget {
  const MarilinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Marilin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      // The phone's theme unless the driver picked one in the profile.
      themeMode: ref.watch(themeModeProvider),
      // Pickers and dialogs from Material speak the driver's language.
      locale: const Locale('es', 'AR'),
      supportedLocales: const [Locale('es', 'AR'), Locale('es'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
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

  static const _saleTabIndex = 2;

  Future<void> _onTabChanged(int index) async {
    // Leaving the sale tab drops the draft; a started sale asks first.
    if (_selectedIndex == _saleTabIndex && index != _saleTabIndex) {
      if (!ref.read(saleDraftProvider).isEmpty) {
        final discard = await confirmDiscardSale(context);
        if (!discard || !mounted) return;
      }
      ref.read(saleDraftProvider.notifier).reset();
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Ruta',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Clientes',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Venta',
            ),
            NavigationDestination(
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
