import 'package:flutter/material.dart';
import '../models/smart_insight.dart';
import '../services/smart_insights_service.dart';
import '../theme/app_theme.dart';

/// Drop-in dashboard widget. Shows active non-dismissed insights.
/// Usage: SmartInsightsCard() — place inside a Column/ListView on the dashboard.
class SmartInsightsCard extends StatelessWidget {
  const SmartInsightsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SmartInsight>>(
      stream: SmartInsightsService().insightsStream,
      builder: (context, snap) {
        final all = snap.data ?? [];
        final visible = all.where((i) => !i.isDismissed).toList();
        if (visible.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Smart Insights',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _InsightChip(insight: visible[i]),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _InsightChip extends StatefulWidget {
  final SmartInsight insight;
  const _InsightChip({required this.insight});
  @override
  State<_InsightChip> createState() => _InsightChipState();
}

class _InsightChipState extends State<_InsightChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _bgColor {
    switch (widget.insight.severity) {
      case InsightSeverity.danger: return AppColors.dangerSoft;
      case InsightSeverity.warning: return AppColors.warningSoft;
      case InsightSeverity.info: return AppColors.accentSoft;
    }
  }

  Color get _iconColor {
    switch (widget.insight.severity) {
      case InsightSeverity.danger: return AppColors.danger;
      case InsightSeverity.warning: return AppColors.warning;
      case InsightSeverity.info: return AppColors.primary;
    }
  }

  IconData get _icon {
    switch (widget.insight.type) {
      case InsightType.anomaly: return Icons.trending_up_rounded;
      case InsightType.burnRate: return Icons.local_fire_department_rounded;
      case InsightType.savings: return Icons.savings_rounded;
      case InsightType.achievement: return Icons.star_rounded;
      case InsightType.tip: return Icons.lightbulb_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _iconColor.withValues(alpha: 0.2), width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_icon, color: _iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.insight.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: _iconColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(widget.insight.message,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => SmartInsightsService().dismiss(widget.insight.id),
                child: Icon(Icons.close_rounded, size: 14, color: AppColors.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
