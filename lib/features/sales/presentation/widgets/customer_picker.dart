import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/widgets/customer_list_tile.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

class CustomerPicker extends ConsumerWidget {
  const CustomerPicker({super.key, required this.onSelected});

  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    final selectedCustomer = ref.watch(
      saleDraftProvider.select((s) => s.customer),
    );

    return customersAsync.when(
      data: (customers) => ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerListTile(
            customer: customer,
            selectable: true,
            selected: selectedCustomer?.id == customer.id,
            onTap: () {
              ref.read(saleDraftProvider.notifier).selectCustomer(customer);
              onSelected();
            },
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Error al cargar clientes')),
    );
  }
}
