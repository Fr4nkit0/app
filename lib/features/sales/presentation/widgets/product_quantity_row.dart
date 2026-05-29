import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/sales/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

class ProductQuantityRow extends ConsumerWidget {
  const ProductQuantityRow({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(saleDraftProvider.select((s) => s.items));
    final existing =
        items.where((i) => i.product.id == product.id).firstOrNull;
    final quantity = existing?.quantity ?? 0;
    final hasQuantity = quantity > 0;
    const blue = Color(0xFF1565C0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: hasQuantity ? blue.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasQuantity ? blue.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
          width: hasQuantity ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icono del producto
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: hasQuantity
                  ? blue.withValues(alpha: 0.1)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 20,
              color: hasQuantity ? blue : const Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: hasQuantity ? blue : const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${product.price.toStringAsFixed(0)} c/u'
                  '${hasQuantity ? '  ·  Subtotal: \$${(product.price * quantity).toStringAsFixed(0)}' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          // Stepper
          _QuantityStepper(
            quantity: quantity,
            onDecrement: () => ref.read(saleDraftProvider.notifier).setQuantity(
                  SaleItem(product: product, quantity: 0),
                  (quantity - 1).clamp(0, 99),
                ),
            onIncrement: () => ref.read(saleDraftProvider.notifier).setQuantity(
                  SaleItem(product: product, quantity: 0),
                  quantity + 1,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove,
          onTap: quantity > 0 ? onDecrement : null,
          active: quantity > 0,
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: quantity > 0 ? blue : const Color(0xFFD1D5DB),
            ),
          ),
        ),
        _Btn(icon: Icons.add, onTap: onIncrement, active: true),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap, required this.active});

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1565C0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active && onTap != null
              ? blue.withValues(alpha: 0.1)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active && onTap != null ? blue : const Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}
