import 'package:flutter/material.dart';

class CarolPalette {
  const CarolPalette._({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.red,
    required this.redGlow,
    required this.redDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.borderFocus,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color red;
  final Color redGlow;
  final Color redDim;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color borderFocus;

  static CarolPalette of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const CarolPalette._(
        bg: Color(0xFF0A0E1A),
        surface: Color(0xFF111827),
        surfaceAlt: Color(0xFF1C2333),
        red: Color(0xFFE53E3E),
        redGlow: Color(0x33E53E3E),
        redDim: Color(0xFF9B2C2C),
        textPrimary: Color(0xFFF7FAFC),
        textSecondary: Color(0xFF8A98B4),
        border: Color(0xFF2D3748),
        borderFocus: Color(0xFFE53E3E),
      );
    }

    return const CarolPalette._(
      bg: Color(0xFFF7F9FC),
      surface: Color(0xFFFFFFFF),
      surfaceAlt: Color(0xFFF2F4F8),
      red: Color(0xFFE53E3E),
      redGlow: Color(0x1AE53E3E),
      redDim: Color(0xFFB83232),
      textPrimary: Color(0xFF111827),
      textSecondary: Color(0xFF5B6477),
      border: Color(0xFFD8DEE9),
      borderFocus: Color(0xFFE53E3E),
    );
  }
}
