import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Primary Teal Palette
  static const Color primary = Color(0xFF00B4C5);
  static const Color primaryDark = Color(0xFF007A87);
  static const Color primaryLight = Color(0xFF4DD8E6);
  static const Color primarySurface = Color(0xFF0D2B2E);

  // Background Layers (dark fintech)
  static const Color bg = Color(0xFF0A0E13);
  static const Color surface = Color(0xFF111820);
  static const Color surface2 = Color(0xFF161E28);
  static const Color surfaceOffset = Color(0xFF1C2733);
  static const Color border = Color(0xFF1E2D3D);

  // Text
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textMuted = Color(0xFF7A8FA6);
  static const Color textFaint = Color(0xFF3D5166);

  // Semantic
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFA726);
  static const Color gold = Color(0xFFFFD700);

  // Categories
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFFF6B6B),
    'Transport': Color(0xFF4ECDC4),
    'Shopping': Color(0xFFFFBE0B),
    'Entertainment': Color(0xFF9B59B6),
    'Health': Color(0xFF2ECC71),
    'Bills': Color(0xFFE74C3C),
    'Education': Color(0xFF3498DB),
    'Others': Color(0xFF95A5A6),
    'Salary': Color(0xFF27AE60),
    'Freelance': Color(0xFF1ABC9C),
    'Investment': Color(0xFFF39C12),
    'Business': Color(0xFF8E44AD),
  };

  static const Map<String, IconData> categoryIcons = {
    'Food': Icons.restaurant_rounded,
    'Transport': Icons.directions_car_rounded,
    'Shopping': Icons.shopping_bag_rounded,
    'Entertainment': Icons.movie_rounded,
    'Health': Icons.favorite_rounded,
    'Bills': Icons.receipt_long_rounded,
    'Education': Icons.school_rounded,
    'Others': Icons.category_rounded,
    'Salary': Icons.account_balance_wallet_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Investment': Icons.trending_up_rounded,
    'Business': Icons.business_center_rounded,
  };
}

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.expense,
      onPrimary: AppColors.bg,
      onSurface: AppColors.textPrimary,
    ),
    fontFamily: 'SF Pro Display',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
      hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bg,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }
        return const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primary, size: 24);
        }
        return const IconThemeData(color: AppColors.textMuted, size: 24);
      }),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
