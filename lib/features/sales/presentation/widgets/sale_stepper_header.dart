import 'package:flutter/material.dart';
import 'package:app/core/theme/sales_tokens.dart';

/// Shows 2-step progress indicator: "Pedido" (step 0) → "Cobro" (step 1).
class SaleStepperHeader extends StatelessWidget {
  const SaleStepperHeader({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Step(
              index: 0,
              label: 'Pedido',
              description: 'Elegir productos',
              current: currentStep,
            ),
          ),
          Container(
            width: 32,
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: currentStep >= 1
                    ? [
                        Theme.of(context).extension<SalesTokens>()!.primary,
                        Theme.of(context).extension<SalesTokens>()!.primary,
                      ]
                    : [
                        Theme.of(context).extension<SalesTokens>()!.primary,
                        Colors.grey.shade300,
                      ],
              ),
            ),
          ),
          Expanded(
            child: _Step(
              index: 1,
              label: 'Cobro',
              description: 'Registrar pago',
              current: currentStep,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.index,
    required this.label,
    required this.description,
    required this.current,
  });

  final int index;
  final String label;
  final String description;
  final int current;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).extension<SalesTokens>()!.primary;
    final isActive = current == index;
    final isDone = current > index;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF10B981) // Emerald check
                : isActive
                    ? primary
                    : Colors.white,
            border: Border.all(
              color: isDone
                  ? const Color(0xFF10B981)
                  : isActive
                      ? primary
                      : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '${index + 1}',
                      key: ValueKey('step_$index'),
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive || isDone ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? primary
                      : isDone
                          ? const Color(0xFF0F172A)
                          : Colors.grey.shade500,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: isActive || isDone
                      ? Colors.grey.shade600
                      : Colors.grey.shade400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
