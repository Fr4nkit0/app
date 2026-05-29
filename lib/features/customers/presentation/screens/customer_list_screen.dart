import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:app/features/customers/presentation/widgets/customer_list_tile.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Clientes'),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: customersAsync.maybeWhen(
                data: (customers) => _SearchBar(
                  controller: _searchController,
                  hint: 'Buscar ${customers.length} clientes...',
                  onChanged: (q) => setState(() => _query = q),
                ),
                orElse: () => _SearchBar(
                  controller: _searchController,
                  hint: 'Buscar clientes...',
                  onChanged: (q) => setState(() => _query = q),
                ),
              ),
            ),
            Expanded(
              child: customersAsync.when(
                data: (customers) {
                  final filtered = _query.isEmpty
                      ? customers
                      : customers
                          .where((c) => c.name
                              .toLowerCase()
                              .contains(_query.toLowerCase()))
                          .toList();
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      icon: Icons.people_outline,
                      title: 'Sin clientes',
                      message: 'Tocá el botón para agregar el primero.',
                    );
                  }
                  return _CustomerList(
                    customers: filtered,
                    onTap: (customer) => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerProfileScreen(customer: customer),
                      ),
                    ),
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error al cargar clientes',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_customers',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateCustomerScreen()),
        ),
        backgroundColor: const Color(0xFFBF1B1B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon:
            Icon(Icons.search, color: Colors.grey.shade500, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  const _CustomerList({required this.customers, required this.onTap});

  final List<Customer> customers;
  final ValueChanged<Customer> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 96),
      itemCount: customers.length,
      itemBuilder: (context, index) => CustomerListTile(
        customer: customers[index],
        onTap: () => onTap(customers[index]),
      ),
    );
  }
}
