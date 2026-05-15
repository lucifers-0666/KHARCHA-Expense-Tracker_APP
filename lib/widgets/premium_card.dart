import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final bool hasBorder;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
    this.radius = AppRadius.xl,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        color ?? (isDark ? AppColors.cardDark : AppColors.cardLight);
    final border = hasBorder
        ? Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          )
        : null;

    final content = Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );

    if (onTap != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(onTap: onTap, child: content),
        ),
      );
    }
    return content;
  }
}
