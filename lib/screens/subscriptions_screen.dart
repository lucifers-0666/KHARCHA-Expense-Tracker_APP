import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_textfield.dart';
import '../widgets/primary_button.dart';
import '../widgets/kharcha_widgets.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');
  final List<String> _cycles = ['Monthly', 'Quarterly', 'Yearly'];
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
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
          'Subscriptions',
          style: AppTextStyles.heading.copyWith(color: textPrimary, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _showAddSheet(context, isDark),
              icon: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 18),
              label: const Text(
                'Add',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<SubscriptionModel>>(
        stream: _service.getSubscriptions(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer(isDark);
          }
          final subs = snap.data ?? [];
          if (subs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.subscriptions_outlined,
              title: 'No subscriptions tracked',
              subtitle: 'Add Netflix, Spotify, gym etc.',
              buttonLabel: 'Add Subscription',
              onButton: () => _showAddSheet(context, isDark),
            );
          }

          // compute totals
          double monthlyTotal = 0;
          double yearlyTotal = 0;
          int activeCount = 0;
          for (final sub in subs) {
            if (!sub.isActive) continue;
            activeCount++;
            if (sub.category == 'Monthly') {
              monthlyTotal += sub.monthlyAmount;
              yearlyTotal += sub.monthlyAmount * 12;
            } else if (sub.category == 'Quarterly') {
              monthlyTotal += sub.monthlyAmount / 3;
              yearlyTotal += sub.monthlyAmount * 4;
            } else if (sub.category == 'Yearly') {
              monthlyTotal += sub.monthlyAmount / 12;
              yearlyTotal += sub.monthlyAmount;
            }
          }

          // sort by due date
          final sorted = [...subs]
            ..sort((a, b) => a.nextRenewal.compareTo(b.nextRenewal));

          return FadeTransition(
            opacity: _fadeAnim,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildSummaryBanner(
                    isDark: isDark,
                    monthly: monthlyTotal,
                    yearly: yearlyTotal,
                    activeCount: activeCount,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SubTile(
                          sub: sorted[i],
                          isDark: isDark,
                          fmt: _fmt,
                          onDelete: () =>
                              _service.deleteSubscription(sorted[i].id),
                          onToggle: () => _service.toggleSubscription(
                              sorted[i].id, !sorted[i].isActive),
                        ),
                      ),
                      childCount: sorted.length,
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

  Widget _buildSummaryBanner({
    required bool isDark,
    required double monthly,
    required double yearly,
    required int activeCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.18),
            AppColors.warning.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.subscriptions_outlined,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Burn',
                    style: TextStyle(
                        color: AppColors.textMutedFor(isDark),
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '₹${_fmt.format(monthly.toInt())} / mo',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _StatPill(
                label: 'Yearly Cost',
                value: '₹${_fmt.format(yearly.toInt())}',
                isDark: isDark,
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: 'Active',
                value: '$activeCount subs',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final color = AppColors.surfaceFor(isDark);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
            height: 130,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.xl))),
        const SizedBox(height: 20),
        ...List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            height: 72,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.lg)),
          ),
        ),
      ],
    );
  }

  void _showAddSheet(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String category = 'Monthly';
    DateTime nextDue = DateTime.now().add(const Duration(days: 30));
    final card = AppColors.surfaceFor(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.borderFor(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'New Subscription',
                style: TextStyle(
                    color: AppColors.textPrimaryFor(isDark),
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your recurring bills in one place',
                style: TextStyle(
                    color: AppColors.textMutedFor(isDark), fontSize: 12),
              ),
              const SizedBox(height: 18),
              PremiumTextField(
                  controller: nameCtrl,
                  label: 'Service Name',
                  hint: 'e.g. Netflix, Spotify'),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: amtCtrl,
                label: 'Amount (₹)',
                hint: '199',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text(
                'Billing Cycle',
                style: TextStyle(
                    color: AppColors.textMutedFor(isDark),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Row(
                children: _cycles
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setSt(() => category = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: category == c
                                  ? AppColors.warning.withValues(alpha: 0.15)
                                  : AppColors.surfaceOffsetFor(isDark),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: category == c
                                    ? AppColors.warning.withValues(alpha: 0.50)
                                    : AppColors.borderFor(isDark),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(
                                color: category == c
                                    ? AppColors.warning
                                    : AppColors.textMutedFor(isDark),
                                fontSize: 12,
                                fontWeight: category == c
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: nextDue,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setSt(() => nextDue = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOffsetFor(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.borderFor(isDark), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppColors.warning, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Next Due: ${DateFormat('d MMM yyyy').format(nextDue)}',
                        style: TextStyle(
                            color: AppColors.textMutedFor(isDark),
                            fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Save Subscription',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
                  if (name.isEmpty || amt <= 0) return;
                  final sub = SubscriptionModel(
                    id: '',
                    name: name,
                    category: category,
                    monthlyAmount: amt,
                    nextRenewal: nextDue,
                    isActive: true,
                  );
                  await _service.addSubscription(sub);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Pill ───────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  const _StatPill(
      {required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

// ─── Sub Tile ─────────────────────────────────────────────────────────────────
class _SubTile extends StatelessWidget {
  final SubscriptionModel sub;
  final bool isDark;
  final NumberFormat fmt;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _SubTile({
    required this.sub,
    required this.isDark,
    required this.fmt,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final daysLeft = sub.nextRenewal.difference(DateTime.now()).inDays;
    final isDue = daysLeft <= 3;
    final isInactive = !sub.isActive;

    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedOpacity(
        opacity: isInactive ? 0.50 : 1.0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isDue
                  ? AppColors.danger.withValues(alpha: 0.35)
                  : border,
              width: isDue ? 1.0 : 0.8,
            ),
          ),
          child: Row(
            children: [
              // icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.subscriptions_outlined,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.name,
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.10),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            sub.category,
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDue
                              ? 'Due in $daysLeft days!'
                              : 'Renews in $daysLeft days',
                          style: TextStyle(
                            color: isDue ? AppColors.danger : textMuted,
                            fontSize: 11,
                            fontWeight: isDue
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${fmt.format(sub.monthlyAmount.toInt())}',
                    style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 15,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: sub.isActive
                            ? AppColors.success.withValues(alpha: 0.12)
                            : AppColors.borderFor(isDark)
                                .withValues(alpha: 0.30),
                        borderRadius:
                            BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        sub.isActive ? 'Active' : 'Paused',
                        style: TextStyle(
                          color: sub.isActive
                              ? AppColors.success
                              : textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
