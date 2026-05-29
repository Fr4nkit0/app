import 'package:flutter/material.dart';
import 'package:app/core/widgets/debt_chip.dart';
import 'package:app/core/widgets/product_chip.dart';
import 'package:app/features/customers/domain/models/customer.dart';

class CustomerProfileHeader extends StatelessWidget {
  const CustomerProfileHeader({super.key, required this.customer});

  final Customer customer;

  String get _initials {
    final parts = customer.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: blue.withValues(alpha: 0.12),
              child: Text(
                _initials,
                style: const TextStyle(
                  color: blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                customer.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
        if (customer.debtAmount > 0) ...[
          const SizedBox(height: 12),
          DebtChip(amount: customer.debtAmount),
        ],
        if (customer.productLabels.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: customer.productLabels
                .map((label) => ProductChip(label: label))
                .toList(),
          ),
        ],
      ],
    );
  }
}
