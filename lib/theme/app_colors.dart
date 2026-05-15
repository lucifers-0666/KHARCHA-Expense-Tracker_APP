import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Light Mode Surfaces ──────────────────────────────────────────
  static const Color bgLight          = Color(0xFFF8F7F4);
  static const Color surfaceLight     = Color(0xFFF2F1EC);
  static const Color surfaceOffLight  = Color(0xFFECE9E1);
  static const Color cardLight        = Color(0xFFFFFFFF);

  // ── Dark Mode Surfaces ───────────────────────────────────────────
  static const Color bgDark           = Color(0xFF111111);
  static const Color surfaceDark      = Color(0xFF1C1C1C);
  static const Color surfaceOffDark   = Color(0xFF252525);
  static const Color cardDark         = Color(0xFF232323);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimaryLight  = Color(0xFF1E1E1E);
  static const Color textSecondaryLight= Color(0xFF4A4A4A);
  static const Color textMutedLight    = Color(0xFF8A8A8A);

  static const Color textPrimaryDark   = Color(0xFFF5F5F5);
  static const Color textSecondaryDark = Color(0xFFCFCFCF);
  static const Color textMutedDark     = Color(0xFF888888);

  // ── Accents ───────────────────────────────────────────────────────
  static const Color charcoal         = Color(0xFF1E1E1E);
  static const Color graphite         = Color(0xFF2D2D2D);
  static const Color slate            = Color(0xFF4A4A4A);
  static const Color luxuryAccent     = Color(0xFF7C8C7A);
  static const Color mutedOlive       = Color(0xFFA4B494);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color success          = Color(0xFF4CAF7D);
  static const Color warning          = Color(0xFFD9A441);
  static const Color danger           = Color(0xFFD96C6C);
  static const Color income           = Color(0xFF4CAF7D);
  static const Color expense          = Color(0xFFD96C6C);

  // ── Utility ───────────────────────────────────────────────────────
  static const Color dividerLight     = Color(0x0F000000);
  static const Color dividerDark      = Color(0x14FFFFFF);
  static const Color shadowColor      = Color(0x14000000);
  static const Color transparent      = Colors.transparent;

  // ── Category Colors ───────────────────────────────────────────────
  static const Map<String, Color> categoryColors = {
    'Food':          Color(0xFFD9A441),
    'Transport':     Color(0xFF7C8C7A),
    'Shopping':      Color(0xFFA4B494),
    'Bills':         Color(0xFF4A4A4A),
    'Entertainment': Color(0xFF8C7A7C),
    'Health':        Color(0xFF4CAF7D),
    'Education':     Color(0xFF6A8CAF),
    'Income':        Color(0xFF4CAF7D),
    'Other':         Color(0xFF9A9A9A),
  };

  static Color categoryColor(String cat) =>
      categoryColors[cat] ?? const Color(0xFF9A9A9A);
}
