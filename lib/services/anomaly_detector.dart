import '../models/expense.dart';
import '../models/smart_insight.dart';

/// Pure local computation — zero external APIs.
/// Compares current month category spend vs trailing 3-month average.
class AnomalyDetector {
  static const double _percentThreshold = 0.30; // 30% increase
  static const double _absoluteThreshold = 500.0; // ₹500 minimum delta

  /// [currentExpenses] — expenses for current month
  /// [historicalExpenses] — expenses for previous 3 months combined
  List<SmartInsight> detect({
    required List<Expense> currentExpenses,
    required List<Expense> historicalExpenses,
    required DateTime currentMonth,
  }) {
    final insights = <SmartInsight>[];

    // Build current month category totals
    final currentTotals = _categoryTotals(currentExpenses);

    // Build 3-month averages (only complete months)
    final avgTotals = _threeMonthAverage(historicalExpenses, currentMonth);

    for (final entry in currentTotals.entries) {
      final cat = entry.key;
      final current = entry.value;
      final avg = avgTotals[cat] ?? 0.0;

      if (avg == 0) continue; // No history to compare

      final delta = current - avg;
      final deltaPercent = avg > 0 ? delta / avg : 0.0;

      if (delta >= _absoluteThreshold && deltaPercent >= _percentThreshold) {
        final severity = deltaPercent >= 0.6
            ? InsightSeverity.danger
            : InsightSeverity.warning;
        final pctLabel = (deltaPercent * 100).toStringAsFixed(0);
        final deltaLabel = '₹${delta.toStringAsFixed(0)}';

        insights.add(SmartInsight(
          id: 'anomaly_$cat',
          title: '$cat spending spike',
          message:
              '$cat is $deltaLabel higher than usual (+$pctLabel% vs 3-month avg).',
          type: InsightType.anomaly,
          severity: severity,
          generatedAt: DateTime.now(),
          category: cat,
          deltaAmount: delta,
          deltaPercent: deltaPercent,
        ));
      }
    }

    // Also check for good savings behaviour
    final totalCurrent = currentTotals.values.fold(0.0, (a, b) => a + b);
    final totalAvg = avgTotals.values.fold(0.0, (a, b) => a + b);
    if (totalAvg > 0 && totalCurrent < totalAvg * 0.85) {
      insights.add(SmartInsight(
        id: 'saving_well',
        title: 'Great spending control!',
        message:
            'You\'re spending 15%+ less than your usual. Keep it up!',
        type: InsightType.achievement,
        severity: InsightSeverity.info,
        generatedAt: DateTime.now(),
      ));
    }

    return insights;
  }

  Map<String, double> _categoryTotals(List<Expense> expenses) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<String, double> _threeMonthAverage(
    List<Expense> historical,
    DateTime currentMonth,
  ) {
    // Group by month
    final byMonth = <String, Map<String, double>>{};
    for (final e in historical) {
      final key = '${e.date.year}-${e.date.month}';
      byMonth.putIfAbsent(key, () => {});
      byMonth[key]![e.category] =
          (byMonth[key]![e.category] ?? 0) + e.amount;
    }

    if (byMonth.isEmpty) return {};

    // Average across months
    final allCategories = <String>{};
    for (final m in byMonth.values) {
      allCategories.addAll(m.keys);
    }

    final avg = <String, double>{};
    final monthCount = byMonth.length;
    for (final cat in allCategories) {
      double sum = 0;
      for (final m in byMonth.values) {
        sum += m[cat] ?? 0;
      }
      avg[cat] = sum / monthCount;
    }
    return avg;
  }
}
