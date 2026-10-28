import 'package:flutter/material.dart';
import 'package:app/core/theme/marilin_tokens.dart';
import 'package:app/core/theme/sales_tokens.dart';

/// The colors one theme needs. [AppTheme] builds the light and the dark theme
/// from the same rules, so a widget styled by the theme works in both.
class _Palette {
  const _Palette({
    required this.brightness,
    required this.tokens,
    required this.sales,
    required this.text,
    required this.textMuted,
    required this.textHint,
    required this.surface,
    required this.surfaceSoft,
    required this.surfaceSofter,
    required this.line,
    required this.lineStrong,
    required this.divider,
    required this.primaryContainer,
    required this.secondaryContainer,
    required this.snackBar,
    required this.shadow,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
  });

  final Brightness brightness;
  final MarilinTokens tokens;
  final SalesTokens sales;
  final Color text;
  final Color textMuted;
  final Color textHint;
  final Color surface;
  final Color surfaceSoft;
  final Color surfaceSofter;
  final Color line;
  final Color lineStrong;
  final Color divider;
  final Color primaryContainer;
  final Color secondaryContainer;
  final Color snackBar;
  final Color shadow;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
}

abstract final class AppTheme {
  // Light: the values the app always had.
  static const _Palette _light = _Palette(
    brightness: Brightness.light,
    tokens: MarilinTokens.light,
    sales: SalesTokens.light,
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF6B7280),
    textHint: Color(0xFF9CA3AF),
    surface: Colors.white,
    surfaceSoft: Color(0xFFF9FAFB),
    surfaceSofter: Color(0xFFF3F4F6),
    line: Color(0xFFE5E7EB),
    lineStrong: Color(0xFFD1D5DB),
    divider: Color(0xFFF3F4F6),
    primaryContainer: Color(0xFFDBEAFE),
    secondaryContainer: Color(0xFFE2E8F0),
    snackBar: Color(0xFF1F2937),
    shadow: Color(0x14000000),
    error: Color(0xFFB3261E),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
  );

  // Dark: near-black neutral (no blue tint) with the light theme's blue as accent.
  static const _Palette _dark = _Palette(
    brightness: Brightness.dark,
    tokens: MarilinTokens.dark,
    sales: SalesTokens.dark,
    text: Color(0xFFF4F5F7),
    textMuted: Color(0xFF8B929C),
    textHint: Color(0xFF5E6570),
    surface: Color(0xFF15181D),
    surfaceSoft: Color(0xFF1D2127),
    surfaceSofter: Color(0xFF262B33),
    line: Color(0xFF262B33),
    lineStrong: Color(0xFF353B45),
    divider: Color(0xFF1D2127),
    primaryContainer: Color(0xFF1E3A8A),
    secondaryContainer: Color(0xFF262B33),
    snackBar: Color(0xFF262B33),
    shadow: Color(0x59000000),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
  );

  static ThemeData get lightTheme => _build(_light);

  static ThemeData get darkTheme => _build(_dark);

  static ThemeData _build(_Palette p) {
    final t = p.tokens;
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: t.brandBlue,
      onPrimary: Colors.white,
      primaryContainer: p.primaryContainer,
      onPrimaryContainer: t.brandNavy,
      secondary: t.brandNavy,
      onSecondary: p.surface,
      secondaryContainer: p.secondaryContainer,
      onSecondaryContainer: t.brandNavy,
      tertiary: const Color(0xFFBC6700),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFDDB4),
      onTertiaryContainer: const Color(0xFF2B1700),
      surface: p.surface,
      onSurface: p.text,
      surfaceContainerHighest: p.surfaceSofter,
      surfaceContainerHigh: p.surfaceSoft,
      surfaceContainer: p.surfaceSoft,
      surfaceContainerLow: p.surface,
      error: p.error,
      onError: p.onError,
      errorContainer: p.errorContainer,
      onErrorContainer: p.onErrorContainer,
      outline: p.textHint,
      outlineVariant: p.line,
      onSurfaceVariant: p.textMuted,
      inverseSurface: p.snackBar,
      onInverseSurface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      extensions: [t, p.sales],
      scaffoldBackgroundColor: t.scaffoldMuted,

      // ── PageTransitions: evitar flash con color de fondo ──────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ── AppBar: superficie limpia para screens secundarias ────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: t.brandNavy,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        shadowColor: p.shadow,
        titleTextStyle: TextStyle(
          color: t.brandNavy,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: t.brandNavy),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.brandBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.brandNavy,
          side: BorderSide(color: p.lineStrong, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.brandBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.brandBlue,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── NavigationBar: superficie + azul activo ──────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        elevation: 0,
        shadowColor: p.shadow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.brandBlue,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return IconThemeData(color: p.textMuted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: t.brandBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(color: p.textMuted, fontSize: 12);
        }),
      ),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: t.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.error),
        ),
        labelStyle: TextStyle(color: p.textHint),
        floatingLabelStyle: TextStyle(
          color: t.brandBlue,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: p.textHint),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.line),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.snackBar,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Tipografía ───────────────────────────────────────────────────────
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w800,
          fontSize: 26,
        ),
        titleLarge: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(color: p.text, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: p.text, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(
          color: p.textMuted,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: p.text,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          color: p.textMuted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
