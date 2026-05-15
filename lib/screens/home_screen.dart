import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../widgets/premium_card.dart';
import '../widgets/section_header.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid  = user?.uid ?? '';
    final name = user?.displayName?.split(' ').first ?? 'there';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPri  = isDark ? AppColors.textPrimaryDark  : AppColors.textPrimaryLight;
    final textMuted= isDark ? AppColors.textMutedDark    : AppColors.textMutedLight;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: RefreshIndicator(
          color: isDark ? AppColors.mutedOlive : AppColors.charcoal,
          backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
          onRefresh: () async => await Future.delayed(const Duration(milliseconds: 500)),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHPad, AppSpacing.pageVPad,
                    AppSpacing.pageHPad, 0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: AppTextStyles.caption.copyWith(color: textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Hi, $name',
                              style: AppTextStyles.title.copyWith(color: textPri),
                            ),
                          ],
                        ),
                      ),
                      // Notification icon
                      _IconBtn(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Avatar
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceOffLight,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'K',
                          style: AppTextStyles.subtitle.copyWith(
                            color: isDark
                                ? AppColors.mutedOlive
                                : AppColors.charcoal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

              // Balance card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHPad),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users').doc(uid)
                        .collection('expenses')
                        .where('date', isGreaterThanOrEqualTo: monthStart)
                        .snapshots(),
                    builder: (ctx, snap) {
                      double totalSpent = 0;
                      if (snap.hasData) {
                        for (final d in snap.data!.docs) {
                          final data = d.data() as Map<String, dynamic>;
                          totalSpent += (data['amount'] as num?)?.toDouble() ?? 0;
                        }
                      }
                      return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users').doc(uid)
                            .collection('budgets')
                            .doc('monthly')
                            .snapshots(),
                        builder: (ctx2, budgetSnap) {
                          double budget = 0;
                          if (budgetSnap.hasData && budgetSnap.data!.exists) {
                            budget = ((budgetSnap.data!.data()
                                as Map<String, dynamic>?)?['amount'] as num?)
                                ?.toDouble() ?? 0;
                          }
                          final remaining = (budget - totalSpent).clamp(0, double.infinity);
                          final progress = budget > 0
                              ? (totalSpent / budget).clamp(0.0, 1.0)
                              : 0.0;
                          return _BalanceCard(
                            spent: totalSpent,
                            budget: budget,
                            remaining: remaining.toDouble(),
                            progress: progress.toDouble(),
                            isDark: isDark,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),

              // Quick actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHPad),
                  child: Row(
                    children: [
                      _QuickAction(
                        icon: Icons.add_rounded,
                        label: 'Expense',
                        onTap: () => Navigator.pushNamed(context, '/add-expense'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _QuickAction(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Income',
                        onTap: () => Navigator.pushNamed(context, '/income'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _QuickAction(
                        icon: Icons.sms_rounded,
                        label: 'Import SMS',
                        onTap: () => Navigator.pushNamed(context, '/sms-import'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _QuickAction(
                        icon: Icons.bar_chart_rounded,
                        label: 'Reports',
                        onTap: () => Navigator.pushNamed(context, '/export'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sectionGap)),

              // Transactions header
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'Recent',
                  actionLabel: 'See All',
                  onAction: () => Navigator.pushNamed(context, '/search'),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

              // Transactions list
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users').doc(uid)
                      .collection('expenses')
                      .orderBy('date', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return _SkeletonList();
                    }
                    if (snap.hasError) {
                      return _ErrorCard(isDark: isDark);
                    }
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'No expenses yet',
                        subtitle: 'Add your first expense to start tracking.',
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.pageHPad),
                      child: PremiumCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (int i = 0; i < docs.length; i++) ...[
                              _buildTile(docs[i], isDark),
                              if (i < docs.length - 1)
                                Divider(
                                  height: 1,
                                  indent: 58 + AppSpacing.pageHPad,
                                  color: isDark
                                      ? AppColors.dividerDark
                                      : AppColors.dividerLight,
                                ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
    final title  = data['merchant'] as String? ?? data['title'] as String? ?? 'Expense';
    final cat    = data['category'] as String? ?? 'Other';
    DateTime date;
    try {
      date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }
    return TransactionTile(
      title: title,
      category: cat,
      amount: amount,
      date: date,
      isExpense: true,
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _BalanceCard extends StatelessWidget {
  final double spent, budget, remaining, progress;
  final bool isDark;
  const _BalanceCard({
    required this.spent, required this.budget,
    required this.remaining, required this.progress, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPri = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final progressColor = progress > 0.85
        ? AppColors.danger
        : progress > 0.6
            ? AppColors.warning
            : AppColors.success;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MONTHLY SPENDING', style: AppTextStyles.label.copyWith(color: textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '\u20b9${spent.toStringAsFixed(0)}',
            style: AppTextStyles.amountLarge.copyWith(color: textPri),
          ),
          if (budget > 0) ...[
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? AppColors.surfaceOffDark
                          : AppColors.surfaceOffLight,
                      valueColor: AlwaysStoppedAnimation(progressColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: AppTextStyles.caption.copyWith(
                    color: progressColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatPill(label: 'Budget', value: '\u20b9${budget.toStringAsFixed(0)}', isDark: isDark),
                const SizedBox(width: AppSpacing.md),
                _StatPill(label: 'Remaining', value: '\u20b9${remaining.toStringAsFixed(0)}',
                    isDark: isDark, highlight: true),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded,
                      size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text('Set monthly budget',
                      style: AppTextStyles.caption.copyWith(color: textMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value;
  final bool isDark, highlight;
  const _StatPill({
    required this.label, required this.value,
    required this.isDark, this.highlight = false,
  });
  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPri = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label.copyWith(color: textMuted)),
          const SizedBox(height: 2),
          Text(value,
              style: AppTextStyles.subtitle.copyWith(
                  color: highlight ? AppColors.success : textPri,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  const _QuickAction({
    required this.icon, required this.label,
    required this.onTap, required this.isDark,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.cardLight,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            ),
            boxShadow: isDark ? null : [
              BoxShadow(color: AppColors.shadowColor, blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isDark ? AppColors.mutedOlive : AppColors.charcoal,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHPad),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: List.generate(5, (i) => Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: 14),
            child: Row(
              children: [
                _Shimmer(width: 42, height: 42, radius: AppRadius.md, isDark: isDark),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Shimmer(width: 120, height: 14, radius: 4, isDark: isDark),
                      const SizedBox(height: 6),
                      _Shimmer(width: 70, height: 11, radius: 4, isDark: isDark),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _Shimmer(width: 60, height: 14, radius: 4, isDark: isDark),
                    const SizedBox(height: 6),
                    _Shimmer(width: 40, height: 11, radius: 4, isDark: isDark),
                  ],
                ),
              ],
            ),
          )),
        ),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double width, height, radius;
  final bool isDark;
  const _Shimmer({required this.width, required this.height, required this.radius, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfaceOffDark : AppColors.surfaceOffLight,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  final bool isDark;
  const _ErrorCard({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageHPad),
      child: PremiumCard(
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.textMutedLight, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Unable to load expenses',
                      style: AppTextStyles.subtitle),
                  Text('Please check your connection and try again.',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _IconBtn({required this.icon, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        child: Icon(icon, size: 18,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      ),
    );
  }
}
