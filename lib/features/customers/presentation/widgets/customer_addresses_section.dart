import 'package:flutter/material.dart';
import 'package:app/features/customers/domain/models/customer.address.dart';

class CustomerAddressesSection extends StatelessWidget {
  const CustomerAddressesSection({super.key, required this.addresses});

  final List<CustomerAddress> addresses;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dirección',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...addresses.map(
          (addr) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (addr.street != null)
                        Text(addr.street!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      if (addr.floor != null || addr.apartment != null)
                        Text(
                          [
                            if (addr.floor != null) 'Piso ${addr.floor}',
                            if (addr.apartment != null) 'Depto ${addr.apartment}',
                          ].join(' - '),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      if (addr.visualReference != null)
                        Text(
                          addr.visualReference!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
