import 'package:flutter/material.dart';
import 'package:app/core/theme/sales_tokens.dart';

/// Shows 2-step progress indicator: "Pedido" (step 0) → "Cobro" (step 1).
class SaleStepperHeader extends StatelessWidget {
  const SaleStepperHeader({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _Step(index: 0, label: 'Pedido', current: currentStep),
          _Divider(active: currentStep >= 1),
          _Step(index: 1, label: 'Cobro', current: currentStep),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.label, required this.current});

  final int index;
  final String label;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;
    final isActive = current == index;
    final isDone = current > index;

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isActive || isDone) ? primary : Colors.grey.shade200,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? primary : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: active ? primary : Colors.grey.shade200,
      ),
    );
  }
}
