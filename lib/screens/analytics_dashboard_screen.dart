import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/income.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _service = FirestoreServices();
  DateTime _month = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  int _touchedIndex = -1;

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

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

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    final now  = DateTime.now();
    if (next.year < now.year ||
        (next.year == now.year && next.month <= now.month)) {
      setState(() => _month = next);
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(month: _month, monthNames: _monthNames),
            _MonthSelector(
              month: _month,
              monthNames: _monthNames,
              onPrev: _prevMonth,
              onNext: _isCurrentMonth ? null : _nextMonth,
              isDark: isDark,
            ),
            _TabBar(controller: _tabCtrl, isDark: isDark),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _ExpensesTab(
                    service: _service,
                    month: _month,
                    touchedIndex: _touchedIndex,
                    onTouch: (i) => setState(() => _touchedIndex = i),
                    isDark: isDark,
                  ),
                  _TrendsTab(
                    service: _service,
                    month: _month,
                    isDark: isDark,
                  ),
                  _SixMonthTab(
                    service: _service,
                    currentMonth: _month,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final DateTime month;
  final List<String> monthNames;
  const _Header({required this.month, required this.monthNames});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              color: AppColors.textPrimaryFor(isDark),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${monthNames[month.month - 1]} ${month.year}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

// ─── Month Selector ───────────────────────────────────────────────────────────
class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final List<String> monthNames;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final bool isDark;
  const _MonthSelector({
    required this.month,
    required this.monthNames,
    required this.onPrev,
    required this.onNext,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface     = AppColors.surfaceFor(isDark);
    final border      = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _btn(Icons.chevron_left_rounded, onPrev, surface, border, textMuted),
          const SizedBox(width: 12),
          Text(
            '${monthNames[month.month - 1]} ${month.year}',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          _btn(
            Icons.chevron_right_rounded,
            onNext,
            surface,
            border,
            onNext != null ? textMuted : AppColors.textFaintFor(isDark),
          ),
        ],
      ),
    );
  }

  Widget _btn(
      IconData icon, VoidCallback? onTap, Color bg, Color border, Color ic) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: ic, size: 18),
      ),
    );
  }
}

