import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/products/domain/models/product.dart';

/// What is left on the truck right now: one row per product with its stock,
/// already discounted by the sales made on this phone.
class TruckLoadCard extends StatelessWidget {
  const TruckLoadCard({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: products.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Todavía no hay carga. Sincronizá para traerla.',
                style: tokens.subtitle.copyWith(fontSize: 13),
              ),
            )
          : Column(
              children: [
                for (final (index, product) in products.indexed) ...[
                  if (index > 0) Divider(height: 1, color: tokens.border),
                  _TruckLoadRow(
                    key: ValueKey('truck-load-${product.id}'),
                    product: product,
                  ),
                ],
              ],
            ),
    );
  }
}

class _TruckLoadRow extends StatelessWidget {
  const _TruckLoadRow({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final available = product.available ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.brandBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.water_drop_rounded,
              size: 20,
              color: tokens.brandBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
                if (product.unitLabel.isNotEmpty)
                  Text(
                    product.unitLabel,
                    style: tokens.subtitle.copyWith(fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$available',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: available > 0 ? tokens.ink : tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
