import 'package:flutter/material.dart';

import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/features/customers/domain/models/customer_number.dart';

/// A customer's name followed by its number (`Kiosco Norte  #128`), the
/// number smaller and muted. A customer not synced yet shows only the name.
class CustomerNameText extends StatelessWidget {
  const CustomerNameText({
    super.key,
    required this.name,
    required this.number,
    required this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String name;
  final int? number;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final number = this.number;
    return Text.rich(
      TextSpan(
        text: name,
        style: style,
        children: [
          if (number != null)
            TextSpan(
              text: '  ${CustomerNumber.format(number)}',
              style: TextStyle(
                fontSize: (style.fontSize ?? 14) * 0.8,
                fontWeight: FontWeight.w600,
                color: context.marilin.textMuted,
                decoration: TextDecoration.none,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
        ],
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
