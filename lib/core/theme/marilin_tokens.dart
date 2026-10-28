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
  static const Color warning = Color(0xFFF59E0B);
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
    required this.warning,
    this.isDark = false,
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
  final Color warning;

  /// Whether these are the dark-theme tokens; picks the neutral roles below.
  final bool isDark;

  /// Main text and icons (the navy of the light theme).
  Color get ink => brandNavy;

  Color get inkSecondary =>
      isDark ? const Color(0xFFC9CDD4) : const Color(0xFF334155);

  /// Hints and placeholders.
  Color get inkHint =>
      isDark ? const Color(0xFF5E6570) : const Color(0xFF9CA3AF);

  Color get lineStrong =>
      isDark ? const Color(0xFF353B45) : const Color(0xFFD1D5DB);

  /// Subtle fills behind chips, rows and inputs.
  Color get fill => isDark ? const Color(0xFF1D2127) : const Color(0xFFF1F5F9);

  /// A strong status color for text and icons: as is in light, lifted in dark
  /// so it keeps its contrast over the near-black background.
  Color vivid(Color strong) {
    if (!isDark) return strong;
    final hsl = HSLColor.fromColor(strong);
    return hsl.lightness >= 0.62 ? strong : hsl.withLightness(0.62).toColor();
  }

  /// A pastel status background: as is in light. In dark, a translucent wash of
  /// the same hue at full strength, so tiles read blue/green/orange and not grey.
  Color soft(Color pastel) {
    if (!isDark) return pastel;
    final hsl = HSLColor.fromColor(pastel);
    return hsl
        .withLightness(0.55)
        .withSaturation(hsl.saturation < 0.6 ? 0.6 : hsl.saturation)
        .toColor()
        .withValues(alpha: 0.16);
  }

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
    warning: MarilinColors.warning,
  );

  /// Near-black neutral dark with solid cards one step lighter than the
  /// background. The accent is the light theme's blue.
  static const MarilinTokens dark = MarilinTokens(
    scaffoldMuted: Color(0xFF0B0D10),
    surface: Color(0xFF16191E),
    brandBlue: Color(0xFF3B82F6),
    brandNavy: Color(0xFFF4F5F7),
    textMuted: Color(0xFF8B929C),
    border: Color(0xFF262B33),
    success: Color(0xFF34D399),
    destructive: Color(0xFFF87171),
    accent: Color(0xFFFB923C),
    warning: Color(0xFFFBBF24),
    isDark: true,
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

  TextStyle get subtitle =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted);

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
    Color? warning,
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
      warning: warning ?? this.warning,
      isDark: isDark,
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
      warning: Color.lerp(warning, other.warning, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

/// `context.marilin.surface`: the current theme's tokens.
extension MarilinThemeContext on BuildContext {
  MarilinTokens get marilin => MarilinTokens.of(this);
}
