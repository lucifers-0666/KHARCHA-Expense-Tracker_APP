import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_textfield.dart';
import '../widgets/primary_button.dart';
import '../widgets/kharcha_widgets.dart';

class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});

  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen> {
  final _service = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');

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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Savings Goals',
          style: AppTextStyles.heading.copyWith(
            color: textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddGoalSheet(
              context,
              isDark,
              card,
              border,
              textPrimary,
              textMuted,
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<SavingsGoal>>(
        stream: _service.getSavingsGoals(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }
          final goals = snap.data ?? [];
          if (goals.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.savings_outlined,
              title: 'No savings goals yet',
              subtitle: 'Tap + to set your first goal',
              buttonLabel: 'Add Goal',
              onButton: () => _showAddGoalSheet(
                context,
                isDark,
                card,
                border,
                textPrimary,
                textMuted,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: goals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) =>
                _GoalCard(goal: goals[i], isDark: isDark, fmt: _fmt),
          );
        },
      ),
    );
  }

  void _showAddGoalSheet(
    BuildContext context,
    bool isDark,
    Color card,
    Color border,
    Color textPrimary,
    Color textMuted,
  ) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 90));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetRadius),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'New Savings Goal',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: nameCtrl,
                label: 'Goal Name',
                hint: 'e.g. Emergency Fund',
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: amountCtrl,
                label: 'Current Saved (₹)',
                hint: '0',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: targetCtrl,
                label: 'Target Amount (₹)',
                hint: '50000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: deadline,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setSt(() => deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOffsetFor(isDark),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.borderFor(isDark),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Deadline: ${DateFormat('d MMM yyyy').format(deadline)}',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save Goal',
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final saved = double.tryParse(amountCtrl.text) ?? 0;
                  final target = double.tryParse(targetCtrl.text) ?? 0;
                  if (name.isEmpty || target <= 0) return;
                  final goal = SavingsGoal(
                    id: '',
                    title: name,
                    type: GoalType.custom,
                    targetAmount: target,
                    savedAmount: saved,
                    targetDate: deadline,
                    createdAt: DateTime.now(),
                  );
                  await _service.addSavingsGoal(goal);
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

class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;
  final NumberFormat fmt;

  const _GoalCard({
    required this.goal,
    required this.isDark,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final progress = goal.targetAmount > 0
        ? goal.savedAmount / goal.targetAmount
        : 0.0;
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(1);
    final daysLeft = goal.targetDate.difference(DateTime.now()).inDays;

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
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${fmt.format(goal.savedAmount.toInt())}',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' / ₹${fmt.format(goal.targetAmount.toInt())}',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
              const Spacer(),
              Icon(Icons.schedule_rounded, color: textMuted, size: 12),
              const SizedBox(width: 3),
              Text(
                daysLeft >= 0
                    ? '$daysLeft days left'
                    : '${(-daysLeft)} days overdue',
                style: TextStyle(
                  color: daysLeft >= 0 ? textMuted : AppColors.danger,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
