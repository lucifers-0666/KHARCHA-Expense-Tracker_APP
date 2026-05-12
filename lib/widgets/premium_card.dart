import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool elevated;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? (elevated ? AppColors.surfaceElevated : AppColors.surface);
    final br = borderRadius ?? AppRadius.cardRadius;

    Widget content = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          child: content,
        ),
      );
    }
    return content;
  }
}
