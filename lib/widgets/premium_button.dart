import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, secondary, ghost, danger }

class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool loading;
  final bool fullWidth;
  final IconData? icon;
  final double height;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.fullWidth = true,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg, fg;
    Border? border;
    switch (variant) {
      case ButtonVariant.primary:
        bg = isDark ? AppColors.mutedOlive : AppColors.charcoal;
        fg = Colors.white;
        break;
      case ButtonVariant.secondary:
        bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
        fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        border = Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1.5,
        );
        break;
      case ButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        break;
      case ButtonVariant.danger:
        bg = AppColors.danger.withAlpha(20);
        fg = AppColors.danger;
        break;
    }

    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: ClipRRect(
        borderRadius: AppRadius.buttonRadius,
        child: Material(
          color: bg,
          child: InkWell(
            onTap: loading ? null : onPressed,
            child: Container(
              decoration: BoxDecoration(
                border: border,
                borderRadius: AppRadius.buttonRadius,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: loading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(fg),
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: fullWidth
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 18, color: fg),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          label,
                          style: AppTextStyles.subtitle.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
