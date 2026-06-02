import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/core/widgets/screen_header.dart';
import 'package:app/core/widgets/core_search_bar.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/screens/create_customer_screens.dart';
import 'package:app/features/customers/presentation/widgets/customer_list_tile.dart';
import 'package:app/features/sales/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_draft_state.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/product_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:app/features/sales/presentation/widgets/product_quantity_row.dart';
import 'package:app/core/widgets/core_horizontal_stepper.dart';

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

  // ─── Multi-field search predicate ─────────────────────────────────────────

  bool _matches(Customer c, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (c.name.toLowerCase().contains(q)) return true;
    if (c.phone != null && c.phone!.toLowerCase().contains(q)) return true;
    return c.addresses.any(
      (a) => a.street != null && a.street!.toLowerCase().contains(q),
    );
  }

  // ─── Habitual order apply ──────────────────────────────────────────────────

  void _onApplyHabitual(Customer customer, List<Product> products) {
    String norm(String s) => s.toLowerCase().trim();

    for (final label in customer.productLabels) {
      // Exact match first, then substring fallback (bidirectional)
      final match =
          products.where((p) => norm(p.name) == norm(label)).firstOrNull ??
              products
                  .where((p) =>
                      norm(p.name).contains(norm(label)) ||
                      norm(label).contains(norm(p.name)))
                  .firstOrNull;

      if (match != null) {
        ref.read(saleDraftProvider.notifier).setQuantity(
              SaleItem(product: match, quantity: 0),
              1,
            );
      }
      // unmatched labels are silently ignored (REQ-S1-04b)
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  void _goToCobro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SaleStep3Screen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(saleDraftProvider);
    final customer = draft.customer;
    final inSelectedMode = customer != null;

    // 3-state CTA logic
    final String ctaLabel;
    final VoidCallback? ctaAction;
    if (customer == null) {
      ctaLabel = 'Seleccioná un cliente';
      ctaAction = null;
    } else if (draft.items.isEmpty) {
      ctaLabel = 'Agregá productos';
      ctaAction = null;
    } else {
      ctaLabel = 'Continuar al cobro';
      ctaAction = draft.canProceedToStep3 ? _goToCobro : null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(
              title: 'Nueva Venta',
              subtitle: 'Elegí el cliente para registrar la venta',
              onBackPressed: Navigator.canPop(context)
                  ? () => Navigator.of(context).pop()
                  : null,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CoreHorizontalStepper(
                steps: ['Pedido', 'Cobro'],
                stepDescriptions: ['Elegir productos', 'Registrar pago'],
                layoutRow: true,
                currentStep: 0,
              ),
            ),
            const SizedBox(height: 12),
            // ── Mode-based content ─────────────────────────────────────
            Expanded(
              child: inSelectedMode
                  ? _SelectedMode(
                      customer: customer,
                      onChangeCustomer: () {
                        ref.read(saleDraftProvider.notifier).clearCustomer();
                        setState(() {
                          _query = '';
                          _searchController.clear();
                        });
                      },
                      onApplyHabitual: _onApplyHabitual,
                    )
                  : _SearchMode(
                      controller: _searchController,
                      query: _query,
                      matchesFn: _matches,
                      onQueryChanged: (q) => setState(() => _query = q),
                      onSelectCustomer: (c) =>
                          ref.read(saleDraftProvider.notifier).selectCustomer(c),
                      onNewCustomer: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateCustomerScreen(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // ── Single primary CTA ─────────────────────────────────────────────
      bottomNavigationBar: _StickyFooter(
        draft: draft,
        label: ctaLabel,
        onTap: ctaAction,
      ),
    );
  }
}

// ─── SEARCH MODE ──────────────────────────────────────────────────────────────

class _SearchMode extends ConsumerWidget {
  const _SearchMode({
    required this.controller,
    required this.query,
    required this.matchesFn,
    required this.onQueryChanged,
    required this.onSelectCustomer,
    required this.onNewCustomer,
  });

  final TextEditingController controller;
  final String query;
  final bool Function(Customer, String) matchesFn;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<Customer> onSelectCustomer;
  final VoidCallback onNewCustomer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);
    final selected = ref.watch(saleDraftProvider.select((s) => s.customer));

    return Column(
      children: [
        // Search bar + new customer button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: CoreSearchBar(
                  controller: controller,
                  onChanged: onQueryChanged,
                  hintText: 'Buscar por nombre, dirección...',
                  focusedBorderColor: Theme.of(context).extension<SalesTokens>()!.primary,
                  onClear: query.isNotEmpty
                      ? () {
                          controller.clear();
                          onQueryChanged('');
                        }
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              _NewCustomerButton(onTap: onNewCustomer),
            ],
          ),
        ),
        Expanded(
          child: customersAsync.when(
            data: (customers) {
              final filtered =
                  customers.where((c) => matchesFn(c, query)).toList();
              final frequent = filtered.where((c) => c.isFrequent).toList();
              final all = filtered;

              if (query.isNotEmpty && filtered.isEmpty) {
                return _EmptyState(query: query);
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  if (frequent.isNotEmpty) ...[
                    _SectionHeader('Frecuentes'),
                    ...frequent.map((c) => CustomerListTile(
                          customer: c,
                          selectable: true,
                          selected: selected?.id == c.id,
                          onTap: () => onSelectCustomer(c),
                        )),
                    const SizedBox(height: 8),
                  ],
                  _SectionHeader('Todos los clientes'),
                  ...all.map((c) => CustomerListTile(
                        customer: c,
                        selectable: true,
                        selected: selected?.id == c.id,
                        onTap: () => onSelectCustomer(c),
                      )),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Error al cargar clientes')),
          ),
        ),
      ],
    );
  }
}

