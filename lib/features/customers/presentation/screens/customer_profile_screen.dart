import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/domain/models/history_entry_type.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  int _selectedTab = 0;

  static const _days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _dayName(int day) =>
      day >= 1 && day <= 7 ? _days[day] : 'Día $day';

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    final historyAsync = ref.watch(historyListProvider);

    final customerHistory = historyAsync.maybeWhen(
      data: (entries) =>
          entries.where((e) => e.customer.id == customer.id).toList(),
      orElse: () => <HistoryEntry>[],
    );

    // Dynamic list with high-fidelity mockup data if the DB history is empty
    final displayHistory = customerHistory.isNotEmpty
        ? customerHistory
        : [
            HistoryEntry(
              id: 'mock_1',
              type: HistoryEntryType.sale,
              customer: customer,
              date: DateTime.now().subtract(const Duration(hours: 2)),
              amount: 13000,
              description: 'Venta de Agua',
              tags: const ['2 x 20L', 'MIXTO'],
            ),
            HistoryEntry(
              id: 'mock_2',
              type: HistoryEntryType.sale,
              customer: customer,
              date: DateTime.now().subtract(const Duration(hours: 5)),
              amount: 9000,
              description: 'Venta de Soda',
              tags: const ['9 x 1.5L', 'MIXTO'],
            ),
            HistoryEntry(
              id: 'mock_3',
              type: HistoryEntryType.payment,
              customer: customer,
              date: DateTime.now().subtract(const Duration(days: 1)),
              amount: 6500,
              description: 'Pago recibido',
              tags: const ['Transf. Bancaria'],
            ),
          ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Beautiful slate-50 background tint
      appBar: AppBar(
        title: const Text(
          'Perfil de Cliente',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF0D1B3E),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D1B3E),
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Top Profile Header ──────────────────────────────────────────
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.only(top: 24, bottom: 20),
              child: Column(
                children: [
                  // Massive Blue Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1565C0),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AvatarUtils.getInitials(customer.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Customer Name
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Phone Pill
                  if (customer.phone != null && customer.phone!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF0D1B3E)),
                          const SizedBox(width: 8),
                          Text(
                            customer.phone!,
                            style: const TextStyle(
                              color: Color(0xFF0D1B3E),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            height: 14,
                            width: 1,
                            color: const Color(0xFF1565C0).withValues(alpha: 0.2),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Llamando a ${customer.name}...'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: const Text(
                              'Llamar',
                              style: TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Metric Cards (Saldo + Comodatos)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Card 1: Saldo en dinero
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Saldo en dinero',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade900,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.credit_card_rounded,
                                      size: 16,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '\$${customer.debtAmount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Deuda pendiente',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Card 2: Comodatos activos
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Comodatos activos',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D1B3E),
                                      ),
                                    ),
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 16,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Text(
                                      '2',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D1B3E),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bidones 20L',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Text(
                                      '9',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0D1B3E),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sifon 1.5L',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ─── Custom Tab Bar ──────────────────────────────────────────────
            _buildTabBar(),
            
            // ─── Tab Views ───────────────────────────────────────────────────
            _buildTabContent(customer, displayHistory),
            
            const SizedBox(height: 80), // Padding to avoid FAB coverage
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_sale',
        onPressed: () {
          ref.read(saleDraftProvider.notifier).selectCustomer(customer);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SaleStep1Screen()),
          );
        },
        backgroundColor: const Color(0xFFBF1B1B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.point_of_sale_outlined),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Historial', 'Preferencias', 'Acuerdos', 'Datos'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? const Color(0xFF1565C0) : Colors.transparent,
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent(Customer customer, List<HistoryEntry> history) {
    switch (_selectedTab) {
      case 0:
        return _buildHistoryTab(history);
      case 1:
        return _buildPreferencesTab(customer);
      case 2:
        return _buildAcuerdosTab();
      case 3:
        return _buildDatosTab(customer);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHistoryTab(List<HistoryEntry> history) {
    if (history.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history_outlined,
        title: 'Sin actividad reciente',
        subtitle: 'Este cliente no tiene historial de visitas ni ventas.',
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HistoryEntryTile(entry: history[index]),
        ),
      ),
    );
  }

  Widget _buildPreferencesTab(Customer customer) {
    final displayPrefs = customer.preferences.isNotEmpty
        ? customer.preferences
        : [
            CustomerPreference(
              id: 'pref_1',
              dayOfWeek: 3, // Wednesday
              timeWindowStart: '14:00',
              timeWindowEnd: '16:00',
            ),
            CustomerPreference(
              id: 'pref_2',
              dayOfWeek: 6, // Saturday
              timeWindowStart: '10:00',
              timeWindowEnd: '12:00',
            ),
            CustomerPreference(
              id: 'pref_3',
              dayOfWeek: 1, // Monday
              timeWindowStart: '08:00',
              timeWindowEnd: '10:00',
            ),
          ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.schedule_outlined, color: Color(0xFF1565C0), size: 20),
                SizedBox(width: 8),
                Text(
                  'Horarios de Visita Preferidos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D1B3E),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFE2E8F0)),
            ...displayPrefs.map((pref) {
              final day = _dayName(pref.dayOfWeek);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1565C0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '$day: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0D1B3E),
                            ),
                          ),
                          Text(
                            'de ${pref.timeWindowStart} a ${pref.timeWindowEnd ?? ''} hs',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAcuerdosTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.handshake_outlined,
                size: 32,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Acuerdos Comerciales',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D1B3E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Próximamente disponible. Aquí se listarán los contratos especiales de comodato y precios fijos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatosTab(Customer customer) {
    final addr = customer.addresses.where((a) => a.isPrimary).firstOrNull ??
        customer.addresses.firstOrNull;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Dirección principal
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined, color: Color(0xFF1565C0), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Dirección de Entrega',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B3E),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                if (addr != null) ...[
                  Text(
                    addr.street ?? 'Sin nombre de calle',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D1B3E),
                    ),
                  ),
                  if (addr.floor != null || addr.apartment != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (addr.floor != null) 'Piso ${addr.floor}',
                        if (addr.apartment != null) 'Depto ${addr.apartment}',
                      ].join(' - '),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  if (addr.visualReference != null && addr.visualReference!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              addr.visualReference!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Abriendo mapa para ${addr.street ?? ''}...'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Cómo llegar / Ver en Mapa'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ] else
                  Text(
                    'Sin dirección cargada',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Card 2: Otros Datos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: Color(0xFF1565C0), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Datos de Cuenta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B3E),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, color: Color(0xFFE2E8F0)),
                _buildDataRow(
                  label: 'Teléfono',
                  value: customer.phone ?? 'No registrado',
                  icon: Icons.phone_android_rounded,
                ),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildDataRow(
                  label: 'Frecuencia de compra',
                  value: customer.isFrequent ? 'Cliente Frecuente' : 'Cliente Ocasional',
                  icon: Icons.star_border_rounded,
                  valueColor: customer.isFrequent ? Colors.amber.shade800 : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF0D1B3E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
