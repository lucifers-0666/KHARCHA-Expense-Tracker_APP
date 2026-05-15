import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─── Gradient Background ───────────────────────────────────────────────
class KharchaBackground extends StatelessWidget {
  final Widget child;
  const KharchaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1A1F), AppColors.bg],
          stops: [0.0, 0.5],
        ),
      ),
      child: child,
    );
  }
}

// ─── KPI Card ──────────────────────────────────────────────────────────
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: amountColor, size: 18),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction Tile ──────────────────────────────────────────────────
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
    final catColor = AppColors.categoryColors[category] ?? AppColors.textMuted;
    final catIcon = AppColors.categoryIcons[category] ?? Icons.category_rounded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(catIcon, color: catColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: catColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: const TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                    ],
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
                    color: isExpense ? AppColors.expense : AppColors.income,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onDelete != null)
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.textFaint),
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

// ─── Section Header ────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onButton,
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Budget Progress Bar ───────────────────────────────────────────────
class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double total;

  const BudgetProgressBar({super.key, required this.spent, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final color = pct > 0.9
        ? AppColors.expense
        : pct > 0.7
            ? AppColors.warning
            : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '₹${spent.toStringAsFixed(0)} / ₹${total.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            const Spacer(),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
