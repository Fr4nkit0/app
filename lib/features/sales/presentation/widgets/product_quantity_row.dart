import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/features/sales/domain/models/product.dart';
import 'package:app/features/sales/domain/models/sale_item.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';

class ProductQuantityRow extends ConsumerWidget {
  const ProductQuantityRow({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final items = ref.watch(saleDraftProvider.select((s) => s.items));
    final existing =
        items.where((i) => i.product.id == product.id).firstOrNull;
    final quantity = existing?.quantity ?? 0;
    final hasQuantity = quantity > 0;
    final primary = tokens.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: hasQuantity ? primary.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasQuantity
              ? primary.withValues(alpha: 0.3)
              : cs.outlineVariant,
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
                  ? primary.withValues(alpha: 0.1)
                  : cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.water_drop_outlined,
              size: 20,
              color: hasQuantity ? primary : cs.outline,
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
                    color: hasQuantity ? primary : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${product.price.toStringAsFixed(0)} c/u'
                  '${hasQuantity ? '  ·  Subtotal: \$${(product.price * quantity).toStringAsFixed(0)}' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.outline,
                    fontFeatures: tokens.tabularStyle.fontFeatures,
                  ),
                ),
                // Show stock availability only when not null (REQ-S1-03a/b)
                if (product.available != null)
                  Text(
                    'Disponible: ${product.available}',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.outline,
                    ),
                  ),
              ],
            ),
          ),
          // Stepper
          _QuantityStepper(
            quantity: quantity,
            primary: primary,
            cs: cs,
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
    required this.primary,
    required this.cs,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final Color primary;
  final ColorScheme cs;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove,
          onTap: quantity > 0 ? onDecrement : null,
          active: quantity > 0,
          primary: primary,
          cs: cs,
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: quantity > 0 ? primary : SalesTokens.muted,
            ),
          ),
        ),
        _Btn(
          icon: Icons.add,
          onTap: onIncrement,
          active: true,
          primary: primary,
          cs: cs,
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({
    required this.icon,
    required this.onTap,
    required this.active,
    required this.primary,
    required this.cs,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final Color primary;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active && onTap != null
              ? primary.withValues(alpha: 0.1)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active && onTap != null ? primary : SalesTokens.muted,
        ),
      ),
    );
  }
}
