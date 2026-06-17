import 'package:flutter/material.dart';

class AvatarColors {
  final Color background;
  final Color foreground;
  const AvatarColors({required this.background, required this.foreground});
}

abstract final class AvatarUtils {
  /// Extracts up to 2 uppercase initials from a full name.
  static String getInitials(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) return '';
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts.first;
      final last = parts.last;
      if (first.isNotEmpty && last.isNotEmpty) {
        return '${first[0]}${last[0]}'.toUpperCase();
      }
    }
    return cleaned.substring(0, cleaned.length.clamp(0, 2)).toUpperCase();
  }

  /// Calculates a deterministic, visually pleasing pastel color from a string seed.
  static Color getPastelColor(String seed) {
    if (seed.trim().isEmpty) {
      return const Color(0xFF1565C0);
    }
    var hash = 0;
    for (var i = 0; i < seed.length; i++) {
      hash = seed.codeUnitAt(i) + ((hash << 5) - hash);
    }
    final double h = ((hash & 0xFFFFFF) % 360).toDouble();
    return HSLColor.fromAHSL(1.0, h, 0.6, 0.75).toColor();
  }

  /// Computes background and foreground colors for an avatar based on selection and custom inputs.
  static AvatarColors getColors(
    String name, {
    bool selected = false,
    Color? baseColor,
  }) {
    const defaultColor = Color(0xFF1565C0);
    final targetColor = baseColor ?? defaultColor;
    if (selected) {
      return const AvatarColors(
        background: defaultColor,
        foreground: Colors.white,
      );
    }
    return AvatarColors(
      background: targetColor.withValues(alpha: 0.1),
      foreground: targetColor,
    );
  }
}
