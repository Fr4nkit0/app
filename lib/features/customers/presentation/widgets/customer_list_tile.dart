import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/core/utils/avatar_utils.dart';
import 'package:app/core/utils/address_formatter.dart';
import 'package:app/features/customers/domain/models/customer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:app/core/widgets/top_toast.dart';

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
      neighborhood: addr.neighborhood,
      floor: addr.floor,
      apartment: addr.apartment,
      visualReference: addr.visualReference,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const blue = MarilinColors.brandBlue;
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
        color: selected
            ? blue.withValues(alpha: 0.03)
            : context.marilin.surface,
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
              : context.marilin.border,
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
                                color: selected ? blue : context.marilin.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _address.isNotEmpty ? _address : 'Sin dirección',
                              style: TextStyle(
                                fontSize: 13,
                                color: context.marilin.textMuted,
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
                                  color: context.marilin.lineStrong,
                                  size: 24,
                                ),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: context.marilin.inkHint,
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
                                backgroundColor: context.marilin
                                    .vivid(MarilinColors.destructive)
                                    .withValues(alpha: 0.08),
                                borderColor: context.marilin.soft(
                                  MarilinColors.destructive.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                borderWidth: 1.0,
                                textColor: context.marilin.vivid(
                                  MarilinColors.destructive,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                icon: Icons.warning_amber_rounded,
                                iconSize: 11,
                                iconColor: context.marilin.vivid(
                                  MarilinColors.destructive,
                                ),
                                prefixText: 'Deuda: ',
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
                                      TopToast.showError(
                                        context,
                                        'No se pudo abrir WhatsApp',
                                      );
                                    }
                                  }
                                },
                                child: Tooltip(
                                  message: 'WhatsApp',
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      color: MarilinColors.success,
                                      shape: BoxShape.circle,
                                    ),
                                    child: FaIcon(
                                      FontAwesomeIcons.whatsapp,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
