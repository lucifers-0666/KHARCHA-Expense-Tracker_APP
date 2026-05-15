import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── KPI Card ──────────────────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor   = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 1),
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: amountColor, size: 16),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Tile ─────────────────────────────────────────────────────────
class TransactionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor    = AppColors.categoryColors[category] ?? AppColors.textMuted;
    final catIcon     = AppColors.categoryIcons[category] ?? Icons.category_rounded;
    final cardColor   = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    final textFaint   = AppColors.textFaintFor(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: borderColor),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
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
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$category · $date',
                    style: TextStyle(color: textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isExpense ? '-' : '+'}₹$amount',
                  style: TextStyle(
                    color: isExpense ? AppColors.danger : AppColors.success,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryFor(isDark);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
/// Usage:
/// EmptyStateWidget(
///   icon: Icons.receipt_long_rounded,
///   title: 'No transactions yet',
///   subtitle: 'Add your first expense to get started',
///   buttonLabel: 'Add Expense',   // optional
///   onButton: () {},              // optional
/// )
class EmptyStateWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);
    final textFaint   = AppColors.textFaintFor(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceOffsetFor(isDark),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: textFaint),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: textMuted,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          if (buttonLabel != null && onButton != null) ...
            [
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onButton,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12,
                  ),
                ),
                child: Text(
                  buttonLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
        ],
      ),
    );
  }
}

// ─── Budget Progress Bar ───────────────────────────────────────────────────────
/// Used in analytics_dashboard_screen.dart and budget_setup_screen.dart
/// BudgetProgressBar(label: 'Food', spent: 3500, limit: 5000)
class BudgetProgressBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final pct     = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
    final barColor = color ?? (pct >= 0.9 ? AppColors.danger : pct >= 0.7 ? AppColors.warning : AppColors.primary);
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
                label,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
