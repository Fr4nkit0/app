import 'package:flutter/material.dart';

/// Semantic color tokens and text styles for the Sales module.
///
/// Register via [ThemeData.extensions]:
/// ```dart
/// extensions: [SalesTokens.light],
/// ```
///
/// Consume in widgets:
/// ```dart
/// final tokens = Theme.of(context).extension<SalesTokens>()!;
/// ```
class SalesTokens extends ThemeExtension<SalesTokens> {
  const SalesTokens({
    required this.primary,
    required this.accent,
    required this.destructive,
  });

  /// Azul principal de tracking / acciones primarias.
  final Color primary;

  /// Naranja para CTAs de énfasis secundario.
  final Color accent;

  /// Rojo semántico para deuda, errores y estados críticos.
  final Color destructive;

  /// Gris neutro para bordes y controles inactivos (Tailwind gray-300).
  static const Color muted = Color(0xFFD1D5DB);

  /// TextStyle con [FontFeature.tabularFigures] para totales y subtotales.
  /// Evita layout-shift cuando la cantidad de dígitos cambia.
  TextStyle get tabularStyle => const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
      );

  // ─── Preset ───────────────────────────────────────────────────────────────

  static const SalesTokens light = SalesTokens(
    primary: Color(0xFF2563EB),
    accent: Color(0xFFEA580C),
    destructive: Color(0xFFDC2626),
  );

  // ─── ThemeExtension contract ──────────────────────────────────────────────

  @override
  SalesTokens copyWith({
    Color? primary,
    Color? accent,
    Color? destructive,
  }) {
    return SalesTokens(
      primary: primary ?? this.primary,
      accent: accent ?? this.accent,
      destructive: destructive ?? this.destructive,
    );
  }

  @override
  SalesTokens lerp(SalesTokens? other, double t) {
    if (other == null) return this;
    return SalesTokens(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
    );
  }
}
