import 'package:flutter/material.dart';

class CustomerStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;

  const CustomerStepIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.isSubmitting = false,
  });

  static const _blue = Color(0xFF1565C0);
  static const _steps = ['Datos', 'Dirección', 'Preferencias'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            // Línea divisora
            final filled = (i ~/ 2) < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: filled ? _blue : const Color(0xFFE5E7EB),
              ),
            );
          }
          final step = i ~/ 2;
          final isDone = step < currentStep;
          final isActive = step == currentStep;
          return _StepDot(
            number: step + 1,
            label: _steps[step],
            isDone: isDone,
            isActive: isActive,
            isSubmitting: isSubmitting && isActive,
          );
        }),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isSubmitting,
  });

  final int number;
  final String label;
  final bool isDone;
  final bool isActive;
  final bool isSubmitting;

  static const _blue = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDone || isActive) ? _blue : const Color(0xFFE5E7EB),
          ),
          child: Center(
            child: isSubmitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '$number',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? _blue : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
