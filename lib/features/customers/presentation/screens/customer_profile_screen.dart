import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:uuid/uuid.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/widgets/debt_payment_dialog.dart';
import 'package:app/features/payments/domain/models/payment.dart';
import 'package:app/core/utils/resource.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key, required this.customerId});

  final String customerId;

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  int _selectedTab = 0;

  static const _days = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  String _dayName(int day) => day >= 1 && day <= 7 ? _days[day] : 'Día $day';

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    final historyAsync = ref.watch(historyListProvider);

    return customerAsync.when(
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil de Cliente')),
            body: const Center(child: Text('Cliente no encontrado')),
          );
        }

        final customerHistory = historyAsync.maybeWhen(
          data: (entries) =>
              entries.where((e) => e.customer.id == customer.id).toList(),
          orElse: () => <HistoryEntry>[],
        );

        return _buildScaffold(context, customer, customerHistory);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error al cargar: $e'))),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    dynamic customer,
    List<HistoryEntry> customerHistory,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            _buildProfileHeader(customer),
            const SizedBox(height: 16),
            _buildTabBar(),
            _buildTabContent(customer, customerHistory),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_new_sale',
        onPressed: () {
          ref.read(saleDraftProvider.notifier).selectCustomer(customer);
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SaleStep1Screen()));
        },
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.point_of_sale_outlined),
        label: const Text(
          'Nueva Venta',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic customer) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        children: [
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
          Text(
            customer.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0D1B3E),
            ),
          ),
          const SizedBox(height: 10),
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
                  const Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: Color(0xFF0D1B3E),
                  ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: customer.debtAmount > 0
                          ? () async {
                              final result = await showDialog<DebtPaymentResult>(
                                context: context,
                                builder: (_) => DebtPaymentDialog(
                                  totalDebt: customer.debtAmount,
                                ),
                              );
                              if (result == null) return;

                              final payments = <Payment>[];
                              final now = DateTime.now();
                              if (result.method == 'Efectivo') {
                                payments.add(
                                  Payment(
                                    id: const Uuid().v4(),
                                    customerId: customer.id,
                                    amount: result.cashAmount!,
                                    type: PaymentType.cash,
                                    createdAt: now,
                                  ),
                                );
                              } else if (result.method == 'Transferencia') {
                                payments.add(
                                  Payment(
                                    id: const Uuid().v4(),
                                    customerId: customer.id,
                                    amount: result.transferAmount!,
                                    type: PaymentType.transfer,
                                    createdAt: now,
                                  ),
                                );
                              } else if (result.method == 'Mixto') {
                                if (result.cashAmount != null &&
                                    result.cashAmount! > 0) {
                                  payments.add(
                                    Payment(
                                      id: const Uuid().v4(),
                                      customerId: customer.id,
                                      amount: result.cashAmount!,
                                      type: PaymentType.cash,
                                      createdAt: now,
                                    ),
                                  );
                                }
                                if (result.transferAmount != null &&
                                    result.transferAmount! > 0) {
                                  payments.add(
                                    Payment(
                                      id: const Uuid().v4(),
                                      customerId: customer.id,
                                      amount: result.transferAmount!,
                                      type: PaymentType.transfer,
                                      createdAt: now.add(
                                        const Duration(milliseconds: 10),
                                      ),
                                    ),
                                  );
                                }
                              }

                              if (payments.isNotEmpty) {
                                final usecase = ref.read(
                                  registerPaymentUseCaseProvider,
                                );
                                final res = await usecase.execute(payments);
                                if (res is Success) {
                                  if (context.mounted) {
                                    TopToast.show(
                                      context,
                                      message: 'Pago registrado con éxito',
                                      icon: Icons.check_circle_rounded,
                                      color: const Color(0xFF10B981),
                                    );
                                  }
                                } else if (res is Error) {
                                  if (context.mounted) {
                                    TopToast.show(
                                      context,
                                      message:
                                          'Error al registrar pago: ${res.error}',
                                      icon: Icons.error_outline,
                                      color: const Color(0xFFDC2626),
                                    );
                                  }
                                }
                              }
                            }
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
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
                              customer.debtAmount > 0
                                  ? 'Tocar para pagar'
                                  : 'Sin deuda',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onLongPress: () {
                      final balancesAsync = ref.read(
                        customerContainerBalancesProvider(customer.id),
                      );
                      final balances = balancesAsync.maybeWhen(
                        data: (list) => list,
                        orElse: () => <CustomerContainerBalance>[],
                      );
                      final hasActiveCustody = balances.any(
                        (b) => b.quantity > 0,
                      );
                      if (!hasActiveCustody) return;

                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            ProfileContainerReturnDialog(customer: customer),
                      );
                    },
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
                          ref
                              .watch(
                                customerContainerBalancesProvider(customer.id),
                              )
                              .when(
                                data: (balances) {
                                  final bidon = balances
                                      .firstWhere(
                                        (b) => b.containerType == 'BIDON_20L',
                                        orElse: () => CustomerContainerBalance(
                                          customerId: customer.id,
                                          containerType: 'BIDON_20L',
                                          quantity: 0,
                                        ),
                                      )
                                      .quantity;
                                  final sifon = balances
                                      .firstWhere(
                                        (b) => b.containerType == 'SIFON_2L',
                                        orElse: () => CustomerContainerBalance(
                                          customerId: customer.id,
                                          containerType: 'SIFON_2L',
                                          quantity: 0,
                                        ),
                                      )
                                      .quantity;

                                  return Column(
                                    children: [
                                      _buildProfileCustodyRow(
                                        icon: Icons.water_drop_outlined,
                                        label: 'Bidón 20L',
                                        count: bidon,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildProfileCustodyRow(
                                        icon: Icons.local_drink_outlined,
                                        label: 'Sifón 2L',
                                        count: sifon,
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const Center(
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                                error: (err, stack) => const Text(
                                  'Error',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        color: isSelected
                            ? const Color(0xFF1565C0)
                            : Colors.transparent,
                        width: 3.0,
                      ),
                    ),
                  ),
                  child: Text(
                    tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade500,
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
    if (customer.preferences.isEmpty) {
      return _buildEmptyState(
        icon: Icons.schedule_outlined,
        title: 'Sin preferencias',
        subtitle: 'Este cliente no tiene horarios de entrega configurados.',
      );
    }

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
                Icon(
                  Icons.schedule_outlined,
                  color: Color(0xFF1565C0),
                  size: 20,
                ),
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
            ...customer.preferences.map((pref) {
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
    final addresses = customer.addresses;
    final addr =
        addresses.where((a) => a.isPrimary).firstOrNull ??
        addresses.firstOrNull;

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
                    Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
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
                  if (addr.visualReference != null &&
                      addr.visualReference!.isNotEmpty) ...[
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
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
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
                            content: Text(
                              'Abriendo mapa para ${addr.street ?? ''}...',
                            ),
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
                    Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF1565C0),
                      size: 20,
                    ),
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
                  value: customer.isFrequent
                      ? 'Cliente Frecuente'
                      : 'Cliente Ocasional',
                  icon: Icons.star_border_rounded,
                  valueColor: customer.isFrequent
                      ? Colors.amber.shade800
                      : null,
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

  Widget _buildProfileCustodyRow({
    required IconData icon,
    required String label,
    required int count,
  }) {
    final hasStock = count > 0;
    final color = hasStock ? const Color(0xFF1565C0) : Colors.grey.shade400;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: hasStock
                ? const Color(0xFF1565C0).withValues(alpha: 0.08)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasStock ? const Color(0xFF0D1B3E) : Colors.grey.shade500,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
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
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class ProfileContainerReturnDialog extends ConsumerStatefulWidget {
  const ProfileContainerReturnDialog({super.key, required this.customer});

  final Customer customer;

  @override
  ConsumerState<ProfileContainerReturnDialog> createState() =>
      _ProfileContainerReturnDialogState();
}

class _ProfileContainerReturnDialogState
    extends ConsumerState<ProfileContainerReturnDialog> {
  final Map<String, int> _returns = {'BIDON_20L': 0, 'SIFON_2L': 0};

  @override
  Widget build(BuildContext context) {
    final balancesAsync = ref.watch(
      customerContainerBalancesProvider(widget.customer.id),
    );
    final balances = balancesAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <CustomerContainerBalance>[],
    );

    return AlertDialog(
      title: const Text(
        'Registrar Retorno de Envases',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...['BIDON_20L', 'SIFON_2L'].map((type) {
              final returned = _returns[type] ?? 0;
              final label = type == 'BIDON_20L' ? 'Bidón 20L' : 'Sifón 2L';
              final balance = balances
                  .firstWhere(
                    (b) => b.containerType == type,
                    orElse: () => CustomerContainerBalance(
                      customerId: widget.customer.id,
                      containerType: type,
                      quantity: 0,
                    ),
                  )
                  .quantity;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: returned > 0
                              ? () {
                                  setState(() {
                                    _returns[type] = returned - 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: const Color(0xFFEF4444),
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            '$returned',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: returned < balance
                              ? () {
                                  setState(() {
                                    _returns[type] = returned + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: const Color(0xFF1565C0),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            final repository = ref.read(inventoryRepositoryProvider);
            for (final type in ['BIDON_20L', 'SIFON_2L']) {
              final returnedQty = _returns[type] ?? 0;
              if (returnedQty > 0) {
                final movement = ContainerMovement(
                  id: const Uuid().v4(),
                  customerId: widget.customer.id,
                  containerType: type,
                  deliveredQuantity: 0,
                  returnedQuantity: returnedQty,
                  createdAt: DateTime.now(),
                );
                await repository.recordContainerMovement(movement);
              }
            }

            ref.invalidate(
              customerContainerBalancesProvider(widget.customer.id),
            );

            if (context.mounted) {
              Navigator.of(context).pop();
              TopToast.show(
                context,
                message: 'Retorno de envases registrado',
                icon: Icons.check_circle_rounded,
                color: const Color(0xFF10B981),
              );
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
