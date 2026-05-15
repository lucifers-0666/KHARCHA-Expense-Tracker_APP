import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Premium White Fintech Color System ──────────────────────────────────────
// Design direction: Apple Wallet · Revolut · Linear · Notion
// White-first, monochrome, luxury, calm, elegant
class AppColors {
  // ── Light Mode Backgrounds ──
  static const Color bg            = Color(0xFFF6F6F3); // primary bg
  static const Color bgPrimary     = Color(0xFFF6F6F3); // alias
  static const Color bgSecondary   = Color(0xFFEFEFEA); // secondary bg
  static const Color surface       = Color(0xFFFFFFFF); // card surface
  static const Color surface2      = Color(0xFFFAFAF8); // elevated surface
  static const Color surfaceOffset = Color(0xFFF0F0EC); // offset surface
  static const Color border        = Color(0xFFE5E5E0); // border
  static const Color divider       = Color(0x0D000000); // rgba(0,0,0,0.05)

  // ── Dark Mode Backgrounds ──
  static const Color bgDark            = Color(0xFF111315);
  static const Color bgPrimaryDark     = Color(0xFF111315);
  static const Color bgSecondaryDark   = Color(0xFF1B1E20);
  static const Color surfaceDark       = Color(0xFF1B1E20);
  static const Color surface2Dark      = Color(0xFF232729);
  static const Color surfaceOffsetDark = Color(0xFF2C3135);
  static const Color borderDark        = Color(0xFF2A2E32);
  static const Color dividerDark       = Color(0x14FFFFFF);

  // ── Text (Light) ──
  static const Color textPrimary   = Color(0xFF171717);
  static const Color textSecondary = Color(0xFF5C5C5C);
  static const Color textMuted     = Color(0xFF8B8B8B);
  static const Color textFaint     = Color(0xFFBBBBBB);
  static const Color textDisabled  = Color(0xFFCCCCCC);

  // ── Text (Dark) ──
  static const Color textPrimaryDark   = Color(0xFFF3F3F3);
  static const Color textSecondaryDark = Color(0xFFB8B8B8);
  static const Color textMutedDark     = Color(0xFF888888);
  static const Color textFaintDark     = Color(0xFF555555);

  // ── Accent System ──
  static const Color primary       = Color(0xFF2F5D50); // deep forest green
  static const Color primaryDark   = Color(0xFF1E3D35);
  static const Color primaryLight  = Color(0xFF4A7A6B);
  static const Color accent        = Color(0xFF2F5D50); // alias
  static const Color accentSoft    = Color(0xFFEAF0EE); // soft accent bg
  static const Color secondaryAccent = Color(0xFF7A8F85);
  static const Color softGreen     = Color(0xFFA9B8AE);

  // ── Semantic ──
  static const Color success    = Color(0xFF3FA76F);
  static const Color income     = Color(0xFF3FA76F);
  static const Color warning    = Color(0xFFC6923D);
  static const Color danger     = Color(0xFFD46A6A);
  static const Color expense    = Color(0xFFD46A6A);
  static const Color info       = Color(0xFF617AFA);
  static const Color gold       = Color(0xFFC6923D);
  static const Color dangerSoft = Color(0xFFFAEEEE);
  static const Color successSoft = Color(0xFFEAF5EF);
  static const Color warningSoft = Color(0xFFFAF3E8);
  static const Color infoSoft   = Color(0xFFEEF0FE);

  // ── Shadow ──
  static const Color shadow     = Color(0x0F000000); // rgba(0,0,0,0.06)
  static const Color shadowMd   = Color(0x1A000000); // rgba(0,0,0,0.10)

  // ── Legacy aliases kept for backward compat ──
  static const Color cardLight  = Color(0xFFFFFFFF);
  static const Color cardDark   = Color(0xFF232729);
  static const Color charcoal   = Color(0xFF1E1E1E);
  static const Color graphite   = Color(0xFF2D2D2D);
  static const Color slate      = Color(0xFF4A4A4A);
  static const Color luxuryAccent  = Color(0xFF7A8F85);
  static const Color mutedOlive    = Color(0xFFA9B8AE);
  static const Color shadowColor   = Color(0x0F000000);
  static const Color dividerLight  = Color(0x0D000000);

  // ── Premium Muted Category Colors ──
  static const Map<String, Color> categoryColors = {
    'Food'          : Color(0xFFB85C5C), // muted terracotta
    'Transport'     : Color(0xFF5577AA), // slate blue
    'Shopping'      : Color(0xFFB89A3E), // muted gold
    'Entertainment' : Color(0xFF7A6FAA), // dusty purple
    'Health'        : Color(0xFF4A8F6F), // forest green
    'Bills'         : Color(0xFF8B7355), // warm brown
    'Education'     : Color(0xFF4A7799), // steel blue
    'Others'        : Color(0xFF8B8B8B), // neutral gray
    'Other'         : Color(0xFF8B8B8B),
    'Salary'        : Color(0xFF3FA76F), // success green
    'Freelance'     : Color(0xFF4A7A6B), // teal
    'Investment'    : Color(0xFFC6923D), // amber
    'Business'      : Color(0xFF5D7AA8), // navy blue
    'Gift'          : Color(0xFFAA6B8B), // rose
    'Rent'          : Color(0xFFD46A6A), // soft red
    'EMI'           : Color(0xFFB85C5C), // terracotta
    'Subscriptions' : Color(0xFF7A6FAA), // dusty purple
  };

