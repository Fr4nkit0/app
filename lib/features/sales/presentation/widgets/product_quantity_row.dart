import 'package:flutter/material.dart';
import 'package:app/core/theme/sales_tokens.dart';
import 'package:app/features/products/domain/models/product.dart';

/// Pure presentational widget for a product row with quantity stepper.
/// Has zero Riverpod dependency — all state and actions come from the parent.
class ProductQuantityRow extends StatelessWidget {
  const ProductQuantityRow({
    super.key,
    required this.product,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<SalesTokens>()!;
    final cs = Theme.of(context).colorScheme;
    final hasQuantity = quantity > 0;
    final primary = tokens.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: hasQuantity ? primary.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasQuantity
              ? primary.withValues(alpha: 0.4)
              : Colors.grey.shade200,
          width: hasQuantity ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: hasQuantity
                ? primary.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: hasQuantity ? 10 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icono del producto
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: hasQuantity
                      ? primary.withValues(alpha: 0.12)
                      : cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.water_drop_rounded,
                  size: 22,
                  color: hasQuantity ? primary : cs.outline,
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: hasQuantity ? primary : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${product.price.toStringAsFixed(0)} c/u'
                      '${hasQuantity ? '  ·  Subtotal: \$${(product.price * quantity).toStringAsFixed(0)}' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasQuantity
                            ? primary.withValues(alpha: 0.8)
                            : cs.outline,
                        fontFeatures: tokens.tabularStyle.fontFeatures,
                      ),
                    ),
                    // Show stock availability only when not null (REQ-S1-03a/b)
                    if (product.available != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Disponible: ${product.available}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Stepper
              _QuantityStepper(
                quantity: quantity,
                primary: primary,
                cs: cs,
                onDecrement: quantity > 0 ? onDecrement : null,
                onIncrement: onIncrement,
              ),
            ],
          ),
        ),
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
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove_rounded,
          onTap: onDecrement,
          active: quantity > 0,
          primary: const Color(0xFFBF1B1B),
          cs: cs,
        ),
        SizedBox(
          width: 38,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: quantity > 0 ? primary : SalesTokens.muted,
            ),
          ),
        ),
        _Btn(
          icon: Icons.add_rounded,
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
    final isEnabled = active && onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isEnabled
                ? primary.withValues(alpha: 0.1)
                : primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 18,
              color: isEnabled ? primary : primary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}