// ─── SELECTED MODE ────────────────────────────────────────────────────────────

class _SelectedMode extends ConsumerWidget {
  const _SelectedMode({
    required this.customer,
    required this.onChangeCustomer,
    required this.onApplyHabitual,
  });

  final Customer customer;
  final VoidCallback onChangeCustomer;
  final void Function(Customer, List<Product>) onApplyHabitual;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final productsAsync = ref.watch(productListProvider);

    final draft = ref.watch(saleDraftProvider);
    final isFromRouteStop = draft.routeStopId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Client chip + "Cambiar" action ────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tokens.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: tokens.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  customer.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isFromRouteStop)
                TextButton(
                  onPressed: onChangeCustomer,
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Cambiar',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
            ],
          ),
        ),
        // ── Product list ───────────────────────────────────────────────
        Expanded(
          child: productsAsync.when(
            data: (products) => ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                // Habitual order card
                if (customer.productLabels.isNotEmpty)
                  _HabitualOrderCard(
                    labels: customer.productLabels,
                    onApply: () => onApplyHabitual(customer, products),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Text(
                    'PRODUCTOS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...products.map((p) {
                  final qty = draft.items
                      .where((i) => i.product.id == p.id)
                      .map((i) => i.quantity)
                      .firstOrNull ??
                      0;
                  return ProductQuantityRow(
                    product: p,
                    quantity: qty,
                    onIncrement: () => ref
                        .read(saleDraftProvider.notifier)
                        .setQuantity(SaleItem(product: p, quantity: 0), qty + 1),
                    onDecrement: () => ref
                        .read(saleDraftProvider.notifier)
                        .setQuantity(SaleItem(product: p, quantity: 0), qty - 1),
                  );
                }),
              ],
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Error al cargar productos')),
          ),
        ),
      ],
    );
  }
}

// ─── Habitual order card ──────────────────────────────────────────────────────

class _HabitualOrderCard extends StatelessWidget {
  const _HabitualOrderCard({required this.labels, required this.onApply});

  final List<String> labels;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.history,
                size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedido habitual',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: primary,
                  ),
                ),
                Text(
                  labels.join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Usar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Sin resultados para "$query"',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '¿Buscás por teléfono o dirección?',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── New customer button ──────────────────────────────────────────────────────

class _NewCustomerButton extends StatelessWidget {
  const _NewCustomerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.secondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: secondary,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: secondary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.person_add_alt_1_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

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

// ─── Sticky footer (strongly typed — satisfies REQ-QW-02) ────────────────────

class _StickyFooter extends StatelessWidget {
  const _StickyFooter({
    required this.draft,
    required this.label,
    required this.onTap,
  });

  final SaleDraftState draft;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final enabled = onTap != null;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show total summary when items present
          if (draft.items.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${draft.items.length} producto${draft.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Total: \$${draft.total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: tokens.primary,
                    fontSize: 18,
                    fontFeatures: tokens.tabularStyle.fontFeatures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor:
                    enabled ? tokens.primary : Colors.grey.shade200,
                foregroundColor:
                    enabled ? Colors.white : Colors.grey.shade400,
                minimumSize: const Size(double.infinity, 56),
                elevation: enabled ? 4 : 0,
                shadowColor: tokens.primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
