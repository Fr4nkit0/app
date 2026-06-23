import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/core/widgets/circular_action_button.dart';
import 'package:app/core/widgets/top_toast.dart';
import 'package:app/core/utils/resource.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:app/features/customers/presentation/widgets/address_picker_map.dart';
import 'package:app/features/customers/presentation/providers/customer_repository_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_count_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CustomerListTile extends ConsumerWidget {
  const CustomerListTile({
    super.key,
    required this.customer,
    this.onTap,
    this.selectable = false,
    this.selected = false,
  });

  final Customer customer;
  final VoidCallback? onTap;
  final bool selectable;
  final bool selected;

  String get _address {
    final addr =
        customer.addresses.where((a) => a.isPrimary).firstOrNull ??
        customer.addresses.firstOrNull;
    if (addr == null) return '';
    return AddressFormatter.format(
      street: addr.street,
      floor: addr.floor,
      apartment: addr.apartment,
      visualReference: addr.visualReference,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const blue = Color(0xFF1565C0);
    final initials = AvatarUtils.getInitials(customer.name);
    final avatarColors = AvatarUtils.getColors(
      customer.name,
      selected: selected,
      baseColor: AvatarUtils.getPastelColor(customer.name),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? blue.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: selected
                ? blue.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: selected ? 12 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: selected
              ? blue.withValues(alpha: 0.8)
              : const Color(0xFFE2E8F0),
          width: selected ? 2.0 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upper Row: Avatar + Name & Address + Selection/Action
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pastel Avatar
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: avatarColors.background,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: avatarColors.foreground,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? blue
                                    : const Color(0xFF0D1B3E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _address.isNotEmpty ? _address : 'Sin dirección',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Right accessory
                      if (selectable) ...[
                        const SizedBox(width: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: selected
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  key: ValueKey('selected'),
                                  color: blue,
                                  size: 24,
                                )
                              : Icon(
                                  Icons.circle_outlined,
                                  key: const ValueKey('unselected'),
                                  color: Colors.grey.shade300,
                                  size: 24,
                                ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Bottom Row: Tags + Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Chips for Debt and Products
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (customer.debtAmount > 0)
                              DebtChip(
                                amount: customer.debtAmount,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                backgroundColor: const Color(
                                  0xFFEF4444,
                                ).withValues(alpha: 0.08),
                                borderColor: const Color(0xFFFFCDD2),
                                borderWidth: 1.0,
                                textColor: const Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                icon: Icons.warning_amber_rounded,
                                iconSize: 11,
                                iconColor: const Color(0xFFEF4444),
                                prefixText: 'Deuda: \$',
                              ),
                            ...customer.productLabels
                                .take(2) // Max 2 tags to avoid overflow
                                .map((label) => ProductChip(label: label)),
                          ],
                        ),
                      ),

                      // Quick Contact / Map Actions
                      if (!selectable) ...[
                        Row(
                          children: [
                            if (customer.phone != null &&
                                customer.phone!.isNotEmpty) ...[
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No se pudo abrir WhatsApp',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF25D366),
                                    shape: BoxShape.circle,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.whatsapp,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_address.isNotEmpty)
                              CircularActionButton(
                                icon: Icons.location_on,
                                color: const Color(0xFF0369A1),
                                onPressed: () async {
                                  final addr = customer.addresses
                                          .where((a) => a.isPrimary)
                                          .firstOrNull ??
                                      customer.addresses.firstOrNull;
                                  if (addr == null) return;

                                  await Navigator.of(context).push<LatLng>(
                                    MaterialPageRoute(
                                      builder: (context) => AddressPickerMap(
                                        initialLatitude: addr.latitude,
                                        initialLongitude: addr.longitude,
                                        initialSearchQuery: addr.street,
                                        onSave: (latLng) async {
                                          final repository =
                                              ref.read(customerRepositoryProvider);
                                          final updateResult =
                                              await repository
                                                  .updateAddressCoordinates(
                                            addr.id,
                                            latLng.latitude,
                                            latLng.longitude,
                                          );

                                          if (context.mounted) {
                                            switch (updateResult) {
                                              case Success():
                                                TopToast.showSuccess(
                                                  context,
                                                  'Ubicación del cliente guardada',
                                                );
                                                ref
                                                    .read(
                                                        paginatedCustomerListProvider
                                                            .notifier)
                                                    .refresh();
                                                ref.invalidate(
                                                    customerByIdProvider(
                                                        customer.id));
                                              case Error(:final error):
                                                TopToast.showError(
                                                  context,
                                                  'Error al guardar ubicación: $error',
                                                );
                                            }
                                          }
                                        },
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
