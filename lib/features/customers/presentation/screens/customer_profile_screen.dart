import 'package:app/core/utils/money_formatter.dart';
import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/core/presentation/failure_message.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_usecase_providers.dart';
import 'package:app/features/customers/presentation/widgets/disable_customer_dialog.dart';
import 'package:app/features/route/presentation/providers/route_repository_provider.dart';
import 'package:app/features/customers/presentation/screens/edit_customer_screen.dart';
import 'package:app/features/customers/presentation/widgets/customer_addresses_section.dart';
import 'package:app/features/customers/presentation/widgets/customer_agreements_tab.dart';
import 'package:app/features/customers/presentation/widgets/customer_preferences_section.dart';
import 'package:app/features/customers/presentation/widgets/customer_history_list.dart';
import 'package:app/features/history/presentation/providers/customer_history_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step1_screen.dart';
import 'package:app/features/inventory/presentation/providers/inventory_repository_provider.dart';
import 'package:app/features/inventory/domain/custody.dart';
import 'package:app/features/inventory/domain/models/container_type.dart';
import 'package:app/features/inventory/presentation/widgets/container_return_dialog.dart';
import 'package:app/features/inventory/presentation/widgets/register_container_return_dialog.dart';
import 'package:app/core/widgets/error_state.dart';
import 'package:app/core/widgets/top_toast.dart';
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

  /// Disabling is allowed with a stop today; the dialog only warns about it.
  Future<void> _disable(Customer customer) async {
    final hasStopToday =
        ref
            .read(routeAllStopsProvider)
            .value
            ?.any((s) => s.customer.id == customer.id) ??
        false;
    final confirmed = await confirmDisableCustomer(
      context,
      customerName: customer.name,
      hasStopToday: hasStopToday,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(disableCustomerUseCaseProvider).execute(customer.id);
      if (!mounted) return;
      TopToast.showSuccess(context, '${customer.name} dado de baja');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      TopToast.showError(
        context,
        failureMessage(e, fallback: 'No se pudo dar de baja. Reintentá.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    // Kept live so the disable dialog knows about today's stop.
    ref.watch(routeAllStopsProvider);

    // Every address or preference write re-emits the customer list, which
    // reloads this provider; keeping the shown customer keeps the scroll view
    // (and its position) instead of swapping in the loading scaffold.
    return customerAsync.when(
      skipLoadingOnReload: true,
      data: (customer) {
        if (customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Perfil de Cliente')),
            body: const Center(child: Text('Cliente no encontrado')),
          );
        }

        return _buildScaffold(context, customer);
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

  Widget _buildScaffold(BuildContext context, dynamic customer) {
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
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditCustomerScreen(customer: customer),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dar de baja',
            icon: const Icon(Icons.person_off_outlined),
            onPressed: () => _disable(customer),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileHeader(customer),
              const SizedBox(height: 16),
              _buildTabBar(),
              _buildTabContent(customer),
              const SizedBox(height: 80),
            ],
          ),
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
                          TopToast.showError(
                            context,
                            'No se pudo abrir WhatsApp',
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
                  final containerTypes = ref
                      .watch(containerTypesProvider)
                      .maybeWhen(
                        data: (types) => types,
                        orElse: () => <ContainerType>[],
                      );

                  return Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: balance > 0
                              ? context.marilin.soft(
                                  MarilinColors.destructive.withValues(
                                    alpha: 0.12,
                                  ),
                                )
                              : context.marilin.soft(
                                  MarilinColors.success.withValues(alpha: 0.12),
                                ),
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
                                      ? context.marilin.soft(
                                          MarilinColors.destructive.withValues(
                                            alpha: 0.12,
                                          ),
                                        )
                                      : context.marilin.soft(
                                          MarilinColors.success.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
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
                                            ? context.marilin.vivid(
                                                MarilinColors.destructive,
                                              )
                                            : context.marilin.vivid(
                                                MarilinColors.success,
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    balance > 0
                                        ? formatMoney(balance)
                                        : (balance == 0
                                              ? formatMoney(0)
                                              : formatMoney(-balance)),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: balance > 0
                                          ? context.marilin.vivid(
                                              MarilinColors.destructive,
                                            )
                                          : context.marilin.vivid(
                                              MarilinColors.success,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    balance > 0
                                        ? 'Debe ${formatMoney(balance)}'
                                        : (balance == 0
                                              ? 'Al día'
                                              : 'Saldo a favor: ${formatMoney(-balance)}'),
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
                                builder: (_) => RegisterContainerReturnDialog(
                                  customerId: customer.id,
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
                                      final custody = custodyByContainerType(
                                        balances,
                                      );
                                      return Column(
                                        children: [
                                          for (final (index, type)
                                              in containerTypes.indexed) ...[
                                            if (index > 0)
                                              const SizedBox(height: 8),
                                            _buildProfileCustodyRow(
                                              icon: containerTypeIcon(index),
                                              label: type.label,
                                              count: custody[type.code] ?? 0,
                                            ),
                                          ],
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

  Widget _buildTabContent(Customer customer) {
    switch (_selectedTab) {
      case 0:
        return _buildHistoryTab(customer);
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

  /// Every record of the customer stored on the device, including the ones
  /// the bootstrap brought from the server.
  Widget _buildHistoryTab(Customer customer) {
    final containerLabels = <String, String>{
      for (final type
          in ref.watch(containerTypesProvider).value ?? const <ContainerType>[])
        type.code: type.label,
    };
    return ref
        .watch(customerRecordsProvider(customer.id))
        .when(
          skipLoadingOnReload: true,
          data: (records) => records.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history_outlined,
                  title: 'Sin actividad reciente',
                  subtitle:
                      'Este cliente no tiene historial de visitas ni ventas.',
                )
              : CustomerHistoryList(
                  records: records,
                  containerLabels: containerLabels,
                ),
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _buildEmptyState(
            icon: Icons.error_outline,
            title: 'No pudimos cargar el historial',
            subtitle: 'Volvé a abrir el perfil para reintentar.',
          ),
        );
  }

  Widget _buildPreferencesTab(Customer customer) {
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
        child: CustomerPreferencesSection(customerId: customer.id),
      ),
    );
  }

  Widget _buildDatosTab(Customer customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: Direcciones de entrega
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.marilin.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.marilin.border),
            ),
            child: CustomerAddressesSection(customerId: customer.id),
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
