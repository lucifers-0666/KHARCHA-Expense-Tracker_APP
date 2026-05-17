import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cashflow_forecast.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class CashflowForecastScreen extends StatefulWidget {
  const CashflowForecastScreen({super.key});

  @override
  State<CashflowForecastScreen> createState() =>
      _CashflowForecastScreenState();
}

class _CashflowForecastScreenState extends State<CashflowForecastScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cashflow Forecast',
          style:
              AppTextStyles.heading.copyWith(color: textPrimary, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<CashflowForecast>>(
        stream: _service.getCashflowForecasts(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer(isDark);
          }
          final forecasts = snap.data ?? [];
          if (forecasts.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.show_chart_rounded,
              title: 'No forecast data yet',
              subtitle:
                  'Add income and expenses to see your cashflow projection',
              buttonLabel: 'Close',
              onButton: () => Navigator.pop(context),
            );
          }

          final activeForecast = forecasts.first;
          final spots = activeForecast.days
              .asMap()
              .entries
              .map((e) =>
                  FlSpot(e.key.toDouble(), e.value.projectedBalance))
              .toList();

          // compute aggregate stats
          final totalProjected = forecasts.fold<double>(
              0, (s, f) => s + f.projectedMonthEnd);
          final hasWarnings =
              forecasts.any((f) => f.warnings.isNotEmpty);

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildSummaryCard(
                      isDark: isDark,
                      activeForecast: activeForecast,
                      totalProjected: totalProjected,
                      hasWarnings: hasWarnings),
                ),
                SliverToBoxAdapter(
                  child: _buildChart(
                      isDark: isDark, spots: spots, textMuted: textMuted),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'MONTHLY BREAKDOWN',
                      style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ForecastRow(
                            forecast: forecasts[i],
                            isDark: isDark,
                            fmt: _fmt),
                      ),
                      childCount: forecasts.length,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required bool isDark,
    required CashflowForecast activeForecast,
    required double totalProjected,
    required bool hasWarnings,
  }) {
    final isPositive = totalProjected >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '6-Month Projection',
                    style: TextStyle(
                        color: AppColors.textMutedFor(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₹${_fmt.format(totalProjected.abs().toInt())}',
                    style: TextStyle(
                        color:
                            isPositive ? AppColors.success : AppColors.danger,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
              const Spacer(),
              if (hasWarnings)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.30),
                        width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.danger, size: 13),
                      const SizedBox(width: 4),
                      const Text(
                        'Alerts',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(
                label: 'Current Balance',
                value:
                    '₹${_fmt.format(activeForecast.currentBalance.toInt())}',
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _MiniStat(
                label: 'Low Balance Limit',
                value:
                    '₹${_fmt.format(activeForecast.lowBalanceThreshold.toInt())}',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart({
    required bool isDark,
    required List<FlSpot> spots,
    required Color textMuted,
  }) {
    return Container(
      height: 200,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: AppColors.borderFor(isDark), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Balance Trajectory',
              style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5),
            ),
          ),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      spots.isEmpty ? 1 : null,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.borderFor(isDark)
                        .withValues(alpha: 0.50),
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty
                        ? [const FlSpot(0, 0), const FlSpot(1, 0)]
                        : spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final c = AppColors.surfaceFor(isDark);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
            height: 130,
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(AppRadius.xl))),
        const SizedBox(height: 12),
        Container(
            height: 200,
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(AppRadius.lg))),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 110,
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(AppRadius.lg)),
          ),
        ),
      ],
    );
  }
}

// ─── Mini Stat ────────────────────────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _MiniStat(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceOffsetFor(isDark).withValues(alpha: 0.50),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: AppColors.borderFor(isDark).withValues(alpha: 0.60),
              width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: AppColors.textMutedFor(isDark),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    color: AppColors.textPrimaryFor(isDark),
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Forecast Row ─────────────────────────────────────────────────────────────
class _ForecastRow extends StatelessWidget {
  final CashflowForecast forecast;
  final bool isDark;
  final NumberFormat fmt;

  const _ForecastRow({
    required this.forecast,
    required this.isDark,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final monthLabel = forecast.days.isNotEmpty
        ? DateFormat('MMMM yyyy').format(forecast.days.first.date)
        : 'Forecast';
    final isPositive = forecast.projectedMonthEnd >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceFor(isDark),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: forecast.warnings.isNotEmpty
                ? AppColors.danger.withValues(alpha: 0.25)
                : AppColors.borderFor(isDark),
            width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? AppColors.success : AppColors.danger)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '₹${fmt.format(forecast.projectedMonthEnd.abs().toInt())}',
                  style: TextStyle(
                      color: isPositive
                          ? AppColors.success
                          : AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RowStat(
                label: 'Current',
                value: '₹${fmt.format(forecast.currentBalance.toInt())}',
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _RowStat(
                label: 'Threshold',
                value:
                    '₹${fmt.format(forecast.lowBalanceThreshold.toInt())}',
                isDark: isDark,
              ),
            ],
          ),
          if (forecast.lowBalanceDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 13),
                const SizedBox(width: 5),
                Text(
                  'Low balance expected ${DateFormat('d MMM').format(forecast.lowBalanceDate!)}',
                  style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          if (forecast.warnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...forecast.warnings.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style:
                            TextStyle(color: textMuted, fontSize: 11)),
                    Expanded(
                      child: Text(w,
                          style: TextStyle(
                              color: textMuted, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RowStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _RowStat(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textMutedFor(isDark),
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimaryFor(isDark),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
