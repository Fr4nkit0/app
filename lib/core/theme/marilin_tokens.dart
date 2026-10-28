import 'package:flutter/material.dart';

/// Compile-time color constants (use in `const` widgets and [ThemeData]).
abstract final class MarilinColors {
  static const Color scaffoldMuted = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color brandBlue = Color(0xFF2563EB);
  static const Color brandNavy = Color(0xFF0D1B3E);
  static const Color textMuted = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color success = Color(0xFF10B981);
  static const Color destructive = Color(0xFFDC2626);
  static const Color accent = Color(0xFFEA580C);
}

/// Semantic design tokens for Marilin mobile (Premium SaaS / SURFACE.md).
///
/// Prefer [MarilinTokens.of] in widgets; use [MarilinColors] when `const` is required.
class MarilinTokens extends ThemeExtension<MarilinTokens> {
  const MarilinTokens({
    required this.scaffoldMuted,
    required this.surface,
    required this.brandBlue,
    required this.brandNavy,
    required this.textMuted,
    required this.border,
    required this.success,
    required this.destructive,
    required this.accent,
  });

  final Color scaffoldMuted;
  final Color surface;
  final Color brandBlue;
  final Color brandNavy;
  final Color textMuted;
  final Color border;
  final Color success;
  final Color destructive;
  final Color accent;

  static const MarilinTokens light = MarilinTokens(
    scaffoldMuted: MarilinColors.scaffoldMuted,
    surface: MarilinColors.surface,
    brandBlue: MarilinColors.brandBlue,
    brandNavy: MarilinColors.brandNavy,
    textMuted: MarilinColors.textMuted,
    border: MarilinColors.border,
    success: MarilinColors.success,
    destructive: MarilinColors.destructive,
    accent: MarilinColors.accent,
  );

  /// DESIGN.md dark palette: dark canvas, lighter cards, light ink.
  static const MarilinTokens dark = MarilinTokens(
    scaffoldMuted: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    brandBlue: Color(0xFF3B82F6),
    brandNavy: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8),
    border: Color(0xFF334155),
    success: Color(0xFF34D399),
    destructive: Color(0xFFF87171),
    accent: Color(0xFFFB923C),
  );

  static MarilinTokens of(BuildContext context) {
    return Theme.of(context).extension<MarilinTokens>() ?? light;
  }

  TextStyle get titleLarge => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: brandNavy,
        letterSpacing: 0.3,
      );

  TextStyle get subtitle => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textMuted,
      );

  @override
  MarilinTokens copyWith({
    Color? scaffoldMuted,
    Color? surface,
    Color? brandBlue,
    Color? brandNavy,
    Color? textMuted,
    Color? border,
    Color? success,
    Color? destructive,
    Color? accent,
  }) {
    return MarilinTokens(
      scaffoldMuted: scaffoldMuted ?? this.scaffoldMuted,
      surface: surface ?? this.surface,
      brandBlue: brandBlue ?? this.brandBlue,
      brandNavy: brandNavy ?? this.brandNavy,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      success: success ?? this.success,
      destructive: destructive ?? this.destructive,
      accent: accent ?? this.accent,
    );
  }

  @override
  MarilinTokens lerp(MarilinTokens? other, double t) {
    if (other == null) return this;
    return MarilinTokens(
      scaffoldMuted: Color.lerp(scaffoldMuted, other.scaffoldMuted, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      brandBlue: Color.lerp(brandBlue, other.brandBlue, t)!,
      brandNavy: Color.lerp(brandNavy, other.brandNavy, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      success: Color.lerp(success, other.success, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
