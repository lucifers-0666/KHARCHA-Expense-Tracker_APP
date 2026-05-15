import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
  DateTime _month = DateTime.now();
  int _touchedIndex = -1;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
    if (!next.isAfter(DateTime.now())) setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildMonthSelector(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _ExpensesTab(service: _service, month: _month,
                      touchedIndex: _touchedIndex,
                      onTouch: (i) => setState(() => _touchedIndex = i)),
                  _TrendsTab(service: _service, month: _month),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'Analytics',
            style: TextStyle(
              color: AppColors.textPrimary,
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
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_months[_month.month - 1]} ${_month.year}',
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

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          _monthBtn(Icons.chevron_left_rounded, _prevMonth),
          const SizedBox(width: 12),
          Text(
            '${_months[_month.month - 1]} ${_month.year}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          _monthBtn(Icons.chevron_right_rounded, _nextMonth),
        ],
      ),
    );
  }

  Widget _monthBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 18),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          controller: _tabCtrl,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorPadding: const EdgeInsets.all(3),
          dividerColor: Colors.transparent,
          labelColor: Colors.black,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Trends'),
          ],
        ),
      ),
    );
  }
}

// ── Expenses Tab ─────────────────────────────────────────────────────
class _ExpensesTab extends StatelessWidget {
  final FirestoreServices service;
  final DateTime month;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _ExpensesTab({
    required this.service,
    required this.month,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: service.getCategoryTotalsByMonth(month),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary));
        }
        final data = snap.data ?? {};
        if (data.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No data this month',
            subtitle: 'Add some expenses to see category breakdown',
          );
        }
        final entries = data.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final total = entries.fold(0.0, (s, e) => s + e.value);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Donut Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
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
                              centerSpaceRadius: 60,
                              pieTouchData: PieTouchData(
                                touchCallback: (event, resp) {
                                  if (event is FlTapUpEvent) {
                                    onTouch(resp?.touchedSection
                                            ?.touchedSectionIndex ??
                                        -1);
                                  }
                                },
                              ),
                              sections: entries.asMap().entries.map((e) {
                                final isTouched = e.key == touchedIndex;
                                final color =
                                    AppColors.categoryColors[e.value.key] ??
                                        AppColors.primary;
                                return PieChartSectionData(
                                  value: e.value.value,
                                  color: color,
                                  radius: isTouched ? 55 : 45,
                                  showTitle: false,
                                );
                              }).toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                '\u20b9${total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: entries.asMap().entries.map((entry) {
                    final cat = entry.value.key;
                    final amt = entry.value.value;
                    final pct = total > 0 ? amt / total : 0.0;
                    final color =
                        AppColors.categoryColors[cat] ?? AppColors.primary;
                    final icon =
                        AppColors.categoryIcons[cat] ?? Icons.category_rounded;
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
                                child: Icon(icon, color: color, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(cat,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            )),
                                        const Spacer(),
                                        Text(
                                          '\u20b9${amt.toStringAsFixed(0)}',
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
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: AppColors.border,
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
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (entry.key < entries.length - 1)
                          const Divider(
                              height: 1, indent: 64, color: AppColors.border),
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

// ── Trends Tab ───────────────────────────────────────────────────────
class _TrendsTab extends StatelessWidget {
  final FirestoreServices service;
  final DateTime month;

  const _TrendsTab({required this.service, required this.month});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: service.getTotalExpensesByMonth(month),
      builder: (ctx, expSnap) {
        return StreamBuilder<double>(
          stream: service.getTotalIncomeByMonth(month),
          builder: (ctx2, incSnap) {
            final exp = expSnap.data ?? 0;
            final inc = incSnap.data ?? 0;
            final savings = inc - exp;
            final savingsPct =
                inc > 0 ? ((savings / inc) * 100).clamp(0.0, 100.0) : 0.0;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // KPI Cards
                  Row(
                    children: [
                      Expanded(
                        child: KpiCard(
                          title: 'Income',
                          amount: '\u20b9${inc.toStringAsFixed(0)}',
                          amountColor: AppColors.income,
                          icon: Icons.arrow_downward_rounded,
                          iconBg: AppColors.income.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KpiCard(
                          title: 'Expenses',
                          amount: '\u20b9${exp.toStringAsFixed(0)}',
                          amountColor: AppColors.expense,
                          icon: Icons.arrow_upward_rounded,
                          iconBg: AppColors.expense.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Savings rate card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Savings Rate',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                )),
                            const Spacer(),
                            Text(
                              '${savingsPct.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: savingsPct >= 20
                                    ? AppColors.income
                                    : savingsPct >= 10
                                        ? AppColors.warning
                                        : AppColors.expense,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BudgetProgressBar(
                          spent: exp,
                          total: inc > 0 ? inc : exp,
                        ),
                        const SizedBox(height: 16),
                        // Bar chart — income vs expense
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (inc > exp ? inc : exp) * 1.2,
                              barTouchData:
                                  BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
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
                                        'Savings'
                                      ];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 6),
                                        child: Text(
                                          labels[v.toInt()],
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
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
                                _bar(0, inc, AppColors.income),
                                _bar(1, exp, AppColors.expense),
                                _bar(2, savings.abs(), savings >= 0
                                    ? AppColors.primary
                                    : AppColors.warning),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Summary row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        _summaryItem('Net Balance',
                            '\u20b9${savings.abs().toStringAsFixed(0)}',
                            savings >= 0
                                ? AppColors.income
                                : AppColors.expense),
                        _dividerV(),
                        _summaryItem('Savings',
                            '${savingsPct.toStringAsFixed(0)}%',
                            AppColors.primary),
                        _dividerV(),
                        _summaryItem('Status',
                            savingsPct >= 20
                                ? 'Great'
                                : savingsPct >= 10
                                    ? 'Good'
                                    : 'Watch out',
                            savingsPct >= 20
                                ? AppColors.income
                                : AppColors.warning),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 36,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: y * 1.2,
            color: AppColors.border,
          ),
        ),
      ],
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _dividerV() {
    return Container(
        width: 1, height: 36, color: AppColors.border);
  }
}
