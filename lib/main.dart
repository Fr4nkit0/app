import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app.theme.dart';
import 'package:app/features/customers/presentation/screens/customer_list_screen.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';

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

// ─── Shell raíz con NavigationBar ────────────────────────────────────────────

class _RootShell extends ConsumerStatefulWidget {
  const _RootShell();

  @override
  ConsumerState<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends ConsumerState<_RootShell> {
  int _selectedIndex = 0;

  static const List<_NavDestination> _destinations = [
    _NavDestination(
      label: 'Clientes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    _NavDestination(
      label: 'Ventas',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    _NavDestination(
      label: 'Ruta',
      icon: Icons.route_outlined,
      selectedIcon: Icons.route,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final customerCount = ref.watch(customerCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_selectedIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
            tooltip: 'Perfil',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          CustomerListScreen(),
          _ComingSoonScreen(
            icon: Icons.receipt_long_outlined,
            label: 'Ventas',
          ),
          _ComingSoonScreen(
            icon: Icons.route_outlined,
            label: 'Ruta',
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          // Destino Clientes con badge reactivo
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
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ventas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Ruta',
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

// ─── Datos de navegación ──────────────────────────────────────────────────────

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

// ─── Pantalla "Próximamente" ──────────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 40,
              vertical: 48,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Próximamente',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Esta sección está en desarrollo.\nPresto va a estar disponible.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
