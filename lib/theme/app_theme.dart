import 'package:flutter/material.dart';

class AppColors {
  // Light Theme Colors
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
  static const warning = Color(0xFFFFA500);
}

class AppColorsDark {
  // Dark Theme Colors
  static const primary = Color(0xFF3D4A6E);
  static const primaryDark = Color(0xFF1A1F35);
  static const accent = Color(0xFF35C9B8);
  static const accentDark = Color(0xFF2AA595);
  static const surface = Color(0xFF121212);
  static const card = Color(0xFF1E1E1E);
  static const textPrimary = Color(0xFFE8EAF0);
  static const textSecondary = Color(0xFFB0B3BF);
  static const border = Color(0xFF2C2C2C);
  static const success = Color(0xFF3FAF7C);
  static const danger = Color(0xFFEF6B6B);
  static const info = Color(0xFF5A94FF);
  static const warning = Color(0xFFFFA500);
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

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColorsDark.primary,
      onPrimary: Colors.white,
      secondary: AppColorsDark.accent,
      onSecondary: Colors.white,
      error: AppColorsDark.danger,
      onError: Colors.white,
      surface: AppColorsDark.card,
      onSurface: AppColorsDark.textPrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColorsDark.surface,
      fontFamily: 'Roboto',
      useMaterial3: true,
      brightness: Brightness.dark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColorsDark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColorsDark.accent, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.card,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.accent,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