// ─── TabBar ──────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  final TabController controller;
  final bool isDark;
  const _TabBar({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderFor(isDark)),
        ),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMutedFor(isDark),
          labelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Overview'),
            Tab(text: '6 Months'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 — Expenses (Donut + Category Breakdown)
// ─────────────────────────────────────────────────────────────────────────────
class _ExpensesTab extends StatelessWidget {
  final FirestoreServices service;
  final DateTime month;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  final bool isDark;
  const _ExpensesTab({
    required this.service,
    required this.month,
    required this.touchedIndex,
    required this.onTouch,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    return StreamBuilder<Map<String, double>>(
      stream: service.getCategoryTotalsByMonth(month),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
          );
        }
        final data = snap.data ?? {};
        if (data.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No expenses this month',
            subtitle: 'Add some expenses to see category breakdown',
          );
        }
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = entries.fold(0.0, (s, e) => s + e.value);
        final surface     = AppColors.surfaceFor(isDark);
        final border      = AppColors.borderFor(isDark);
        final textPrimary = AppColors.textPrimaryFor(isDark);
        final textMuted   = AppColors.textMutedFor(isDark);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Donut chart card ──────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 62,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, resp) {
                                  if (event is FlTapUpEvent) {
                                    onTouch(
                                      resp?.touchedSection
                                              ?.touchedSectionIndex ??
                                          -1,
                                    );
                                  }
                                },
                              ),
                              sections:
                                  entries.asMap().entries.map((e) {
                                final isTouched = e.key == touchedIndex;
                                final color =
                                    AppColors.categoryColor(e.value.key);
                                return PieChartSectionData(
                                  value: e.value.value,
                                  color: color,
                                  radius: isTouched ? 58 : 46,
                                  showTitle: false,
                                );
                              }).toList(),
                            ),
                          ),
                          // centre label
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Total',
                                style: TextStyle(
                                    color: textMuted, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '\u20b9${fmt.format(total.toInt())}',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (touchedIndex >= 0 &&
                                  touchedIndex < entries.length) ...[
                                const SizedBox(height: 4),
                                Text(
                                  entries[touchedIndex].key,
                                  style: TextStyle(
                                      color: AppColors.categoryColor(
                                          entries[touchedIndex].key),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Legend row
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: entries.take(6).map((e) {
                        final color = AppColors.categoryColor(e.key);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              e.key,
                              style: TextStyle(
                                  color: textMuted, fontSize: 11),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Top spending insight ──────────────────────────────────
              if (entries.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.categoryColor(entries.first.key)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.categoryColor(entries.first.key)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppColors.categoryIcon(entries.first.key),
                        color: AppColors.categoryColor(entries.first.key),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Top spend: ${entries.first.key} '
                          '(${((entries.first.value / total) * 100).toStringAsFixed(0)}% of total)',
                          style: TextStyle(
                            color: AppColors.categoryColor(
                                entries.first.key),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // ── Category breakdown list ───────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: entries.asMap().entries.map((entry) {
                    final cat   = entry.value.key;
                    final amt   = entry.value.value;
                    final pct   = total > 0 ? amt / total : 0.0;
                    final color = AppColors.categoryColor(cat);
                    final icon  = AppColors.categoryIcon(cat);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:
                                    Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          cat,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '\u20b9${fmt.format(amt.toInt())}',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: border,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                color),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (entry.key < entries.length - 1)
                          Divider(
                              height: 1, indent: 64, color: border),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2 — Overview (Income vs Expense + Savings)
// ─────────────────────────────────────────────────────────────────────────────
class _TrendsTab extends StatelessWidget {
  final FirestoreServices service;
  final DateTime month;
  final bool isDark;
  const _TrendsTab({
    required this.service,
    required this.month,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fmt         = NumberFormat('#,##,###', 'en_IN');
    final surface     = AppColors.surfaceFor(isDark);
    final border      = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted   = AppColors.textMutedFor(isDark);

    return StreamBuilder<double>(
      stream: service.getTotalExpensesByMonth(month),
      builder: (ctx, expSnap) {
        return StreamBuilder<double>(
          stream: service.getTotalIncomeByMonth(month),
          builder: (ctx2, incSnap) {
            final exp      = expSnap.data ?? 0.0;
            final inc      = incSnap.data ?? 0.0;
            final savings  = inc - exp;
            final savingsPct = inc > 0
                ? ((savings / inc) * 100).clamp(0.0, 100.0)
                : 0.0;
            final Color savingsColor = savingsPct >= 20
                ? AppColors.income
                : savingsPct >= 10
                    ? AppColors.warning
                    : AppColors.expense;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                children: [
                  // ── KPI Cards ─────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Income',
                          value: '\u20b9${fmt.format(inc.toInt())}',
                          valueColor: AppColors.income,
                          icon: Icons.arrow_downward_rounded,
                          iconBg: AppColors.income.withValues(alpha: 0.1),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'Expenses',
                          value: '\u20b9${fmt.format(exp.toInt())}',
                          valueColor: AppColors.expense,
                          icon: Icons.arrow_upward_rounded,
                          iconBg: AppColors.expense.withValues(alpha: 0.1),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Savings rate + bar chart ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Savings Rate',
                              style: TextStyle(
                                  color: textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            Text(
                              '${savingsPct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: savingsColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BudgetProgressBar(
                          label: 'Month Overview',
                          spent: exp,
                          limit: inc > 0 ? inc : exp,
                        ),
                        const SizedBox(height: 20),

                        // Bar chart
                        SizedBox(
                          height: 170,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: ([inc, exp, savings.abs()]
                                          .reduce(
                                              (a, b) => a > b ? a : b)) *
                                      1.25 +
                                  1,
                              barTouchData:
                                  BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      const labels = [
                                        'Income',
                                        'Expense',
                                        'Savings',
                                      ];
                                      if (v.toInt() < 0 ||
                                          v.toInt() >= labels.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Text(
                                          labels[v.toInt()],
                                          style: TextStyle(
                                            color: textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                _barGroup(0, inc, AppColors.income),
                                _barGroup(1, exp, AppColors.expense),
                                _barGroup(
                                  2,
                                  savings.abs(),
                                  savings >= 0
                                      ? AppColors.primary
                                      : AppColors.warning,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Summary strip ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Row(
                      children: [
                        _SummaryItem(
                          label: 'Net Balance',
                          value:
                              '${savings >= 0 ? '+' : '-'}\u20b9${fmt.format(savings.abs().toInt())}',
                          color: savings >= 0
                              ? AppColors.income
                              : AppColors.expense,
                          isDark: isDark,
                        ),
                        Container(
                            width: 1, height: 36, color: border),
                        _SummaryItem(
                          label: 'Saved',
                          value:
                              '${savingsPct.toStringAsFixed(0)}%',
                          color: savingsColor,
                          isDark: isDark,
                        ),
                        Container(
                            width: 1, height: 36, color: border),
                        _SummaryItem(
                          label: 'Health',
                          value: savingsPct >= 20
                              ? 'Great 🟢'
                              : savingsPct >= 10
                                  ? 'Good 🟡'
                                  : 'Watch 🔴',
                          color: savingsColor,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Income breakdown by source ────────────────────────
                  StreamBuilder<List<Income>>(
                    stream: service.getIncomeByMonth(month),
                    builder: (ctx3, incList) {
                      final incomes = incList.data ?? [];
                      if (incomes.isEmpty) return const SizedBox.shrink();

                      final sourceMap = <String, double>{};
                      for (final i in incomes) {
                        sourceMap[i.source] =
                            (sourceMap[i.source] ?? 0) + i.amount;
                      }
                      final srcEntries = sourceMap.entries.toList()
                        ..sort((a, b) => b.value.compareTo(a.value));

                      return Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 12),
                              child: Text(
                                'Income Sources',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ...srcEntries.asMap().entries.map((e) {
                              final src = e.value.key;
                              final amt = e.value.value;
                              final pct = inc > 0 ? amt / inc : 0.0;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: AppColors.income
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.attach_money_rounded,
                                            color: AppColors.income,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    src,
                                                    style: TextStyle(
                                                      color: textPrimary,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    '\u20b9${fmt.format(amt.toInt())}',
                                                    style: const TextStyle(
                                                      color: AppColors.income,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 5),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child:
                                                    LinearProgressIndicator(
                                                  value: pct,
                                                  backgroundColor: border,
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(
                                                    AppColors.income,
                                                  ),
                                                  minHeight: 4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (e.key < srcEntries.length - 1)
                                    Divider(
                                        height: 1,
                                        indent: 60,
                                        color: border),
                                ],
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  BarChartGroupData _barGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 38,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: (y * 1.25) + 1,
            color: AppColors.primary.withValues(alpha: 0.06),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3 — 6-Month Line Chart Trend
// ─────────────────────────────────────────────────────────────────────────────
class _SixMonthTab extends StatefulWidget {
  final FirestoreServices service;
  final DateTime currentMonth;
  final bool isDark;
  const _SixMonthTab({
    required this.service,
    required this.currentMonth,
    required this.isDark,
  });

  @override
  State<_SixMonthTab> createState() => _SixMonthTabState();
}

class _SixMonthTabState extends State<_SixMonthTab> {
  late final Future<List<_MonthData>> _future;
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _future = _loadSixMonths();
  }

  Future<List<_MonthData>> _loadSixMonths() async {
    final result = <_MonthData>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(
          widget.currentMonth.year, widget.currentMonth.month - i);
      final exp =
          await widget.service.getTotalExpensesByMonth(m).first;
      final inc =
          await widget.service.getTotalIncomeByMonth(m).first;
      result.add(_MonthData(month: m, expense: exp, income: inc));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final surface     = AppColors.surfaceFor(widget.isDark);
    final border      = AppColors.borderFor(widget.isDark);
    final textPrimary = AppColors.textPrimaryFor(widget.isDark);
    final textMuted   = AppColors.textMutedFor(widget.isDark);

    return FutureBuilder<List<_MonthData>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary));
        }
        final months = snap.data ?? [];
        final allValues = months
            .expand((m) => [m.expense, m.income])
            .toList();
        final maxY = allValues.isEmpty
            ? 1000.0
            : allValues.reduce((a, b) => a > b ? a : b) * 1.25 + 1;

        final expSpots = months
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.expense))
            .toList();
        final incSpots = months
            .asMap()
            .entries
            .map((e) => FlSpot(e.key.toDouble(), e.value.income))
            .toList();

        final labels = months
            .map((m) => [
                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                ][m.month.month - 1])
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Line chart ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 8, 16),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 16),
                      child: Row(
                        children: [
                          Text(
                            '6-Month Trend',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          _LegendDot(
                              color: AppColors.income,
                              label: 'Income',
                              isDark: widget.isDark),
                          const SizedBox(width: 12),
                          _LegendDot(
                              color: AppColors.expense,
                              label: 'Expense',
                              isDark: widget.isDark),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxY,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (spot) =>
                                  AppColors.surfaceOffsetFor(widget.isDark),
                              getTooltipItems: (spots) => spots
                                  .map(
                                    (s) => LineTooltipItem(
                                      '\u20b9${_fmt.format(s.y.toInt())}',
                                      TextStyle(
                                        color: s.bar.color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: border,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= labels.length) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(top: 6),
                                    child: Text(
                                      labels[idx],
                                      style: TextStyle(
                                        color: textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            _line(incSpots, AppColors.income),
                            _line(expSpots, AppColors.expense),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Monthly table ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text('Month',
                                  style: TextStyle(
                                      color: textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600))),
                          Text('Income',
                              style: TextStyle(
                                  color: AppColors.income,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 20),
                          Text('Expense',
                              style: TextStyle(
                                  color: AppColors.expense,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 50,
                            child: Text('Net',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    color: textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: border),
                    ...months.reversed.toList().asMap().entries.map((e) {
                      final md  = e.value;
                      final net = md.income - md.expense;
                      final monthLabel = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
                      ][md.month.month - 1];
                      return Column(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$monthLabel ${md.month.year}',
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\u20b9${_fmt.format(md.income.toInt())}',
                                  style: const TextStyle(
                                    color: AppColors.income,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Text(
                                  '\u20b9${_fmt.format(md.expense.toInt())}',
                                  style: const TextStyle(
                                    color: AppColors.expense,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    '${net >= 0 ? '+' : ''}\u20b9${_fmt.format(net.abs().toInt())}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: net >= 0
                                          ? AppColors.income
                                          : AppColors.expense,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (e.key < months.length - 1)
                            Divider(height: 1, indent: 16, color: border),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3.5,
          color: color,
          strokeWidth: 2,
          strokeColor: AppColors.bgFor(widget.isDark),
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper data class
// ─────────────────────────────────────────────────────────────────────────────
class _MonthData {
  final DateTime month;
  final double expense;
  final double income;
  const _MonthData(
      {required this.month, required this.expense, required this.income});
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconBg;
  final bool isDark;
  const _KpiCard({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderFor(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration:
                BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: valueColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: AppColors.textMutedFor(isDark),
                      fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: AppColors.textMutedFor(isDark), fontSize: 10)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  const _LegendDot(
      {required this.color, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: AppColors.textMutedFor(isDark), fontSize: 11)),
      ],
    );
  }
}
