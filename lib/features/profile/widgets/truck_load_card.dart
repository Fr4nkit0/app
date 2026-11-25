import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/inventory/domain/models/truck_skeletons.dart';
import 'package:app/features/products/domain/models/product.dart';

/// What is left on the truck right now: one row per product with its stock,
/// already discounted by the sales made on this phone, and the skeletons of
/// today's route when it loaded or moved any.
class TruckLoadCard extends StatelessWidget {
  const TruckLoadCard({super.key, required this.products, this.skeletons});

  final List<Product> products;

  /// Shown only when the route has skeleton loads or movements.
  final TruckSkeletons? skeletons;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final skeletons = this.skeletons;
    final showsSkeletons = skeletons != null && skeletons.hasActivity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: products.isEmpty && !showsSkeletons
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
                if (showsSkeletons) ...[
                  if (products.isNotEmpty)
                    Divider(height: 1, color: tokens.border),
                  _SkeletonRow(
                    key: const ValueKey('truck-load-skeletons'),
                    skeletons: skeletons,
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

/// The skeletons left on the truck, below what was loaded; negative when
/// more went out than was loaded.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({super.key, required this.skeletons});

  final TruckSkeletons skeletons;

  @override
  Widget build(BuildContext context) {
    final tokens = context.marilin;
    final remaining = skeletons.remaining;

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
              Icons.inventory_2_outlined,
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
                  'Esqueleto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: tokens.ink,
                  ),
                ),
                Text(
                  'Cargados: ${skeletons.loaded}',
                  style: tokens.subtitle.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: remaining < 0
                  ? tokens.destructive
                  : remaining > 0
                  ? tokens.ink
                  : tokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
