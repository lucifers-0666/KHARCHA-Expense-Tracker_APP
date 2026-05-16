import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/subscription_model.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _service = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');

  final List<String> _cycles = ['Monthly', 'Quarterly', 'Yearly'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
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
        title: Text('Subscriptions',
            style: AppTextStyles.heading
                .copyWith(color: textPrimary, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddSheet(
                context, isDark, card, border, textPrimary, textMuted),
          ),
        ],
      ),
      body: StreamBuilder<List<SubscriptionModel>>(
        stream: _service.getSubscriptions(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2));
          }
          final subs = snap.data ?? [];
          if (subs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.subscriptions_outlined,
              title: 'No subscriptions tracked',
              subtitle: 'Add Netflix, Spotify, gym etc.',
              buttonLabel: 'Add Subscription',
              onButton: () => _showAddSheet(context, isDark, card,
                  border, textPrimary, textMuted),
            );
          }
          final totalMonthly = subs.fold<double>(0, (s, sub) {
            if (sub.billingCycle == 'Monthly') return s + sub.amount;
            if (sub.billingCycle == 'Yearly') return s + sub.amount / 12;
            if (sub.billingCycle == 'Quarterly') return s + sub.amount / 3;
            return s;
          });
          return Column(
            children: [
              _SubSummaryCard(
                  monthly: totalMonthly, isDark: isDark, fmt: _fmt),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: subs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _SubTile(
                      sub: subs[i],
                      isDark: isDark,
                      fmt: _fmt,
                      onDelete: () =>
                          _service.deleteSubscription(subs[i].id)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(
    BuildContext context,
    bool isDark,
    Color card,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    String cycle = 'Monthly';
    DateTime nextDue = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetRadius),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: AppColors.borderFor(isDark),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Add Subscription',
                  style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              PremiumTextField(
                  controller: nameCtrl,
                  label: 'Service Name',
                  hint: 'e.g. Netflix'),
              const SizedBox(height: 12),
              PremiumTextField(
                  controller: amtCtrl,
                  label: 'Amount (₹)',
                  hint: '199',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _cycles
                    .map((c) => ChoiceChip(
                          label: Text(c),
                          selected: cycle == c,
                          onSelected: (_) => setSt(() => cycle = c),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.20),
                          labelStyle: TextStyle(
                              color: cycle == c
                                  ? AppColors.primary
                                  : textMuted,
                              fontSize: 12),
                        ))
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
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Next Due: ${DateFormat('d MMM yyyy').format(nextDue)}',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save Subscription',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
                  if (name.isEmpty || amt <= 0) return;
                  final sub = SubscriptionModel(
                    id: '',
                    name: name,
                    amount: amt,
                    billingCycle: cycle,
                    nextDueDate: nextDue,
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

class _SubSummaryCard extends StatelessWidget {
  final double monthly;
  final bool isDark;
  final NumberFormat fmt;
  const _SubSummaryCard(
      {required this.monthly,
      required this.isDark,
      required this.fmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.20), width: 0.8),
      ),
      child: Row(
        children: [
          const Icon(Icons.subscriptions_outlined,
              color: AppColors.warning, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Subscriptions',
                  style: TextStyle(
                      color: AppColors.textMutedFor(isDark),
                      fontSize: 11)),
              Text('₹${fmt.format(monthly.toInt())} / month',
                  style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  final SubscriptionModel sub;
  final bool isDark;
  final NumberFormat fmt;
  final VoidCallback onDelete;

  const _SubTile({
    required this.sub,
    required this.isDark,
    required this.fmt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final daysLeft =
        sub.nextDueDate.difference(DateTime.now()).inDays;

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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.subscriptions_outlined,
                  color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub.name,
                      style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(
                    '${sub.billingCycle} • due in $daysLeft days',
                    style: TextStyle(
                        color: daysLeft <= 3
                            ? AppColors.danger
                            : textMuted,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            Text(
              '₹${fmt.format(sub.amount.toInt())}',
              style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 14,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
