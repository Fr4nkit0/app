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

  String get _initials {
    final parts = customer.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  String get _address {
    final addr = customer.addresses.where((a) => a.isPrimary).firstOrNull ??
        customer.addresses.firstOrNull;
    return addr?.street ?? '';
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? blue
                    : const Color(0xFF1565C0).withValues(alpha: 0.1),
                child: Text(
                  _initials,
                  style: TextStyle(
                    color: selected ? Colors.white : blue,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (_address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13,
                              color: Theme.of(context).colorScheme.outline),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _address,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (customer.productLabels.isNotEmpty ||
                        customer.debtAmount > 0) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (customer.debtAmount > 0)
                            DebtChip(amount: customer.debtAmount),
                          ...customer.productLabels
                              .map((label) => ProductChip(label: label)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!selectable)
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outline,
                ),
              if (selectable && selected)
                const Icon(Icons.check_circle_rounded, color: blue),
            ],
          ),
        ),
      ),
    );
  }
}
