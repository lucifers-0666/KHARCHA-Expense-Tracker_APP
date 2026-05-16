import '../models/expense.dart';
import '../models/smart_insight.dart';

enum BurnRateStatus { safe, warning, danger }

class BurnRateResult {
  final double usedPercent;
  final double projectedMonthEnd;
  final double projectedOverrun;
  final int dayOfMonth;
  final int daysInMonth;
  final BurnRateStatus status;

  const BurnRateResult({
    required this.usedPercent,
    required this.projectedMonthEnd,
    required this.projectedOverrun,
    required this.dayOfMonth,
    required this.daysInMonth,
    required this.status,
  });

  double get remainingPercent => (1.0 - usedPercent).clamp(0.0, 1.0);
  bool get isOnTrack => status == BurnRateStatus.safe;
}

class BurnRateService {
  /// Returns null if there's no budget or no spending yet.
  BurnRateResult? calculate({
    required List<Expense> expenses,
    required double monthlyBudget,
    required DateTime now,
  }) {
    if (monthlyBudget <= 0) return null;

    final totalSpent = expenses.fold<double>(0, (s, e) => s + e.amount);
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    if (dayOfMonth == 0) return null;

    final dailyRate = totalSpent / dayOfMonth;
    final projected = dailyRate * daysInMonth;
    final usedPercent = (totalSpent / monthlyBudget).clamp(0.0, 1.5);
    final overrun = (projected - monthlyBudget).clamp(0.0, double.infinity);

    BurnRateStatus status;
    if (usedPercent < 0.6) {
      status = BurnRateStatus.safe;
    } else if (usedPercent < 0.85) {
      status = BurnRateStatus.warning;
    } else {
      status = BurnRateStatus.danger;
    }

    return BurnRateResult(
      usedPercent: usedPercent,
      projectedMonthEnd: projected,
      projectedOverrun: overrun,
      dayOfMonth: dayOfMonth,
      daysInMonth: daysInMonth,
      status: status,
    );
  }

  SmartInsight? getInsight({
    required List<Expense> expenses,
    required DateTime now,
  }) {
    final totalSpent = expenses.fold<double>(0, (s, e) => s + e.amount);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    if (dayOfMonth == 0 || totalSpent == 0) return null;

    final dailyRate = totalSpent / dayOfMonth;
    final projected = dailyRate * daysInMonth;
    final percentDay = dayOfMonth / daysInMonth;
    final percentSpent = totalSpent / (projected > 0 ? projected : 1);

    // Only warn if spending pace is 15%+ ahead of time
    if (percentSpent > percentDay + 0.15) {
      final pctUsed = (dayOfMonth / daysInMonth * 100).toStringAsFixed(0);
      final projLabel = '₹${projected.toStringAsFixed(0)}';
      return SmartInsight(
        id: 'burn_rate',
        title: 'Spending ahead of pace',
        message:
            'Used $pctUsed% of month. At this rate you\'ll spend $projLabel by month-end.',
        type: InsightType.burnRate,
        severity: InsightSeverity.warning,
        generatedAt: DateTime.now(),
      );
    }
    return null;
  }
}
