import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:app/features/history/presentation/screens/history_screen.dart';
import 'package:app/features/route/presentation/screens/route_day_screen.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

void main() {
  runApp(const ProviderScope(child: MarilinApp()));
}

class MarilinApp extends StatelessWidget {
  const MarilinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marilin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _RootShell(),
    );
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

    return Scaffold(
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
