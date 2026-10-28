import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/widgets/customer_agreements_tab.dart';
import 'package:app/features/history/domain/models/history_entry.dart';
import 'package:app/features/history/presentation/providers/history_list_provider.dart';
import 'package:app/features/history/presentation/widgets/history_entry_tile.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/domain/models/customer_container_balance.dart';
import 'package:app/features/inventory/domain/models/container_movement.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:uuid/uuid.dart';
import 'package:app/features/payments/presentation/providers/payment_repository_provider.dart';
import 'package:app/features/payments/presentation/register_debt_payment.dart';

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
              entries.where((e) => e.customerId == customer.id).toList(),
          orElse: () => <HistoryEntry>[],
        );

        return _buildScaffold(context, customer, customerHistory);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Perfil de Cliente')),
        body: ErrorState(
          title: 'No pudimos cargar el cliente',
          message:
              'Revisá la conexión y reintentá. '
              'Lo que ya cargaste sigue guardado en el teléfono.',
          onRetry: () =>
              ref.invalidate(customerByIdProvider(widget.customerId)),
        ),
      ),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    dynamic customer,
    List<HistoryEntry> customerHistory,
  ) {
    return Scaffold(
      backgroundColor: context.marilin.fill,
      appBar: AppBar(
        title: Text(
          'Perfil de Cliente',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.marilin.ink,
          ),
        ),
        backgroundColor: context.marilin.surface,
        foregroundColor: context.marilin.ink,
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
        backgroundColor: MarilinColors.brandBlue,
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
      color: context.marilin.surface,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: MarilinColors.brandBlue,
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.marilin.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (customer.phone != null && customer.phone!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: MarilinColors.brandBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: MarilinColors.brandBlue.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.phone_outlined,
                    size: 16,
                    color: context.marilin.ink,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    customer.phone!,
                    style: TextStyle(
                      color: context.marilin.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 14,
                    width: 1,
                    color: MarilinColors.brandBlue.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final phone = customer.phone!.replaceAll(
                        RegExp(r'[^\d]'),
                        '',
                      );
                      final uri = Uri.parse('https://wa.me/$phone');
                      try {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo abrir WhatsApp'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Contactar',
                      style: TextStyle(
                        color: MarilinColors.brandBlue,
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
            child: IntrinsicHeight(
              child: Builder(
                builder: (context) {
                  final balanceAsync = ref.watch(
                    customerBalanceProvider(customer.id),
                  );
                  final balance = balanceAsync.value ?? customer.debtAmount;
                  final containerBalancesAsync = ref.watch(
                    customerContainerBalancesProvider(customer.id),
                  );

                  return Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: balance > 0
                              ? context.marilin.soft(Color(0xFFFEF2F2))
                              : context.marilin.soft(Color(0xFFECFDF5)),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: balance > 0
                                ? () => registerDebtPayment(
                                    context,
                                    ref,
                                    customer: customer,
                                    debt: balance,
                                  )
                                : null,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: balance > 0
                                      ? context.marilin.soft(Color(0xFFFEE2E2))
                                      : const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Saldo en dinero',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: balance > 0
                                              ? Colors.red.shade900
                                              : Colors.green.shade900,
                                        ),
                                      ),
                                      Icon(
                                        balance > 0
                                            ? Icons.credit_card_rounded
                                            : (balance == 0
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                        .monetization_on_outlined),
                                        size: 16,
                                        color: balance > 0
                                            ? const Color(0xFFEF4444)
                                            : const Color(0xFF10B981),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    balance > 0
                                        ? '\$${balance.toStringAsFixed(0)}'
                                        : (balance == 0
                                              ? '\$0'
                                              : '\$${(-balance).toStringAsFixed(0)}'),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: balance > 0
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF10B981),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    balance > 0
                                        ? 'Deuda: \$${balance.toStringAsFixed(0)}'
                                        : (balance == 0
                                              ? 'Al día'
                                              : 'Saldo a favor: \$${(-balance).toStringAsFixed(0)}'),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: balance > 0
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Material(
                          color: context.marilin.surface,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => ProfileContainerReturnDialog(
                                  customer: customer,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: context.marilin.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Comodatos activos',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.marilin.ink,
                                        ),
                                      ),
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 16,
                                        color: MarilinColors.brandBlue,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  containerBalancesAsync.when(
                                    data: (balances) {
                                      final bidon = balances
                                          .firstWhere(
                                            (b) =>
                                                b.containerType == 'BIDON_20L',
                                            orElse: () =>
                                                CustomerContainerBalance(
                                                  customerId: customer.id,
                                                  containerType: 'BIDON_20L',
                                                  quantity: 0,
                                                ),
                                          )
                                          .quantity;
                                      final sifon = balances
                                          .firstWhere(
                                            (b) =>
                                                b.containerType == 'SIFON_2L',
                                            orElse: () =>
                                                CustomerContainerBalance(
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
                                            label: 'Sifón 1.5L',
                                            count: sifon,
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    error: (_, __) => Text(
                                      'Sin comodatos',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.marilin.textMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Historial', 'Preferencias', 'Acuerdos', 'Datos'];
    return Container(
      color: context.marilin.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.marilin.border, width: 1.5),
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
                            ? MarilinColors.brandBlue
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
                          ? MarilinColors.brandBlue
                          : context.marilin.textMuted,
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
        return CustomerAgreementsTab(customerId: customer.id);
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
          color: context.marilin.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.marilin.border),
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
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: MarilinColors.brandBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Horarios de Visita Preferidos',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: context.marilin.ink,
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: context.marilin.border),
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
                        color: MarilinColors.brandBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '$day: ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: context.marilin.ink,
                            ),
                          ),
                          Text(
                            'de ${pref.timeWindowStart} a ${pref.timeWindowEnd ?? ''} hs',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.marilin.inkSecondary,
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
              color: context.marilin.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.marilin.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color: MarilinColors.brandBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Dirección de Entrega',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.marilin.ink,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: context.marilin.border),
                if (addr != null) ...[
                  Text(
                    AddressFormatter.format(
                      street: addr.street,
                      neighborhood: addr.neighborhood,
                      floor: addr.floor,
                      apartment: addr.apartment,
                      visualReference: addr.visualReference,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.marilin.ink,
                    ),
                  ),
                  if (addr.latitude != null && addr.longitude != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ubicación fijada (${addr.latitude!.toStringAsFixed(6)}, ${addr.longitude!.toStringAsFixed(6)})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else
                  Text(
                    'Sin dirección cargada',
                    style: TextStyle(color: context.marilin.textMuted),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Card 2: Otros Datos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.marilin.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.marilin.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: MarilinColors.brandBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Datos de Cuenta',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.marilin.ink,
                      ),
                    ),
                  ],
                ),
                Divider(height: 24, color: context.marilin.border),
                _buildDataRow(
                  label: 'Teléfono',
                  value: customer.phone ?? 'No registrado',
                  icon: Icons.phone_android_rounded,
                ),
                Divider(height: 16, color: context.marilin.fill),
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
        Icon(icon, size: 18, color: context.marilin.inkHint),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.marilin.inkHint,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? context.marilin.ink,
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
    final color = hasStock ? MarilinColors.brandBlue : context.marilin.inkHint;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: hasStock
                ? MarilinColors.brandBlue.withValues(alpha: 0.08)
                : context.marilin.fill,
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
              color: hasStock ? context.marilin.ink : context.marilin.textMuted,
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
          Icon(icon, size: 48, color: context.marilin.lineStrong),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.marilin.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.marilin.textMuted),
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
            Text(
              'Ajustá la cantidad de envases vacíos que devuelve el cliente.',
              style: TextStyle(color: context.marilin.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...['BIDON_20L', 'SIFON_2L'].map((type) {
              final returned = _returns[type] ?? 0;
              final label = type == 'BIDON_20L' ? 'Bidón 20L' : 'Sifón 1.5L';
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
                          tooltip: 'Restar',
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
                          tooltip: 'Sumar',
                          onPressed: returned < balance
                              ? () {
                                  setState(() {
                                    _returns[type] = returned + 1;
                                  });
                                }
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: MarilinColors.brandBlue,
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
            backgroundColor: MarilinColors.brandBlue,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
