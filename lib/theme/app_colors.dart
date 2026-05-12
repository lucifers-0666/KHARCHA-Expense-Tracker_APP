import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────
  static const Color bgPrimary        = Color(0xFF102321);
  static const Color bgSecondary      = Color(0xFF18312E);
  static const Color surface          = Color(0xFF223C39);
  static const Color surfaceElevated  = Color(0xFF2A4541);
  static const Color surfaceHigh      = Color(0xFF324F4B);

  // ── Accent ───────────────────────────────────────────────────
  static const Color accent           = Color(0xFF7BAE9E);
  static const Color accentSoft       = Color(0xFFA8CFC2);
  static const Color accentDim        = Color(0x337BAE9E);

  // ── Text ─────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFFFAF7F2);
  static const Color textSecondary    = Color(0xFFD6D0C4);
  static const Color textMuted        = Color(0xFF8A9A96);
  static const Color textDisabled     = Color(0xFF4A5E5A);

  // ── Borders ──────────────────────────────────────────────────
  static const Color border           = Color(0xFF35524D);
  static const Color borderSoft       = Color(0x1AFFFFFF);
  static const Color divider          = Color(0x14FFFFFF);

  // ── Semantic ─────────────────────────────────────────────────
  static const Color success          = Color(0xFF4CAF7D);
  static const Color successSoft      = Color(0x334CAF7D);
  static const Color warning          = Color(0xFFD9A441);
  static const Color warningSoft      = Color(0x33D9A441);
  static const Color danger           = Color(0xFFD96C6C);
  static const Color dangerSoft       = Color(0x33D96C6C);

  // ── Category Colors ──────────────────────────────────────────
  static const Color catFood          = Color(0xFFE8845C);
  static const Color catTransport     = Color(0xFF5B8ED6);
  static const Color catShopping      = Color(0xFFD4865A);
  static const Color catEntertain     = Color(0xFF8B72D4);
  static const Color catBills         = Color(0xFF4BADB5);
  static const Color catHealth        = Color(0xFF4CAF7D);
  static const Color catEducation     = Color(0xFF5B9BD6);
  static const Color catOther         = Color(0xFF8A9A96);

  // ── Shadow ───────────────────────────────────────────────────
  static const Color shadowColor      = Color(0x33000000);

  // ── Helper ───────────────────────────────────────────────────
  static Color categoryColor(String category) {
    return {
      'Food':          catFood,
      'Transport':     catTransport,
      'Shopping':      catShopping,
      'Entertainment': catEntertain,
      'Bills':         catBills,
      'Health':        catHealth,
      'Education':     catEducation,
      'Other':         catOther,
    }[category] ?? catOther;
  }

  static IconData categoryIcon(String category) {
    return {
      'Food':          Icons.restaurant_rounded,
      'Transport':     Icons.directions_car_rounded,
      'Shopping':      Icons.shopping_bag_rounded,
      'Entertainment': Icons.movie_rounded,
      'Bills':         Icons.receipt_long_rounded,
      'Health':        Icons.favorite_rounded,
      'Education':     Icons.school_rounded,
      'Other':         Icons.category_rounded,
    }[category] ?? Icons.category_rounded;
  }
}
