import 'package:flutter/material.dart';

class CoreHorizontalStepper extends StatelessWidget {
  const CoreHorizontalStepper({
    super.key,
    required this.currentStep,
    required this.steps,
    this.stepDescriptions,
    this.isSubmitting = false,
    this.activeColor,
    this.inactiveColor,
    this.layoutRow = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  final int currentStep;
  final List<String> steps;
  final List<String>? stepDescriptions;
  final bool isSubmitting;
  final Color? activeColor;
  final Color? inactiveColor;
  final bool layoutRow;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? const Color(0xFF1565C0);
    final effectiveInactiveColor = inactiveColor ?? const Color(0xFFE5E7EB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final index = i ~/ 2;
          final filled = index < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: animationDuration,
              height: 2,
              margin: const EdgeInsets.only(top: 13, left: 4, right: 4),
              color: filled ? effectiveActiveColor : effectiveInactiveColor,
            ),
          );
        }

        final index = i ~/ 2;
        final isDone = index < currentStep;
        final isActive = index == currentStep;

        final circle = AnimatedContainer(
          duration: animationDuration,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isDone || isActive)
                ? effectiveActiveColor
                : effectiveInactiveColor,
          ),
          child: Center(
            child: (isSubmitting && isActive)
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
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
          ),
        );

        final titleText = Text(
          steps[index],
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? effectiveActiveColor
                : const Color(0xFF9CA3AF),
          ),
        );

        final hasDescription = stepDescriptions != null &&
            index < stepDescriptions!.length &&
            stepDescriptions![index].isNotEmpty;
        final descriptionText = hasDescription
            ? Text(
                stepDescriptions![index],
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF9CA3AF),
                ),
              )
            : null;

        if (layoutRow) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              circle,
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  titleText,
                  if (descriptionText != null) ...[
                    const SizedBox(height: 2),
                    descriptionText,
                  ],
                ],
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            circle,
            const SizedBox(height: 4),
            titleText,
            if (descriptionText != null) ...[
              const SizedBox(height: 2),
              descriptionText,
            ],
          ],
        );
      }),
    );
  }
}
