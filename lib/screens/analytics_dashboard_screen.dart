import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreServices();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.accent,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Analytics',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Categories'),
                    Tab(text: 'Trends'),
                  ],
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: StreamBuilder<List<Expense>>(
                      stream: service.getAllExpenses(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const _AnalyticsShimmer();
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Unable to load analytics: ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.danger),
                              ),
                            ),
                          );
                        }

                        final expenses = snapshot.data ?? [];
                        return TabBarView(
                          children: [
                            _OverviewTab(expenses: expenses),
                            _CategoriesTab(expenses: expenses),
                            _TrendsTab(expenses: expenses),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final List<Expense> expenses;

  const _OverviewTab({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = _filterByMonth(expenses, now.year, now.month);
    final previousMonthDate = DateTime(now.year, now.month - 1, 1);
    final lastMonth = _filterByMonth(
      expenses,
      previousMonthDate.year,
      previousMonthDate.month,
    );

    final totalThisMonth = thisMonth.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final totalLastMonth = lastMonth.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final avgDaily = totalThisMonth / max(1, now.day);

    final highestDay = _highestExpenseDay(thisMonth);

    double? changePercent;
    if (totalLastMonth > 0) {
      changePercent =
          ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MetricCard(
          title: 'Total This Month',
          value: 'Rs ${totalThisMonth.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet_rounded,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Average Daily Spending',
          value: 'Rs ${avgDaily.toStringAsFixed(2)}',
          icon: Icons.calendar_view_day,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Highest Expense Day',
          value: highestDay == null
              ? 'No data'
              : '${DateFormat('dd MMM').format(highestDay.$1)} - Rs ${highestDay.$2.toStringAsFixed(2)}',
          icon: Icons.trending_up,
        ),
        const SizedBox(height: 12),
        _MetricCard(
          title: 'Vs Last Month',
          value: changePercent == null
              ? 'No previous data'
              : '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
          icon: changePercent != null && changePercent < 0
              ? Icons.south_east
              : Icons.north_east,
          valueColor: changePercent == null
              ? AppColors.textPrimary
              : (changePercent <= 0 ? AppColors.success : AppColors.danger),
        ),
      ],
    );
  }

  List<Expense> _filterByMonth(List<Expense> source, int year, int month) {
    return source
        .where((e) => e.date.year == year && e.date.month == month)
        .toList(growable: false);
  }

  (DateTime, double)? _highestExpenseDay(List<Expense> source) {
    if (source.isEmpty) return null;

    final dailyTotals = <DateTime, double>{};
    for (final expense in source) {
      final dateKey = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
    }

    final maxEntry = dailyTotals.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );

    return (maxEntry.key, maxEntry.value);
  }
}

class _CategoriesTab extends StatelessWidget {
  final List<Expense> expenses;

  const _CategoriesTab({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList(growable: false);

    final total = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final categoryTotals = <String, double>{};
    for (final expense in monthExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return const Center(child: Text('No category data for this month'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 280,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 60,
              sectionsSpace: 2,
              sections: List.generate(sortedEntries.length, (index) {
                final entry = sortedEntries[index];
                final percent = total == 0 ? 0 : (entry.value / total) * 100;
                return PieChartSectionData(
                  value: entry.value,
                  title: '${percent.toStringAsFixed(0)}%',
                  radius: 80,
                  color: _categoryColor(entry.key, index),
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...sortedEntries.map((entry) {
          final percent = total == 0 ? 0 : (entry.value / total) * 100;
          final idx = sortedEntries.indexOf(entry);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _categoryColor(entry.key, idx),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text('Rs ${entry.value.toStringAsFixed(2)}'),
                const SizedBox(width: 8),
                Text('${percent.toStringAsFixed(1)}%'),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _categoryColor(String category, int index) {
    final preset = {
      'Food': const Color(0xFFEF6C57),
      'Transport': const Color(0xFF4C7BF4),
      'Shopping': const Color(0xFFF1A24A),
      'Entertainment': const Color(0xFF7A6FF0),
      'Bills': const Color(0xFF2BB3A6),
      'Other': const Color(0xFF7B8794),
    };

    return preset[category] ??
        Colors.primaries[index % Colors.primaries.length];
  }
}

class _TrendsTab extends StatelessWidget {
  final List<Expense> expenses;

  const _TrendsTab({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final monthPoints = List.generate(6, (index) {
      final monthDate = DateTime(now.year, now.month - (5 - index), 1);
      final monthTotal = expenses
          .where(
            (e) =>
                e.date.year == monthDate.year &&
                e.date.month == monthDate.month,
          )
          .fold<double>(0, (sum, e) => sum + e.amount);
      return (monthDate, monthTotal);
    });

    final thisMonthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .toList(growable: false);

    final weeklyTotals = List<double>.filled(5, 0);
    for (final expense in thisMonthExpenses) {
      final week = ((expense.date.day - 1) ~/ 7).clamp(0, 4);
      weeklyTotals[week] += expense.amount;
    }

    final maxMonthly = monthPoints.map((p) => p.$2).fold<double>(0, max);
    final maxWeekly = weeklyTotals.fold<double>(0, max);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Last 6 Months Spending',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxMonthly == 0 ? 100 : maxMonthly * 1.2,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= monthPoints.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MMM').format(monthPoints[idx].$1),
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    monthPoints.length,
                    (index) => FlSpot(index.toDouble(), monthPoints[index].$2),
                  ),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Weekly Spending (Current Month)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: maxWeekly == 0 ? 100 : maxWeekly * 1.3,
              gridData: const FlGridData(show: true),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(
                5,
                (index) => BarChartGroupData(
                  x: index + 1,
                  barRods: [
                    BarChartRodData(
                      toY: weeklyTotals[index],
                      color: AppColors.accent,
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) => Text('W${value.toInt()}'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsShimmer extends StatelessWidget {
  const _AnalyticsShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: index == 0 ? 180 : 90,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
