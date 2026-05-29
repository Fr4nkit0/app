import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/sales/domain/models/payment_method.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      saleDraftProvider.select((s) => s.paymentMethod),
    );

    return Column(
      children: PaymentMethod.values.map((method) {
        return _MethodTile(
          method: method,
          selected: selected == method,
          onTap: () =>
              ref.read(saleDraftProvider.notifier).setPaymentMethod(method),
        );
      }).toList(),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? blue.withValues(alpha: 0.06) : Colors.white,
          border: Border.all(
            color: selected ? blue : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(method.icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.label,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? blue : null,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: blue, size: 20),
          ],
        ),
      ),
    );
  }
}
