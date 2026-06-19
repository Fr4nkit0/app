import 'package:flutter/material.dart';
import 'package:app/core/theme/sales_tokens.dart';

abstract final class AppTheme {
  // ─── Brand colors ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF0D1B3E);
  static const Color _secondary = Color(0xFFBF1B1B);
  static const Color _navBlue = Color(0xFF1565C0);
  static const Color _darkText = Color(0xFF111827);
  static const Color _error = Color(0xFFB3261E);

  // ─── ColorScheme — paleta limpia (sin crema) ──────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,

    primary: _primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1E3A6E),
    onPrimaryContainer: Color(0xFFD0E4FF),

    secondary: _secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFDAD6),
    onSecondaryContainer: Color(0xFF410002),

    tertiary: Color(0xFFBC6700),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDDB4),
    onTertiaryContainer: Color(0xFF2B1700),

    // Surfaces — todos blancos/gris neutro
    surface: Colors.white,
    onSurface: _darkText,
    surfaceContainerHighest: Color(0xFFF3F4F6),
    surfaceContainerHigh: Color(0xFFF9FAFB),
    surfaceContainer: Color(0xFFF9FAFB),
    surfaceContainerLow: Colors.white,

    error: _error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    // Outlines — gris neutro
    outline: Color(0xFF9CA3AF),
    outlineVariant: Color(0xFFE5E7EB),

    onSurfaceVariant: Color(0xFF6B7280),
    inverseSurface: Color(0xFF1F2937),
    onInverseSurface: Colors.white,
  );

  // ─── Tema ─────────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: Colors.white,
      extensions: const [SalesTokens.light],

      // ── PageTransitions: evitar flash con color de fondo ──────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),

      // ── AppBar: blanco limpio para screens secundarias ────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _primary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        shadowColor: Color(0x14000000),
        titleTextStyle: TextStyle(
          color: _primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: _primary),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondary,
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
          foregroundColor: _primary,
          side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _navBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ── NavigationBar: blanco + azul activo ──────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: const Color(0x14000000),
        surfaceTintColor: Colors.transparent,
        indicatorColor: _navBlue,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return const IconThemeData(color: Color(0xFF6B7280), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: _navBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return const TextStyle(color: Color(0xFF6B7280), fontSize: 12);
        }),
      ),

      // ── Inputs ───────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _navBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error),
        ),
        labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        floatingLabelStyle: const TextStyle(
          color: _navBlue,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF3F4F6),
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ── Tipografía ───────────────────────────────────────────────────────
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w800,
          fontSize: 26,
        ),
        titleLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleSmall: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        bodyLarge: TextStyle(color: _darkText, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: _darkText, fontSize: 14, height: 1.4),
        bodySmall: TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        labelMedium: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
