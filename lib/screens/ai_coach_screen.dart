import 'package:flutter/material.dart';
import '../models/coach_insight.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final service = FirestoreServices();

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
        title: Text('AI Finance Coach',
            style: AppTextStyles.heading
                .copyWith(color: textPrimary, fontSize: 18)),
      ),
      body: StreamBuilder<List<CoachInsight>>(
        stream: service.getCoachInsights(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2));
          }
          final insights = snap.data ?? [];
          if (insights.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.psychology_outlined,
              title: 'No insights yet',
              subtitle:
                  'Add more expenses and the AI will analyse your patterns',
              buttonLabel: 'Refresh',
              onButton: () {},
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _InsightCard(
                insight: insights[i], isDark: isDark),
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final CoachInsight insight;
  final bool isDark;

  const _InsightCard({required this.insight, required this.isDark});

  Color get _typeColor {
    switch (insight.type) {
      case 'warning':
        return AppColors.danger;
      case 'tip':
        return AppColors.primary;
      case 'achievement':
        return AppColors.success;
      default:
        return AppColors.warning;
    }
  }

  IconData get _typeIcon {
    switch (insight.type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'tip':
        return Icons.lightbulb_outline_rounded;
      case 'achievement':
        return Icons.emoji_events_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final c = _typeColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: border, width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
              ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(_typeIcon, color: c, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.message,
                  style: TextStyle(color: textMuted, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
