import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';
import 'package:app/features/customers/presentation/widgets/customer_list_tile.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step2_screen.dart';
import 'package:app/features/sales/presentation/widgets/sale_stepper_header.dart';

class SaleStep1Screen extends ConsumerStatefulWidget {
  const SaleStep1Screen({super.key});

  @override
  ConsumerState<SaleStep1Screen> createState() => _SaleStep1ScreenState();
}

class _SaleStep1ScreenState extends ConsumerState<SaleStep1Screen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCustomer(Customer customer) {
    ref.read(saleDraftProvider.notifier).selectCustomer(customer);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SaleStep2Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final selected = ref.watch(saleDraftProvider.select((s) => s.customer));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header sticky
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nueva Venta',
                    style:
                        Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                  ),
                  const SizedBox(height: 12),
                  const SaleStepperHeader(currentStep: 0),
                  const SizedBox(height: 12),
                  // Barra de búsqueda + botón nuevo cliente
                  Row(
                    children: [
                      Expanded(
                        child: _SearchBar(
                          controller: _searchController,
                          onChanged: (q) => setState(() => _query = q),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _NewCustomerButton(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateCustomerScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Lista
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

                  final frequent =
                      filtered.where((c) => c.isFrequent).toList();
                  final all = filtered;

                  return ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      if (frequent.isNotEmpty) ...[
                        _SectionHeader('Frecuentes'),
                        ...frequent.map((c) => CustomerListTile(
                              customer: c,
                              selectable: true,
                              selected: selected?.id == c.id,
                              onTap: () => _selectCustomer(c),
                            )),
                        const SizedBox(height: 8),
                      ],
                      _SectionHeader('Todos los clientes'),
                      ...all.map((c) => CustomerListTile(
                            customer: c,
                            selectable: true,
                            selected: selected?.id == c.id,
                            onTap: () => _selectCustomer(c),
                          )),
                    ],
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error al cargar clientes')),
              ),
            ),
          ],
        ),
      ),
      // Fixed Footer con botón continuar
      bottomNavigationBar: _FixedFooter(
        enabled: selected != null,
        onTap: selected != null
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SaleStep2Screen()),
                )
            : null,
        label: selected != null
            ? 'Continuar con ${selected.name}'
            : 'Seleccioná un cliente',
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar cliente...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon:
            Icon(Icons.search, color: Colors.grey.shade400, size: 20),
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

class _NewCustomerButton extends StatelessWidget {
  const _NewCustomerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFBF1B1B),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            const Icon(Icons.person_add_outlined, color: Colors.white, size: 22),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _FixedFooter extends StatelessWidget {
  const _FixedFooter({
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: enabled
              ? const Color(0xFF1565C0)
              : Colors.grey.shade200,
          foregroundColor: enabled ? Colors.white : Colors.grey.shade400,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
