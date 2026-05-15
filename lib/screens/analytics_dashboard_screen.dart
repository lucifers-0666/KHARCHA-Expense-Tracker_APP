import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';
import 'package:intl/intl.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FirestoreServices();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Analytics',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(
                      DateFormat('MMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                          color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Categories'),
                  Tab(text: 'Trends'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Expense>>(
                stream: service.getAllExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error loading data',
                            style: TextStyle(color: AppColors.expense)));
                  }
                  final expenses = snapshot.data ?? [];
                  return TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _OverviewTab(expenses: expenses),
                      _CategoriesTab(expenses: expenses),
                      _TrendsTab(expenses: expenses),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Overview Tab ───────────────────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final List<Expense> expenses;
  const _OverviewTab({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = expenses.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    final prevDate = DateTime(now.year, now.month - 1);
    final lastMonth = expenses.where((e) => e.date.year == prevDate.year && e.date.month == prevDate.month).toList();

    final totalThis = thisMonth.fold<double>(0, (s, e) => s + e.amount);
    final totalLast = lastMonth.fold<double>(0, (s, e) => s + e.amount);
    final avgDaily = totalThis / max(1, now.day);
    final change = totalLast > 0 ? ((totalThis - totalLast) / totalLast) * 100 : null;

    DateTime? highDay;
    double highVal = 0;
    final dayMap = <DateTime, double>{};
    for (final e in thisMonth) {
      final key = DateTime(e.date.year, e.date.month, e.date.day);
      dayMap[key] = (dayMap[key] ?? 0) + e.amount;
    }
    for (final entry in dayMap.entries) {
      if (entry.value > highVal) { highVal = entry.value; highDay = entry.key; }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        _metricTile(
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.primary,
          title: 'Total This Month',
          value: '₹${NumberFormat('#,##,###').format(totalThis)}',
          valueColor: AppColors.textPrimary,
        ),
        _metricTile(
          icon: Icons.today_rounded,
          iconColor: AppColors.warning,
          title: 'Avg Daily Spend',
          value: '₹${avgDaily.toStringAsFixed(0)}',
          valueColor: AppColors.warning,
        ),
        _metricTile(
          icon: Icons.local_fire_department_rounded,
          iconColor: AppColors.expense,
          title: 'Highest Day',
          value: highDay != null
              ? '${DateFormat('dd MMM').format(highDay)} · ₹${highVal.toStringAsFixed(0)}'
              : 'No data',
          valueColor: AppColors.expense,
        ),
        _metricTile(
          icon: change != null && change < 0
              ? Icons.trending_down_rounded
              : Icons.trending_up_rounded,
          iconColor: change != null && change < 0 ? AppColors.income : AppColors.expense,
          title: 'vs Last Month',
          value: change != null
              ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%'
              : 'No data',
          valueColor: change == null
              ? AppColors.textMuted
              : (change < 0 ? AppColors.income : AppColors.expense),
        ),
        _metricTile(
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.primaryLight,
          title: 'Total Transactions',
          value: '${thisMonth.length} this month',
          valueColor: AppColors.textPrimary,
        ),
      ],
    );
  }

  Widget _metricTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Categories Tab ──────────────────────────────────────────────────────────
class _CategoriesTab extends StatefulWidget {
  final List<Expense> expenses;
  const _CategoriesTab({required this.expenses});

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthExp = widget.expenses.where(
        (e) => e.date.year == now.year && e.date.month == now.month).toList();
    final total = monthExp.fold<double>(0, (s, e) => s + e.amount);

    final catMap = <String, double>{};
    for (final e in monthExp) {
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
    }
    final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.pie_chart_outline_rounded,
        title: 'No data this month',
        subtitle: 'Add expenses to see category breakdown',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Donut chart
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const SectionHeader(title: 'Spending by Category'),
              const SizedBox(height: 20),
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 70,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, res) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  res == null || res.touchedSection == null) {
                                _touched = -1;
                                return;
                              }
                              _touched = res.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: List.generate(sorted.length, (i) {
                          final isSelected = i == _touched;
                          final color = AppColors.categoryColors[sorted[i].key] ??
                              Colors.primaries[i % Colors.primaries.length];
                          final pct = total > 0 ? (sorted[i].value / total) * 100 : 0;
                          return PieChartSectionData(
                            value: sorted[i].value,
                            color: color,
                            radius: isSelected ? 56 : 48,
                            title: isSelected ? '${pct.toStringAsFixed(0)}%' : '',
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##,###').format(total)}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text('Total',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Category breakdown list
        ...sorted.asMap().entries.map((entry) {
          final i = entry.key;
          final cat = entry.value;
          final pct = total > 0 ? (cat.value / total) * 100 : 0.0;
          final color = AppColors.categoryColors[cat.key] ??
              Colors.primaries[i % Colors.primaries.length];
          final icon = AppColors.categoryIcons[cat.key] ?? Icons.category_rounded;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.key,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${NumberFormat('#,##,###').format(cat.value)}',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text('${pct.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Trends Tab ───────────────────────────────────────────────────────────────
class _TrendsTab extends StatelessWidget {
  final List<Expense> expenses;
  const _TrendsTab({required this.expenses});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i)));
    final monthTotals = months.map((m) {
      return expenses
          .where((e) => e.date.year == m.year && e.date.month == m.month)
          .fold<double>(0, (s, e) => s + e.amount);
    }).toList();

    final weeklyTotals = List<double>.filled(5, 0);
    for (final e in expenses.where((e) => e.date.year == now.year && e.date.month == now.month)) {
      final w = ((e.date.day - 1) ~/ 7).clamp(0, 4);
      weeklyTotals[w] += e.amount;
    }

    final maxMonthly = monthTotals.fold<double>(0, max);
    final maxWeekly = weeklyTotals.fold<double>(0, max);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: [
        // Line chart — 6 months
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Last 6 Months'),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxMonthly == 0 ? 1000 : maxMonthly * 1.25,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, _) => Text(
                            '₹${(v / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 10),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM').format(months[idx]),
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(6, (i) => FlSpot(i.toDouble(), monthTotals[i])),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2.5,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: AppColors.bg,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.primary.withOpacity(0.2),
                              AppColors.primary.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Bar chart — weekly
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Weekly This Month'),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: maxWeekly == 0 ? 1000 : maxWeekly * 1.3,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(5, (i) => BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: weeklyTotals[i],
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppColors.primaryDark, AppColors.primary],
                          ),
                          width: 28,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ],
                    )),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (v, _) => Text(
                            '₹${(v / 1000).toStringAsFixed(0)}k',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 10),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('W${v.toInt() + 1}',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 11)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
