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
  static const Color bgPrimary = Color(0xFF0A0E13); // alias
  static const Color bgSecondary = Color(0xFF111820); // alias
  static const Color surface = Color(0xFF111820);
  static const Color surface2 = Color(0xFF161E28);
  static const Color surfaceOffset = Color(0xFF1C2733);
  static const Color surfaceElevated = Color(0xFF1C2733); // alias
  static const Color border = Color(0xFF1E2D3D);

  // Text
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textMuted = Color(0xFF7A8FA6);
  static const Color textFaint = Color(0xFF3D5166);
  static const Color textSecondary = Color(0xFF7A8FA6); // alias for textMuted
  static const Color textDisabled = Color(0xFF3D5166); // alias for textFaint

  // Semantic
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFA726);
  static const Color gold = Color(0xFFFFD700);

  // Semantic aliases used by main.dart and widgets
  static const Color accent = Color(0xFF00B4C5); // alias for primary
  static const Color accentSoft = Color(0xFF0D2B2E); // alias for primarySurface
  static const Color success = Color(0xFF22C55E); // alias for income
  static const Color danger = Color(0xFFFF5C5C); // alias for expense
  static const Color dangerSoft = Color(0xFF2A1515); // soft red bg
  static const Color info = Color(0xFF3B82F6); // blue info

  // Light/Dark theme compatibility (from separate app_colors.dart, now consolidated)
  static const Color textPrimaryLight = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFF5F5F5);
  static const Color textSecondaryLight = Color(0xFF4A4A4A);
  static const Color textSecondaryDark = Color(0xFFCFCFCF);
  static const Color textMutedLight = Color(0xFF8A8A8A);
  static const Color textMutedDark = Color(0xFF888888);

  static const Color surfaceLight = Color(0xFFF2F1EC);
  static const Color surfaceDark = Color(0xFF1C1C1C);
  static const Color bgLight = Color(0xFFF8F7F4);
  static const Color bgDark = Color(0xFF111111);
  static const Color charcoal = Color(0xFF1E1E1E);
  static const Color graphite = Color(0xFF2D2D2D);
  static const Color slate = Color(0xFF4A4A4A);
  static const Color luxuryAccent = Color(0xFF7C8C7A);
  static const Color mutedOlive = Color(0xFFA4B494);

  static const Color dividerLight = Color(0x0F000000);
  static const Color dividerDark = Color(0x14FFFFFF);

  static const Color cardDark = Color(0xFF232323);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color shadowColor = Color(0x14000000);

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
    'Other': Color(0xFF95A5A6),
    'Salary': Color(0xFF27AE60),
    'Freelance': Color(0xFF1ABC9C),
    'Investment': Color(0xFFF39C12),
    'Business': Color(0xFF8E44AD),
    'Gift': Color(0xFFEC4899),
    'Rent': Color(0xFFEF4444),
    'EMI': Color(0xFFF97316),
    'Subscriptions': Color(0xFF8B5CF6),
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
    'Other': Icons.category_rounded,
    'Salary': Icons.account_balance_wallet_rounded,
    'Freelance': Icons.laptop_mac_rounded,
    'Investment': Icons.trending_up_rounded,
    'Business': Icons.business_center_rounded,
    'Gift': Icons.card_giftcard_rounded,
    'Rent': Icons.home_rounded,
    'EMI': Icons.credit_card_rounded,
    'Subscriptions': Icons.subscriptions_rounded,
  };

  /// Returns the icon for a category, falling back to category_rounded.
  static IconData categoryIcon(String category) =>
      categoryIcons[category] ?? Icons.category_rounded;

  /// Returns color for a category, falling back to 'Others'.
  static Color categoryColor(String category) =>
      categoryColors[category] ?? categoryColors['Others']!;
}

// ─── Spacing ────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double x2l = 32.0;
  static const double x3l = 40.0;
  static const double x4l = 48.0;
  static const double x5l = 64.0;

  static const double pageHPad = 20.0;
  static const double pageVPad = 24.0;
  static const double cardPad = 16.0;
  static const double sectionGap = 28.0;

  // Legacy aliases for backward compatibility
  static const double pagePadding = 20.0;
  static const double cardPadding = 16.0;
  static const double itemSpacing = 12.0;
  static const double sectionSpacing = 24.0;
}

// ─── Radius ────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double x2l = 24.0;
  static const double full = 999.0;

  static BorderRadius circular(double r) => BorderRadius.circular(r);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius buttonRadius = BorderRadius.all(
    Radius.circular(md),
  );
  static const BorderRadius chipRadius = BorderRadius.all(
    Radius.circular(full),
  );
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(x2l),
  );

  // Legacy aliases
  static const BorderRadius tileRadius = BorderRadius.all(Radius.circular(14));
}

// ─── Text Styles ─────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle amount = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle amountSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle heading = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle title = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );
}

// ─── Theme ──────────────────────────────────────────────────────────────────
class AppTheme {
  /// Named constructor used by: AppTheme.light()
  static ThemeData light() => _buildTheme(brightness: Brightness.light);

  /// Named constructor used by: AppTheme.dark()
  static ThemeData dark() => darkTheme;

  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData _buildTheme({required Brightness brightness}) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
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
      cardTheme: CardThemeData(
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
}
