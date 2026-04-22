// lib/theme/app_theme.dart
// Aesthetic: Bloomberg Terminal meets modern glassmorphism
// Dark navy base, amber accent, tight monospaced data — premium trading feel

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ── Base palette ─────────────────────────────────────────────────────────
  static const bg          = Color(0xFF060B18);   // near-black navy
  static const surface     = Color(0xFF0D1526);   // card background
  static const surfaceAlt  = Color(0xFF111E35);   // elevated surface
  static const border      = Color(0xFF1A2B47);   // subtle borders
  static const borderGlow  = Color(0xFF1E3560);   // hover/active border

  // ── Signal colors ─────────────────────────────────────────────────────────
  static const bullish     = Color(0xFF00D4A0);   // teal-green (not plain green)
  static const bearish     = Color(0xFFFF4757);   // vivid red
  static const sideways    = Color(0xFFFFB300);   // deep amber
  static const accent      = Color(0xFF4D8AF0);   // electric blue

  // ── Text ──────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFFE2EAF8);
  static const textSecondary = Color(0xFF6B89B4);
  static const textMuted     = Color(0xFF3A5070);
  static const textData      = Color(0xFF8BAAD8);   // for numeric data

  // ── Bias backgrounds (semi-transparent tints) ─────────────────────────────
  static const bullishBg   = Color(0xFF001F18);
  static const bearishBg   = Color(0xFF1F0610);
  static const sidewaysBg  = Color(0xFF1F1600);

  // ── Helpers ───────────────────────────────────────────────────────────────
  static Color forBias(String bias) {
    switch (bias.toLowerCase()) {
      case 'bullish': return bullish;
      case 'bearish': return bearish;
      default:        return sideways;
    }
  }

  static Color bgForBias(String bias) {
    switch (bias.toLowerCase()) {
      case 'bullish': return bullishBg;
      case 'bearish': return bearishBg;
      default:        return sidewaysBg;
    }
  }

  static IconData iconForBias(String bias) {
    switch (bias.toLowerCase()) {
      case 'bullish': return Icons.trending_up_rounded;
      case 'bearish': return Icons.trending_down_rounded;
      default:        return Icons.trending_flat_rounded;
    }
  }
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary:   AppColors.accent,
        surface:   AppColors.surface,
        onSurface: AppColors.textPrimary,
        error:     AppColors.bearish,
      ),
      textTheme: GoogleFonts.ibmPlexMonoTextTheme(base.textTheme).apply(
        bodyColor:    AppColors.textSecondary,
        displayColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color:        AppColors.surface,
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      dividerColor: AppColors.border,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
    );
  }
}
