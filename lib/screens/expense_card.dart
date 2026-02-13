import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ExpenseCard extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ExpenseCard({
    Key? key,
    required this.expense,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    return {
          'Food': Icons.restaurant_rounded,
          'Transport': Icons.directions_car_rounded,
          'Shopping': Icons.shopping_bag_rounded,
          'Entertainment': Icons.movie_rounded,
          'Bills': Icons.receipt_long_rounded,
          'Other': Icons.more_horiz_rounded,
        }[category] ??
        Icons.category_rounded;
  }

  Color _getCategoryColor(String category) {
    return {
          'Food': const Color(0xFFEF6C57),
          'Transport': const Color(0xFF4C7BF4),
          'Shopping': const Color(0xFFF1A24A),
          'Entertainment': const Color(0xFF7A6FF0),
          'Bills': const Color(0xFF2BB3A6),
          'Other': const Color(0xFF7B8794),
        }[category] ??
        Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getCategoryIcon(widget.expense.category);
    final color = _getCategoryColor(widget.expense.category);

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onEdit,
              borderRadius: BorderRadius.circular(20),
              splashColor: color.withOpacity(0.1),
              highlightColor: color.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'expense_${widget.expense.id}',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.expense.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.expense.category,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(widget.expense.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${widget.expense.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: widget.onEdit,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: widget.onDelete,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.delete_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