  static const Map<String, IconData> categoryIcons = {
    'Food'          : Icons.restaurant_rounded,
    'Transport'     : Icons.directions_car_rounded,
    'Shopping'      : Icons.shopping_bag_rounded,
    'Entertainment' : Icons.movie_rounded,
    'Health'        : Icons.favorite_rounded,
    'Bills'         : Icons.receipt_long_rounded,
    'Education'     : Icons.school_rounded,
    'Others'        : Icons.category_rounded,
    'Other'         : Icons.category_rounded,
    'Salary'        : Icons.account_balance_wallet_rounded,
    'Freelance'     : Icons.laptop_mac_rounded,
    'Investment'    : Icons.trending_up_rounded,
    'Business'      : Icons.business_center_rounded,
    'Gift'          : Icons.card_giftcard_rounded,
    'Rent'          : Icons.home_rounded,
    'EMI'           : Icons.credit_card_rounded,
    'Subscriptions' : Icons.subscriptions_rounded,
  };

  static IconData categoryIcon(String category) =>
      categoryIcons[category] ?? Icons.category_rounded;

  static Color categoryColor(String category) =>
      categoryColors[category] ?? categoryColors['Others']!;

  /// Resolve colors based on current brightness
  static Color bgFor(bool isDark)            => isDark ? bgDark : bg;
  static Color bgSecondaryFor(bool isDark)   => isDark ? bgSecondaryDark : bgSecondary;
  static Color surfaceFor(bool isDark)       => isDark ? surfaceDark : surface;
  static Color surface2For(bool isDark)      => isDark ? surface2Dark : surface2;
  static Color surfaceOffsetFor(bool isDark) => isDark ? surfaceOffsetDark : surfaceOffset;
  static Color borderFor(bool isDark)        => isDark ? borderDark : border;
  static Color textPrimaryFor(bool isDark)   => isDark ? textPrimaryDark : textPrimary;
  static Color textSecondaryFor(bool isDark) => isDark ? textSecondaryDark : textSecondary;
  static Color textMutedFor(bool isDark)     => isDark ? textMutedDark : textMuted;
  static Color textFaintFor(bool isDark)     => isDark ? textFaintDark : textFaint;
}

// ─── Spacing ─────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double base = 16.0;
  static const double lg   = 20.0;
  static const double xl   = 24.0;
  static const double x2l  = 32.0;
  static const double x3l  = 40.0;
  static const double x4l  = 48.0;
  static const double x5l  = 64.0;

  static const double pageHPad    = 20.0;
  static const double pageVPad    = 24.0;
  static const double cardPad     = 18.0;
  static const double sectionGap  = 28.0;

  // Legacy aliases
  static const double pagePadding    = 20.0;
  static const double cardPadding    = 18.0;
  static const double itemSpacing    = 12.0;
  static const double sectionSpacing = 24.0;
}

// ─── Radius ───────────────────────────────────────────────────────────────────
class AppRadius {
  AppRadius._();

  static const double xs   = 6.0;
  static const double sm   = 10.0;
  static const double md   = 14.0;
  static const double lg   = 18.0;
  static const double xl   = 22.0;
  static const double x2l  = 28.0;
  static const double full = 999.0;

  static BorderRadius circular(double r) => BorderRadius.circular(r);

  static const BorderRadius cardRadius   = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chipRadius   = BorderRadius.all(Radius.circular(full));
  static const BorderRadius inputRadius  = BorderRadius.all(Radius.circular(md));
  static const BorderRadius sheetRadius  = BorderRadius.vertical(top: Radius.circular(x2l));
  static const BorderRadius tileRadius   = BorderRadius.all(Radius.circular(14));
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
class AppTextStyles {
  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMuted = TextStyle(
    color: AppColors.textMuted,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static const TextStyle amount = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );

  static const TextStyle amountSmall = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static const TextStyle heading = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const TextStyle headline = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
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
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData light() => _buildLight();
  static ThemeData dark()  => _buildDark();
  static ThemeData get darkTheme => _buildDark();
  static ThemeData get lightTheme => _buildLight();

  static ThemeData _buildLight() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.light(
        primary:   AppColors.primary,
        secondary: AppColors.secondaryAccent,
        surface:   AppColors.surface,
        error:     AppColors.danger,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSecondary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
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
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textFaint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.border;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentSoft,
        shadowColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            );
          }
          return const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
      ),
    );
  }

  static ThemeData _buildDark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      fontFamily: 'Inter',
      colorScheme: const ColorScheme.dark(
        primary:    AppColors.softGreen,
        secondary:  AppColors.secondaryAccent,
        surface:    AppColors.surfaceDark,
        error:      AppColors.danger,
        onPrimary:  AppColors.bgDark,
        onSurface:  AppColors.textPrimaryDark,
        onSecondary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          fontFamily: 'Inter',
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondaryDark),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceDark,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2Dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.softGreen, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        hintStyle: const TextStyle(color: AppColors.textFaintDark, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.softGreen,
          foregroundColor: AppColors.bgDark,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.softGreen,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 0,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.bgDark;
          return AppColors.textFaintDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.softGreen;
          return AppColors.borderDark;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        shadowColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.softGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            );
          }
          return const TextStyle(
            color: AppColors.textMutedDark,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'Inter',
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.softGreen, size: 22);
          }
          return const IconThemeData(color: AppColors.textMutedDark, size: 22);
        }),
      ),
    );
  }
}
