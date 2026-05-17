import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/coach_insight.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreServices();
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.psychology_outlined,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              'AI Finance Coach',
              style: AppTextStyles.heading
                  .copyWith(color: textPrimary, fontSize: 18),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<CoachInsight>>(
        stream: _service.getCoachInsights(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer(isDark);
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

          // separate by priority
          final high = insights
              .where((i) => i.priority == InsightPriority.high)
              .toList();
          final rest = insights
              .where((i) => i.priority != InsightPriority.high)
              .toList();

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child: _buildHeaderBanner(isDark, insights.length)),
                if (high.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'NEEDS ATTENTION',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InsightCard(
                              insight: high[i], isDark: isDark),
                        ),
                        childCount: high.length,
                      ),
                    ),
                  ),
                ],
                if (rest.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'INSIGHTS',
                        style: TextStyle(
                            color: AppColors.textMutedFor(isDark),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InsightCard(
                              insight: rest[i], isDark: isDark),
                        ),
                        childCount: rest.length,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark, int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22), width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your financial health report',
                  style: TextStyle(
                      color: AppColors.textPrimaryFor(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count personalised insights generated from your spending patterns.',
                  style: TextStyle(
                      color: AppColors.textMutedFor(isDark), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800),
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
            height: 90,
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(AppRadius.xl))),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
            decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(AppRadius.lg)),
          ),
        ),
      ],
    );
  }
}

// ─── Insight Card ─────────────────────────────────────────────────────────────
class _InsightCard extends StatelessWidget {
  final CoachInsight insight;
  final bool isDark;

  const _InsightCard({required this.insight, required this.isDark});

  Color get _accentColor {
    switch (insight.priority) {
      case InsightPriority.high:
        return AppColors.danger;
      case InsightPriority.medium:
        return AppColors.warning;
      case InsightPriority.low:
        return AppColors.success;
    }
  }

  IconData get _categoryIcon {
    switch (insight.category) {
      case InsightCategory.budget:
        return Icons.account_balance_wallet_outlined;
      case InsightCategory.savings:
        return Icons.savings_outlined;
      case InsightCategory.emi:
        return Icons.receipt_long_outlined;
      case InsightCategory.subscription:
        return Icons.subscriptions_outlined;
      case InsightCategory.goal:
        return Icons.flag_outlined;
      case InsightCategory.cashflow:
        return Icons.show_chart_rounded;
      case InsightCategory.weekly:
        return Icons.calendar_month_outlined;
      case InsightCategory.spending:
        return Icons.lightbulb_outline_rounded;
    }
  }

  String get _priorityLabel {
    switch (insight.priority) {
      case InsightPriority.high:
        return 'HIGH';
      case InsightPriority.medium:
        return 'MEDIUM';
      case InsightPriority.low:
        return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final c = _accentColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: insight.priority == InsightPriority.high
              ? c.withValues(alpha: 0.30)
              : border,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    insight.emoji,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            _priorityLabel,
                            style: TextStyle(
                                color: c,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          insight.category.name.toUpperCase(),
                          style: TextStyle(
                              color: textMuted,
                              fontSize: 10,
                              letterSpacing: 0.6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(_categoryIcon, color: textMuted, size: 16),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.message,
            style: TextStyle(
                color: textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4),
          ),
          if (insight.actionLabel != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.arrow_forward_rounded, color: c, size: 14),
                const SizedBox(width: 4),
                Text(
                  insight.actionLabel!,
                  style: TextStyle(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            DateFormat('d MMM yyyy').format(insight.generatedAt),
            style: TextStyle(color: textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
