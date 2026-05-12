import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_radius.dart';

enum ButtonVariant { primary, secondary, ghost, danger, outlined }

class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double? height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.height,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.96).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bg {
    switch (widget.variant) {
      case ButtonVariant.primary:   return AppColors.accent;
      case ButtonVariant.secondary: return AppColors.surfaceElevated;
      case ButtonVariant.ghost:     return Colors.transparent;
      case ButtonVariant.danger:    return AppColors.dangerSoft;
      case ButtonVariant.outlined:  return Colors.transparent;
    }
  }

  Color get _fg {
    switch (widget.variant) {
      case ButtonVariant.primary:   return AppColors.bgPrimary;
      case ButtonVariant.secondary: return AppColors.textPrimary;
      case ButtonVariant.ghost:     return AppColors.accent;
      case ButtonVariant.danger:    return AppColors.danger;
      case ButtonVariant.outlined:  return AppColors.accent;
    }
  }

  Border? get _border {
    if (widget.variant == ButtonVariant.outlined) {
      return Border.all(color: AppColors.border);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (!widget.isLoading) widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: widget.fullWidth ? double.infinity : null,
          height: widget.height ?? 50,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: AppRadius.buttonRadius,
            border: _border,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_fg),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: _fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTextStyles.button.copyWith(color: _fg),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
