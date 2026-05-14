import 'package:flutter/material.dart';

/// AppTheme - Definición centralizada del sistema de diseño de Marilin.
/// 
/// Sigue las guías de Material 3 Expressive (M3E) con un enfoque en:
/// - Jerarquía visual clara mediante tipografía enfatizada.
/// - Formas orgánicas y consistentes (Large Increased Shapes).
/// - Paleta de alto impacto con accesibilidad verificada.
abstract final class AppTheme {
  // ─── Paleta de Colores (Tokens Base) ───────────────────────────────────────
  static const Color _primary = Color(0xFF0D1B3E); // Azul marino profundo
  static const Color _secondary = Color(0xFFBF1B1B); // Rojo vibrante CTA
  static const Color _tertiary = Color(0xFFBC6700); // Naranja oscuro (ajustado para contraste)
  static const Color _surface = Color(0xFFF5E6C8); // Crema base
  static const Color _surfaceVariant = Color(0xFFEAD9B8); // Crema oscuro / Contornos
  static const Color _onSurfaceVariant = Color(0xFF4D4639); // Texto secundario sobre crema
  static const Color _darkText = Color(0xFF111827); // Texto principal casi negro
  static const Color _error = Color(0xFFB3261E); // Rojo error M3

  // ─── ColorScheme ─────────────────────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    
    // Brand Colors
    primary: _primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1E3A6E),
    onPrimaryContainer: Color(0xFFD0E4FF),
    
    secondary: _secondary,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFFDAD6),
    onSecondaryContainer: Color(0xFF410002),

    tertiary: _tertiary,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFDDB4),
    onTertiaryContainer: Color(0xFF2B1700),

    // Surface & Background
    surface: _surface,
    onSurface: _darkText,
    surfaceContainerHighest: _surfaceVariant,
    surfaceContainerHigh: Color(0xFFF0E1C0),
    surfaceContainer: _surface,
    surfaceContainerLow: Color(0xFFFAF1DF),
    
    error: _error,
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),

    outline: _onSurfaceVariant,
    outlineVariant: _surfaceVariant,
  );

  // ─── Geometría (Shape Tokens) ─────────────────────────────────────────────
  static const double _radiusFull = 32.0; // Botones y FABs
  static const double _radiusLarge = 28.0; // Cards
  static const double _radiusMedium = 24.0; // Inputs y Sheets

  // ─── Tema Principal ───────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _colorScheme,
      scaffoldBackgroundColor: _surface,

      // ── AppBar (M3E: Center Aligned, Emphasized) ──────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // ── Buttons (M3E: Extra Large Increased Shapes) ───────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 60), // Taller para M3E
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusFull),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800, // Extra Bold
            letterSpacing: 0.2,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withOpacity(0.1)),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primary,
          side: const BorderSide(color: _primary, width: 2),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radiusFull),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _secondary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
          ),
        ),
      ),

      // ── FAB (M3E: Large / Circular) ──────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusFull),
        ),
      ),

      // ── Navigation Bar (M3E: Labels emphasized) ──────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _primary,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Input Decoration (M3E: Medium-Large Shapes) ──────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          borderSide: const BorderSide(color: _surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          borderSide: const BorderSide(color: _surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusMedium),
          borderSide: const BorderSide(color: _error),
        ),
        labelStyle: const TextStyle(color: _onSurfaceVariant),
        floatingLabelStyle: const TextStyle(
          color: _primary,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── Cards (M3E: High Radius, Low Elevation) ──────────────────────────
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusLarge),
          side: const BorderSide(color: _surfaceVariant, width: 1.5),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // ── Feedback (SnackBar) ───────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _primary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Tipografía (M3E Expressive Scale) ────────────────────────────────
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w900, // Black weight for display
          fontSize: 42,
          letterSpacing: -1.5,
        ),
        headlineLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w800,
          fontSize: 34,
          letterSpacing: -1.0,
        ),
        headlineMedium: TextStyle(
          color: _primary,
          fontWeight: FontWeight.w700,
          fontSize: 28,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w700,
          fontSize: 22,
        ),
        titleMedium: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        bodyLarge: TextStyle(
          color: _darkText,
          fontSize: 16,
          height: 1.5,
          letterSpacing: 0.15,
        ),
        bodyMedium: TextStyle(
          color: _darkText,
          fontSize: 14,
          height: 1.4,
          letterSpacing: 0.25,
        ),
        labelLarge: TextStyle(
          color: _darkText,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

