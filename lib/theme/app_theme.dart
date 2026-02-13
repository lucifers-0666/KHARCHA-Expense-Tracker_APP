import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2F3A5F);
  static const primaryDark = Color(0xFF1F2846);
  static const accent = Color(0xFF2BB3A6);
  static const accentDark = Color(0xFF1C8E84);
  static const surface = Color(0xFFF7F8FA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1C2230);
  static const textSecondary = Color(0xFF5B6476);
  static const border = Color(0xFFE3E6EC);
  static const success = Color(0xFF2E9E6F);
  static const danger = Color(0xFFE25555);
  static const info = Color(0xFF3E7BFA);
}

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accent,
      onSecondary: Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      background: AppColors.surface,
      onBackground: AppColors.textPrimary,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'Roboto',
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}
