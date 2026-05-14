import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? _EmptyState(colorScheme: colorScheme)
            : _CustomerList(customers: customers),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: colorScheme.error, size: 48),
              const SizedBox(height: 12),
              Text(
                'Error al cargar clientes',
                style: TextStyle(color: colorScheme.error),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_customers',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const CreateCustomerScreen(),
          ),
        ),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Nuevo cliente'),
        shape: const StadiumBorder(),
      ),
    );
  }
}

// ─── Lista de clientes ────────────────────────────────────────────────────────

class _CustomerList extends StatelessWidget {
  const _CustomerList({required this.customers});

  final List<Customer> customers;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _CustomerTile(customer: customers[index]),
    );
  }
}

// ─── Tile individual ─────────────────────────────────────────────────────────

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer});

  final Customer customer;

  /// Genera iniciales a partir del nombre del cliente.
  String get _initials {
    final parts = customer.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Text(
            _initials,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          customer.name,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: customer.phone != null
            ? Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    customer.phone!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                  ),
                ],
              )
            : Text(
                'Sin teléfono',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.outlineVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: colorScheme.outline,
        ),
        onTap: () {
          // TODO: navegar al detalle del cliente
        },
      ),
    );
  }
}

// ─── Estado vacío ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin clientes todavía',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocá el botón para agregar el primero.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
