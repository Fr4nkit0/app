import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/widgets/customer_addresses_section.dart';
import 'package:app/features/customers/presentation/widgets/customer_preferences_section.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step2_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState
    extends ConsumerState<CustomerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final historyAsync = ref.watch(historyListProvider);

    final customerHistory = historyAsync.maybeWhen(
      data: (entries) =>
          entries.where((e) => e.customer.id == customer.id).toList(),
      orElse: () => <HistoryEntry>[],
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0D1B3E),
            elevation: 0,
            scrolledUnderElevation: 0.5,
            shadowColor: Colors.black12,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _ProfileHeader(customer: customer),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF1565C0),
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: const Color(0xFF1565C0),
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Pedidos'),
                Tab(text: 'Info'),
                Tab(text: 'Preferencias'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 0: Pedidos / Historial
            _HistoryTab(entries: customerHistory),
            // Tab 1: Info
            _InfoTab(customer: customer),
            // Tab 2: Preferencias
            _PreferencesTab(customer: customer),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_sale',
        onPressed: () {
          ref.read(saleDraftProvider.notifier).selectCustomer(customer);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SaleStep2Screen()),
          );
        },
        backgroundColor: const Color(0xFFBF1B1B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.point_of_sale_outlined),
        label: const Text('Nueva Venta',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ─── Header expandible ────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.customer});

  final Customer customer;

  String get _initials {
    final parts = customer.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 80, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: blue.withValues(alpha: 0.1),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    if (customer.phone != null)
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            customer.phone!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bento grid: deuda + productos
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'Deuda',
                  value: customer.debtAmount > 0
                      ? '\$${customer.debtAmount.toStringAsFixed(0)}'
                      : 'Sin deuda',
                  valueColor: customer.debtAmount > 0
                      ? const Color(0xFFBF1B1B)
                      : Colors.green.shade700,
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  label: 'Pedido típico',
                  value: customer.productLabels.isNotEmpty
                      ? customer.productLabels.first
                      : 'Sin datos',
                  valueColor: blue,
                  icon: Icons.water_drop_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Sin pedidos registrados',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, i) => _HistoryEntryRow(entry: entries[i]),
    );
  }
}

class _HistoryEntryRow extends StatelessWidget {
  const _HistoryEntryRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isSale = entry.type == HistoryEntryType.sale;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSale
                  ? const Color(0xFF1565C0).withValues(alpha: 0.08)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSale
                  ? Icons.point_of_sale_outlined
                  : Icons.person_outline,
              size: 18,
              color: isSale ? const Color(0xFF1565C0) : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  _formatDate(entry.date),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade500,
                      ),
                ),
              ],
            ),
          ),
          if (entry.amount != null)
            Text(
              '\$${entry.amount!.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF1565C0),
                fontSize: 15,
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} hs';
    if (diff.inDays == 1) return 'Ayer';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customer.productLabels.isNotEmpty) ...[
            _sectionLabel('Productos habituales'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: customer.productLabels
                  .map((l) => ProductChip(label: l))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
          if (customer.debtAmount > 0) ...[
            _sectionLabel('Deuda'),
            const SizedBox(height: 8),
            DebtChip(amount: customer.debtAmount),
            const SizedBox(height: 20),
          ],
          if (customer.addresses.isNotEmpty) ...[
            _sectionLabel('Dirección'),
            const SizedBox(height: 8),
            CustomerAddressesSection(addresses: customer.addresses),
          ],
        ],
      ),
    );
  }
}

class _PreferencesTab extends StatelessWidget {
  const _PreferencesTab({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    if (customer.preferences.isEmpty) {
      return Center(
        child: Text(
          'Sin preferencias de visita',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: CustomerPreferencesSection(preferences: customer.preferences),
    );
  }
}

Widget _sectionLabel(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.8,
      ),
    );
