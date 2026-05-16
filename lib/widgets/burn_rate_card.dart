import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/burn_rate_service.dart';
import '../theme/app_theme.dart';

/// Dashboard burn rate predictor widget.
/// Pass current month expenses + monthly budget.
class BurnRateCard extends StatefulWidget {
  final List<Expense> expenses;
  final double monthlyBudget;
  const BurnRateCard({
    super.key,
    required this.expenses,
    required this.monthlyBudget,
  });

  @override
  State<BurnRateCard> createState() => _BurnRateCardState();
}

class _BurnRateCardState extends State<BurnRateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bar;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(BurnRateCard old) {
    super.didUpdateWidget(old);
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final result = BurnRateService().calculate(
      expenses: widget.expenses,
      monthlyBudget: widget.monthlyBudget,
      now: DateTime.now(),
    );

    if (result == null) return const SizedBox.shrink();

    _bar = Tween<double>(begin: 0, end: result.usedPercent.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final statusColor = result.status == BurnRateStatus.safe
        ? AppColors.success
        : result.status == BurnRateStatus.warning
            ? AppColors.warning
            : AppColors.danger;

    final statusLabel = result.status == BurnRateStatus.safe
        ? 'On track'
        : result.status == BurnRateStatus.warning
            ? 'Spending fast'
            : 'Over budget pace';

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final timePercent = now.day / daysInMonth;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [BoxShadow(
          color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 16, color: statusColor),
              const SizedBox(width: 6),
              const Text('Budget Burn Rate',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statusLabel,
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _bar,
            builder: (_, __) {
              return Stack(
                children: [
                  // Time marker track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _bar.value,
                      backgroundColor: AppColors.surfaceOffset,
                      color: statusColor,
                      minHeight: 8,
                    ),
                  ),
                  // Time position marker
                  Positioned(
                    left: (MediaQuery.of(context).size.width - 64) * timePercent - 1,
                    top: 0, bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(result.usedPercent * 100).toStringAsFixed(0)}% used · Day ${result.dayOfMonth}/${result.daysInMonth}',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              if (result.projectedOverrun > 0)
                Text(
                  '+₹${result.projectedOverrun.toStringAsFixed(0)} overrun',
                  style: TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                )
              else
                Text(
                  '₹${result.projectedMonthEnd.toStringAsFixed(0)} projected',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
