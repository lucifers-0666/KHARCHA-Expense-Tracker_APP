import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── KPI Card ──────────────────────────────────────────────────────────────────
class KpiCard extends StatefulWidget {
  final String title;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconBg;
  final Widget? trailing;

  const KpiCard({
    super.key,
    required this.title,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconBg,
    this.trailing,
  });

  @override
  State<KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<KpiCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(widget.icon, color: widget.amountColor, size: 16),
                  ),
                  const Spacer(),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.title,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.amount,
                style: TextStyle(
                  color: widget.amountColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class TransactionTile extends StatefulWidget {
  final String title;
  final String category;
  final String amount;
  final bool isExpense;
  final String date;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
    required this.date,
    this.onTap,
    this.onDelete,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.975)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final catColor    = AppColors.categoryColors[widget.category] ?? AppColors.textMuted;
    final catIcon     = AppColors.categoryIcons[widget.category] ?? Icons.category_rounded;
    final cardColor   = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    final textFaint   = AppColors.textFaintFor(isDark);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _ctrl.forward();
      },
      onTapUp: (_) async {
        await _ctrl.reverse();
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () {
        _ctrl.reverse();
        setState(() => _pressed = false);
      },
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _pressed
                ? (isDark ? AppColors.surface2Dark : AppColors.surfaceOffset)
                : cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(catIcon, color: catColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.category} · ${widget.date}',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${widget.isExpense ? '-' : '+'}₹${widget.amount}',
                    style: TextStyle(
                      color: widget.isExpense ? AppColors.danger : AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (widget.onDelete != null)
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 15,
                          color: textFaint,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryFor(isDark);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class EmptyStateWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButton,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade      = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide     = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _iconScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    final textFaint   = AppColors.textFaintFor(isDark);
    final offsetBg    = AppColors.surfaceOffsetFor(isDark);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon container
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: offsetBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Icon(widget.icon, size: 28, color: textFaint),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 5),
              Text(
                widget.subtitle,
                style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              if (widget.buttonLabel != null && widget.onButton != null) ...[
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: widget.onButton,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 11,
                    ),
                  ),
                  child: Text(
                    widget.buttonLabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Budget Progress Bar ───────────────────────────────────────────────────────
class BudgetProgressBar extends StatefulWidget {
  final String label;
  final double spent;
  final double limit;
  final Color? color;

  const BudgetProgressBar({
    super.key,
    required this.label,
    required this.spent,
    required this.limit,
    this.color,
  });

  @override
  State<BudgetProgressBar> createState() => _BudgetProgressBarState();
}

class _BudgetProgressBarState extends State<BudgetProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    final pct = widget.limit > 0
        ? (widget.spent / widget.limit).clamp(0.0, 1.0)
        : 0.0;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _progress = Tween<double>(begin: 0, end: pct).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final pct       = widget.limit > 0
        ? (widget.spent / widget.limit).clamp(0.0, 1.0)
        : 0.0;
    final barColor  = widget.color ??
        (pct >= 0.9
            ? AppColors.danger
            : pct >= 0.7
                ? AppColors.warning
                : AppColors.primary);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    final trackColor  = AppColors.borderFor(isDark);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '₹${widget.spent.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: barColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' / ₹${widget.limit.toStringAsFixed(0)}',
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: AnimatedBuilder(
              animation: _progress,
              builder: (_, __) => LinearProgressIndicator(
                value: _progress.value,
                minHeight: 7,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
