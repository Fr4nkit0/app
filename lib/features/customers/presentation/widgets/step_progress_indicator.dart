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

  @override
  Widget build(BuildContext context) {
    // Determine the progress (0.0 to 1.0)
    final progress = isSubmitting ? null : (currentStep + 1) / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4.0), // Rounded ends for M3
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 8.0, // 8dp height for expressive look
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
