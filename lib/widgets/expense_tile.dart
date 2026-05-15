import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';

/// Alias so screens that import ExpenseCard still work
typedef ExpenseCard = ExpenseTile;

class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColor(expense.category);
    final icon = AppColors.categoryIcon(expense.category);
    final fmt = NumberFormat('#,##,###.##');
    // description is nullable — guard before using
    final desc = expense.description;

    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        HapticFeedback.mediumImpact();
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                title: const Text('Delete Expense'),
                content: Text(
                  'Delete "${expense.title}"? This cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: AppRadius.tileRadius,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
              size: 26,
            ),
            const SizedBox(height: 4),
            const Text(
              'Delete',
              style: TextStyle(
                color: AppColors.danger,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.tileRadius,
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onEdit,
            borderRadius: AppRadius.tileRadius,
            splashColor: color.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  // Category icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // Title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                expense.category,
                                style: AppTextStyles.caption.copyWith(
                                  color: color,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(expense.date),
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        // Show description only if non-null and non-empty
                        if (desc != null && desc.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            desc,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '-₹${fmt.format(expense.amount)}',
                        style: AppTextStyles.amountSmall.copyWith(
                          color: AppColors.danger,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textDisabled,
                      ),
                    ],
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
