import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark  => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg       = isDark ? AppColors.bgDark       : AppColors.bgLight;
    final surface  = isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
    final card     = isDark ? AppColors.cardDark     : AppColors.cardLight;
    final textPri  = isDark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final textSec  = isDark ? AppColors.textSecondaryDark: AppColors.textSecondaryLight;
    final textMuted= isDark ? AppColors.textMutedDark    : AppColors.textMutedLight;
    final divider  = isDark ? AppColors.dividerDark  : AppColors.dividerLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'PlusJakartaSans',
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary:   AppColors.charcoal,
        onPrimary: Colors.white,
        secondary: AppColors.luxuryAccent,
        onSecondary: Colors.white,
        error:     AppColors.danger,
        onError:   Colors.white,
        surface:   surface,
        onSurface: textPri,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPri,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        titleTextStyle: AppTextStyles.title.copyWith(color: textPri),
        iconTheme: IconThemeData(color: textPri, size: 22),
      ),
      cardTheme: CardTheme(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: BorderSide(color: divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.charcoal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.inputRadius,
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        labelStyle: AppTextStyles.caption.copyWith(color: textMuted),
        hintStyle: AppTextStyles.body.copyWith(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.mutedOlive : AppColors.charcoal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPri,
          side: BorderSide(color: divider, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          textStyle: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPri,
          textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? AppColors.mutedOlive : AppColors.charcoal,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: isDark ? AppColors.mutedOlive : AppColors.charcoal,
        unselectedItemColor: textMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.caption,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? (isDark ? AppColors.mutedOlive : AppColors.charcoal)
                : textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? (isDark ? AppColors.mutedOlive.withAlpha(80) : AppColors.charcoal.withAlpha(40))
                : divider),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? AppColors.charcoal
                : Colors.transparent),
        side: BorderSide(color: textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(4)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(AppRadius.md)),
        titleTextStyle: AppTextStyles.subtitle.copyWith(color: textPri),
        subtitleTextStyle: AppTextStyles.caption.copyWith(color: textMuted),
        iconColor: textSec,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surfaceOffDark : AppColors.graphite,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
        elevation: 0,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(AppRadius.xl)),
        elevation: 0,
        titleTextStyle: AppTextStyles.title.copyWith(color: textPri),
        contentTextStyle: AppTextStyles.body.copyWith(color: textSec),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: isDark ? AppColors.mutedOlive.withAlpha(60) : AppColors.charcoal.withAlpha(20),
        labelStyle: AppTextStyles.caption.copyWith(color: textSec),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.circular(AppRadius.full)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
