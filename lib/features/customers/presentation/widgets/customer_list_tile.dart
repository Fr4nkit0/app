import 'package:flutter/material.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/features/customers/domain/models/customer.dart';

class CustomerListTile extends StatelessWidget {
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

  Color _getPastelColor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFFE0F2FE), // Blue
      const Color(0xFFFCE7F3), // Pink
      const Color(0xFFFEF3C7), // Amber
      const Color(0xFFE8F5E9), // Green
      const Color(0xFFF3E8FF), // Purple
      const Color(0xFFFFEDD5), // Orange
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getTextColor(String name) {
    final hash = name.hashCode;
    final colors = [
      const Color(0xFF0369A1),
      const Color(0xFFBE185D),
      const Color(0xFFB45309),
      const Color(0xFF2E7D32),
      const Color(0xFF6B21A8),
      const Color(0xFFC2410C),
    ];
    return colors[hash.abs() % colors.length];
  }

  String _getInitials(String name) {
    final cleanName = name.replaceAll(RegExp(r"[^\w\s]"), '').trim();
    final parts = cleanName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  String get _address {
    final addr = customer.addresses.where((a) => a.isPrimary).firstOrNull ??
        customer.addresses.firstOrNull;
    return addr?.street ?? '';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    final initials = _getInitials(customer.name);
    final avatarBg = _getPastelColor(customer.name);
    final avatarText = _getTextColor(customer.name);

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
          color: selected ? blue.withValues(alpha: 0.8) : const Color(0xFFE2E8F0),
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
                          color: selected ? blue : avatarBg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: selected ? Colors.white : avatarText,
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
                                color: selected ? blue : const Color(0xFF0D1B3E),
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
                              DebtChip(amount: customer.debtAmount),
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
                            if (customer.phone != null && customer.phone!.isNotEmpty) ...[
                              _buildQuickActionButton(
                                icon: Icons.phone_in_talk_outlined,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Llamando a ${customer.name}...'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_address.isNotEmpty)
                              _buildQuickActionButton(
                                icon: Icons.map_outlined,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Abriendo mapa para $_address...'),
                                      duration: const Duration(seconds: 1),
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F4F6),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }
}
