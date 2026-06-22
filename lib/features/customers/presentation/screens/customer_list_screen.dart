import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/empty_state.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/core/widgets/core_search_bar.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';
import 'package:app/features/customers/presentation/screens/customer_profile_screen.dart';
import 'package:app/features/customers/presentation/widgets/customer_list_tile.dart';
import 'package:app/features/customers/presentation/widgets/new_customer_button.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  final ScrollController _controller = ScrollController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Load first page when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedCustomerListProvider.notifier).loadNextPage();
    });
    _controller.addListener(() {
      final state = ref.read(paginatedCustomerListProvider);

      if (_controller.position.extentAfter < 300 &&
          !state.isLoading &&
          !state.hasReachedMax) {
        ref.read(paginatedCustomerListProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paginatedCustomerListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              title: 'Clientes',
              subtitle: 'Gestioná tus clientes y ventas',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: CoreSearchBar(
                controller: _searchController,
                hintText: 'Buscar clientes...',
                onChanged: (q) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 400), () {
                    ref
                        .read(paginatedCustomerListProvider.notifier)
                        .setSearchQuery(q);
                  });
                },
              ),
            ),
            Expanded(
              child: state.customers.isEmpty && !state.isLoading
                  ? const EmptyState(
                      icon: Icons.people_outline,
                      title: 'Sin clientes',
                      message: 'Tocá el botón para agregar el primero.',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref
                            .read(paginatedCustomerListProvider.notifier)
                            .refresh();
                      },
                      child: ListView.builder(
                        controller: _controller,
                        padding: const EdgeInsets.only(bottom: 96),
                        itemCount:
                            state.customers.length +
                            (state.hasReachedMax ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (index < state.customers.length) {
                            final customer = state.customers[index];
                            return CustomerListTile(
                              customer: customer,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomerProfileScreen(
                                    customerId: customer.id,
                                  ),
                                ),
                              ),
                            );
                          }

                          // Loader at the bottom
                          return _buildLoader(state);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: NewCustomerButton(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateCustomerScreen()),
          );
          // Recargar la lista al volver de crear un cliente
          if (mounted) {
            ref.read(paginatedCustomerListProvider.notifier).refresh();
          }
        },
        backgroundColor: const Color(0xFF1565C0),
      ),
    );
  }

  Widget _buildLoader(PaginatedCustomerListState state) {
    // 1. Si está cargando, mostrar spinner
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Si llegamos al final, mostrar botón de actualizar
    if (state.hasReachedMax) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton.icon(
            onPressed: () =>
                ref.read(paginatedCustomerListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar lista'),
          ),
        ),
      );
    }

    // 3. Si no llegó al final, cargar más página automáticamente
    // Usamos addPostFrameCallback para evitar modificar el estado durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paginatedCustomerListProvider.notifier).loadNextPage();
    });

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
