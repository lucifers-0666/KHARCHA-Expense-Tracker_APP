import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary:    AppColors.accent,
        secondary:  AppColors.accentSoft,
        surface:    AppColors.surface,
        error:      AppColors.danger,
        onPrimary:  AppColors.bgPrimary,
        onSecondary: AppColors.bgPrimary,
        onSurface:  AppColors.textPrimary,
        onError:    AppColors.textPrimary,
      ),
      fontFamily: 'PlusJakartaSans',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headline,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // Card
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.textDisabled),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
        floatingLabelStyle: AppTextStyles.caption.copyWith(color: AppColors.accent),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.bgPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.button,
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.button,
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.button,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.accentDim,
        labelStyle: AppTextStyles.caption,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.chipRadius),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        elevation: 0,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 0,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: AppTextStyles.body,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.tileRadius),
        behavior: SnackBarBehavior.floating,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.accent,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.bgPrimary : AppColors.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.accent : AppColors.surface),
      ),

      // Slider
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.accentDim,
      ),

      // Progress indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.border,
      ),

      textTheme: const TextTheme(
        displayLarge:  AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        headlineMedium: AppTextStyles.headline,
        titleLarge:    AppTextStyles.title,
        titleMedium:   AppTextStyles.titleMedium,
        bodyLarge:     AppTextStyles.body,
        bodyMedium:    AppTextStyles.bodyMedium,
        labelLarge:    AppTextStyles.button,
        labelSmall:    AppTextStyles.caption,
      ),
    );
  }
}

// Keep old AppColors reference for backward compat
class AppColorsLegacy {
  static const Color primary    = AppColors.accent;
  static const Color accent     = AppColors.accentSoft;
  static const Color success    = AppColors.success;
  static const Color danger     = AppColors.danger;
  static const Color warning    = AppColors.warning;
  static const Color info       = AppColors.catEducation;
  static const Color textPrimary   = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
}
