import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

enum PaymentMode { cash, upi, card, netBanking }

extension PaymentModeX on PaymentMode {
  String get label {
    switch (this) {
      case PaymentMode.cash: return 'Cash';
      case PaymentMode.upi: return 'UPI';
      case PaymentMode.card: return 'Card';
      case PaymentMode.netBanking: return 'Net Banking';
    }
  }
  Color get color {
    switch (this) {
      case PaymentMode.cash: return const Color(0xFFB85C5C);
      case PaymentMode.upi: return AppColors.primary;
      case PaymentMode.card: return AppColors.info;
      case PaymentMode.netBanking: return AppColors.warning;
    }
  }
}

/// Analytics widget — shows payment mode breakdown pie + legend.
/// Pass a map of PaymentMode → amount.
class PaymentModeChart extends StatefulWidget {
  final Map<PaymentMode, double> data;
  const PaymentModeChart({super.key, required this.data});

  @override
  State<PaymentModeChart> createState() => _PaymentModeChartState();
}

class _PaymentModeChartState extends State<PaymentModeChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final entries = widget.data.entries
        .where((e) => e.value > 0)
        .toList();

    final digitalPercent = [
      PaymentMode.upi, PaymentMode.card, PaymentMode.netBanking,
    ].fold<double>(0, (s, m) => s + (widget.data[m] ?? 0));
    final digitalPct = (digitalPercent / total * 100).toStringAsFixed(0);

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
              const Text('Payment Mode',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Spacer(),
              Text('$digitalPct% digital',
                  style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => SizedBox(
              height: 140,
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: PieChart(
                      PieChartData(
                        sections: entries.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final mode = entry.value.key;
                          final val = entry.value.value;
                          final touched = idx == _touchedIndex;
                          return PieChartSectionData(
                            value: val * _anim.value,
                            color: mode.color,
                            radius: touched ? 44 : 38,
                            title: touched ? '${(val / total * 100).toStringAsFixed(0)}%' : '',
                            titleStyle: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white,
                            ),
                          );
                        }).toList(),
                        centerSpaceRadius: 28,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: entries.map((e) {
                        final pct = (e.value / total * 100).toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                  color: e.key.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(e.key.label,
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ),
                              Text('$pct%',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }).toList(),
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
}
