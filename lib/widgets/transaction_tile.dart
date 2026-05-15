import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool isExpense;
  final String? note;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.isExpense = true,
    this.note,
    this.onTap,
    this.onDelete,
  });

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'income':
        return Icons.payments_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = AppColors.categoryColor(category);
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final prefix = isExpense ? '- ' : '+ ';
    final bgColor = catColor.withAlpha(isDark ? 30 : 20);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pageHPad,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_categoryIcon(category), size: 20, color: catColor),
            ),
            const SizedBox(width: AppSpacing.md),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: AppTextStyles.caption.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Amount + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${prefix}₹${amount.toStringAsFixed(0)}',
                  style: AppTextStyles.subtitle.copyWith(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(date),
                  style: AppTextStyles.caption.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
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
