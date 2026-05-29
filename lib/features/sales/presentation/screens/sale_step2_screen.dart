import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/sales/presentation/providers/product_repository_provider.dart';
import 'package:app/features/sales/presentation/providers/sale_draft_provider.dart';
import 'package:app/features/sales/presentation/screens/sale_step3_screen.dart';
import 'package:app/features/sales/presentation/widgets/product_quantity_row.dart';
import 'package:app/features/sales/presentation/widgets/sale_stepper_header.dart';

class SaleStep2Screen extends ConsumerWidget {
  const SaleStep2Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productListProvider);
    final draft = ref.watch(saleDraftProvider);
    final customer = draft.customer;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header sticky: info del cliente + stepper
            _StickyHeader(customerName: customer?.name ?? ''),
            // Lista de productos
            Expanded(
              child: productsAsync.when(
                data: (products) => ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    // Card "Pedido habitual"
                    if (customer != null &&
                        customer.productLabels.isNotEmpty)
                      _HabituOrder(
                        labels: customer.productLabels,
                        onApply: () {
                          // Carga el pedido habitual al draft
                          // Por ahora solo navega; en real buscaría el producto por label
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                      child: Text(
                        'PRODUCTOS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    ...products.map((p) => ProductQuantityRow(product: p)),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error al cargar productos')),
              ),
            ),
          ],
        ),
      ),
      // Footer con total + 2 botones
      bottomNavigationBar: _StickyFooter(draft: draft),
    );
  }
}

// ─── Header sticky ────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({required this.customerName});

  final String customerName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: const Color(0xFF0D1B3E),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      color: Color(0xFF0D1B3E),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SaleStepperHeader(currentStep: 1),
          Divider(height: 1, color: Colors.grey.shade100),
        ],
      ),
    );
  }
}

class _HabituOrder extends StatelessWidget {
  const _HabituOrder({required this.labels, required this.onApply});

  final List<String> labels;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF1565C0).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history, size: 18, color: Color(0xFF1565C0)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pedido habitual',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF1565C0),
                  ),
                ),
                Text(
                  labels.join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onApply,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Usar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Footer sticky con total + 2 botones ─────────────────────────────────────

class _StickyFooter extends ConsumerWidget {
  const _StickyFooter({required this.draft});

  final dynamic draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems = draft.items.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasItems) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${draft.items.length} producto${draft.items.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Total: \$${draft.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1565C0),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              // Botón Atrás
              Expanded(
                flex: 4,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D1B3E),
                    side: const BorderSide(
                        color: Color(0xFF0D1B3E), width: 1.5),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Atrás',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              // Botón Continuar
              Expanded(
                flex: 6,
                child: FilledButton(
                  onPressed: hasItems
                      ? () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SaleStep3Screen(),
                            ),
                          )
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continuar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
