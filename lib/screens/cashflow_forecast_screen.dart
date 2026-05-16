import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/cashflow_forecast.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class CashflowForecastScreen extends StatelessWidget {
  const CashflowForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final service = FirestoreServices();
    final fmt = NumberFormat('#,##,###');

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cashflow Forecast',
          style: AppTextStyles.heading.copyWith(
            color: textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<List<CashflowForecast>>(
        stream: service.getCashflowForecasts(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
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
              .map((e) => FlSpot(e.key.toDouble(), e.value.projectedBalance))
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next 6 Months',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceFor(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.borderFor(isDark),
                      width: 0.8,
                    ),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
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
                const SizedBox(height: 20),
                ...forecasts.map(
                  (f) => _ForecastRow(forecast: f, isDark: isDark, fmt: fmt),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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
        ? DateFormat('MMM yyyy').format(forecast.days.first.date)
        : 'Forecast';
    final isPositive = forecast.projectedMonthEnd >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceFor(isDark),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderFor(isDark), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  monthLabel,
                  style: TextStyle(color: textMuted, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '₹${fmt.format(forecast.projectedMonthEnd.toInt())}',
                  style: TextStyle(
                    color: isPositive ? AppColors.primary : AppColors.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Current balance: ₹${fmt.format(forecast.currentBalance.toInt())}',
              style: TextStyle(color: textPrimary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'Low balance threshold: ₹${fmt.format(forecast.lowBalanceThreshold.toInt())}',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
            if (forecast.lowBalanceDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Low balance date: ${DateFormat('d MMM').format(forecast.lowBalanceDate!)}',
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            if (forecast.warnings.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...forecast.warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $w',
                    style: TextStyle(color: textMuted, fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
