import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/firestore_services.dart';
import '../models/savings_goal.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_textfield.dart';
import '../widgets/primary_button.dart';

// ─── Templates ────────────────────────────────────────────────────────────────
const _templates = [
  {'emoji': '🏍️', 'label': 'Bike', 'target': 80000, 'type': 'bike'},
  {'emoji': '🚨', 'label': 'Emergency', 'target': 50000, 'type': 'emergencyFund'},
  {'emoji': '💻', 'label': 'MacBook', 'target': 120000, 'type': 'laptop'},
  {'emoji': '✈️', 'label': 'Vacation', 'target': 40000, 'type': 'vacation'},
  {'emoji': '🏠', 'label': 'Home', 'target': 500000, 'type': 'homeDownPayment'},
  {'emoji': '🚗', 'label': 'Car', 'target': 200000, 'type': 'car'},
];

const _tips = [
  '💡 Save at least 20% of your monthly income.',
  '📅 Set a deadline — goals with dates are 3× more likely to succeed.',
  '🔁 Automate transfers on salary day.',
  '📊 Break big goals into monthly milestones.',
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class SavingsGoalsScreen extends StatefulWidget {
  const SavingsGoalsScreen({super.key});
  @override
  State<SavingsGoalsScreen> createState() => _SavingsGoalsScreenState();
}

class _SavingsGoalsScreenState extends State<SavingsGoalsScreen>
    with TickerProviderStateMixin {
  final _svc = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');
  late AnimationController _heroCtrl;
  late Animation<double> _heroFade;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
    _heroFade = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<List<SavingsGoal>>(
        stream: _svc.getSavingsGoals(),
        builder: (ctx, snap) {
          final goals = snap.data ?? [];
          final totalTarget = goals.fold(0.0, (s, g) => s + g.targetAmount);
          final totalSaved = goals.fold(0.0, (s, g) => s + g.savedAmount);

          return CustomScrollView(
            slivers: [
              // ── AppBar ──
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: const Color(0xFF1A1A2E),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text('Savings Goals',
                    style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                actions: [
                  GestureDetector(
                    onTap: () => _showAddSheet(context),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('+ Goal',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                        height: 1, color: const Color(0xFFE8F5E9))),
              ),

              // ── Hero card ──
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _heroFade,
                  child: _HeroCard(
                      totalSaved: totalSaved,
                      totalTarget: totalTarget,
                      fmt: _fmt,
                      goalCount: goals.length),
                ),
              ),

              // ── Goal templates ──
              SliverToBoxAdapter(
                  child: _SectionHeader(
                      title: 'Quick Start Templates',
                      subtitle: 'Tap to create a goal instantly')),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 12),
                    itemCount: _templates.length,
                    itemBuilder: (_, i) {
                      final t = _templates[i];
                      return _TemplateChip(
                        emoji: t['emoji'] as String,
                        label: t['label'] as String,
                        amount: t['target'] as int,
                        fmt: _fmt,
                        onTap: () => _showAddSheet(
                          context,
                          prefillTitle: t['label'] as String,
                          prefillEmoji: t['emoji'] as String,
                          prefillTarget: t['target'] as int,
                          prefillType:
                              GoalTypeExt.fromString(t['type'] as String),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Active goals or empty state ──
              if (goals.isEmpty) ...[
                SliverToBoxAdapter(
                    child: _SectionHeader(
                        title: 'Your Goals',
                        subtitle: 'Nothing yet — start below')),
                SliverToBoxAdapter(
                    child: _EmptyGoalsState(
                        onAdd: () => _showAddSheet(context))),
              ] else ...[
                SliverToBoxAdapter(
                    child: _SectionHeader(
                        title: 'Your Goals (${goals.length})',
                        subtitle: 'Swipe left to delete')),
                SliverList(
                    delegate: SliverChildBuilderDelegate(
                  (_, i) => _GoalCard(
                      goal: goals[i],
                      fmt: _fmt,
                      onAddSavings: (g) =>
                          _showAddSavingsSheet(context, g),
                      onDelete: (g) => _svc.deleteSavingsGoal(g.id)),
                  childCount: goals.length,
                )),
              ],

              // ── Tips ──
              SliverToBoxAdapter(
                  child: _SectionHeader(
                      title: 'Savings Tips',
                      subtitle: 'Build better habits')),
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                (_, i) => _TipCard(tip: _tips[i]),
                childCount: _tips.length,
              )),
              const SliverPadding(
                  padding: EdgeInsets.only(bottom: 40)),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(
    BuildContext ctx, {
    String prefillTitle = '',
    String prefillEmoji = '🎯',
    int prefillTarget = 0,
    GoalType prefillType = GoalType.custom,
  }) {
    final titleCtrl = TextEditingController(text: prefillTitle);
    final targetCtrl = TextEditingController(
        text: prefillTarget > 0 ? prefillTarget.toString() : '');
    final savedCtrl = TextEditingController();
    GoalType selectedType = prefillType;
    DateTime targetDate = DateTime.now().add(const Duration(days: 180));

    final emojis = [
      '🎯', '🏍️', '💻', '✈️', '🏠', '💍', '📱', '🚨', '🎓', '🏋️'
    ];
    String emoji = prefillEmoji;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Row(children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.savings_rounded,
                          color: AppColors.primary, size: 20)),
                  const SizedBox(width: 10),
                  const Text('New Savings Goal',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                ]),
                const SizedBox(height: 20),
                // Emoji picker
                SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: emojis.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 8),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => setSt(() => emoji = emojis[i]),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: emoji == emojis[i]
                                ? AppColors.primary
                                    .withValues(alpha: 0.15)
                                : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: emoji == emojis[i]
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Center(
                              child: Text(emojis[i],
                                  style:
                                      const TextStyle(fontSize: 20))),
                        ),
                      ),
                    )),
                const SizedBox(height: 14),
                PremiumTextField(
                    controller: titleCtrl,
                    label: 'Goal Title',
                    hint: 'e.g. New iPhone'),
                const SizedBox(height: 12),
                PremiumTextField(
                    controller: targetCtrl,
                    label: 'Target Amount (₹)',
                    hint: '50000',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                PremiumTextField(
                    controller: savedCtrl,
                    label: 'Already Saved (₹)',
                    hint: '0',
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                // Target date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx2,
                      initialDate: targetDate,
                      firstDate: DateTime.now()
                          .add(const Duration(days: 1)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setSt(() => targetDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFE0E0E0), width: 1),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today_outlined,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Target Date: ${DateFormat('d MMM yyyy').format(targetDate)}',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF555555)),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                    label: 'Create Goal',
                    onPressed: () async {
                      final title = titleCtrl.text.trim();
                      final target =
                          double.tryParse(targetCtrl.text) ?? 0;
                      if (title.isEmpty || target <= 0) return;
                      final g = SavingsGoal(
                        id: '',
                        title: title,
                        type: selectedType,
                        targetAmount: target,
                        savedAmount:
                            double.tryParse(savedCtrl.text) ?? 0,
                        targetDate: targetDate,
                        createdAt: DateTime.now(),
                      );
                      await _svc.addSavingsGoal(g);
                      if (ctx.mounted) Navigator.pop(ctx);
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSavingsSheet(BuildContext ctx, SavingsGoal goal) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Add to ${goal.type.emoji} ${goal.title}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            PremiumTextField(
                controller: ctrl,
                label: 'Amount (₹)',
                hint: '500',
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Add Savings',
                onPressed: () async {
                  final amt = double.tryParse(ctrl.text) ?? 0;
                  if (amt <= 0) return;
                  await _svc.addToSavingsGoal(goal.id, amt);
                  if (ctx.mounted) Navigator.pop(ctx);
                }),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final double totalSaved, totalTarget;
  final NumberFormat fmt;
  final int goalCount;
  const _HeroCard(
      {required this.totalSaved,
      required this.totalTarget,
      required this.fmt,
      required this.goalCount});

  @override
  Widget build(BuildContext context) {
    final pct = totalTarget > 0
        ? (totalSaved / totalTarget * 100).clamp(0, 100).toStringAsFixed(1)
        : '0';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.75)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.savings_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 7),
            const Text('TOTAL SAVINGS PROGRESS',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$goalCount goals',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 16),
          Text('₹${fmt.format(totalSaved.toInt())}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          Text('of ₹${fmt.format(totalTarget.toInt())} target',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalTarget > 0 ? totalSaved / totalTarget : 0,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('$pct% of your total goal achieved',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.rocket_launch_rounded,
                  color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'Start building your future — track dreams, gadgets, trips & emergency funds',
                      style:
                          TextStyle(color: Colors.white, fontSize: 12))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Template Chip ────────────────────────────────────────────────────────────
class _TemplateChip extends StatelessWidget {
  final String emoji, label;
  final int amount;
  final NumberFormat fmt;
  final VoidCallback onTap;
  const _TemplateChip(
      {required this.emoji,
      required this.label,
      required this.amount,
      required this.fmt,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 2),
            Text('₹${fmt.format(amount)}',
                style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Goal Card ────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final NumberFormat fmt;
  final void Function(SavingsGoal) onAddSavings;
  final void Function(SavingsGoal) onDelete;
  const _GoalCard(
      {required this.goal,
      required this.fmt,
      required this.onAddSavings,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final remaining = goal.remaining;
    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.redAccent),
      ),
      onDismissed: (_) => onDelete(goal),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE8F5E9), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                    child: Text(goal.type.emoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(goal.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  Text('₹${fmt.format(remaining.toInt())} remaining',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              )),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${fmt.format(goal.savedAmount.toInt())}',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                  Text(
                      'of ₹${fmt.format(goal.targetAmount.toInt())}',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400)),
                ],
              ),
            ]),
            const SizedBox(height: 14),
            _AnimatedRingWithBar(progress: goal.progressPercent),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => onAddSavings(goal),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Center(
                    child: Text('+ Add Money',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedRingWithBar extends StatelessWidget {
  final double progress;
  const _AnimatedRingWithBar({required this.progress});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(progress * 100).toStringAsFixed(0)}% saved',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            Text('${(100 - progress * 100).toStringAsFixed(0)}% left',
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF9E9E9E))),
          ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            backgroundColor: const Color(0xFFE8F5E9),
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 10,
          ),
        ),
      ),
    ]);
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyGoalsState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGoalsState({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FFF9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Column(children: [
            const Text('🎯',
                style: TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            const Text('No goals yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text(
                'Create your first savings goal and start building your financial future.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            _OnboardStep(
                num: '1',
                text:
                    'Choose a goal — bike, laptop, vacation or emergency fund'),
            _OnboardStep(
                num: '2',
                text: 'Set your target amount and timeline'),
            _OnboardStep(
                num: '3',
                text: 'Track progress and celebrate milestones'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Create My First Goal',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _OnboardStep extends StatelessWidget {
  final String num, text;
  const _OnboardStep({required this.num, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
              color: AppColors.primary, shape: BoxShape.circle),
          child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF555555)))),
      ]),
    );
  }
}

// ─── Tip Card ─────────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final String tip;
  const _TipCard({required this.tip});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(tip,
          style: TextStyle(
              fontSize: 13, color: Colors.grey.shade700)),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title, subtitle;
  const _SectionHeader({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF9E9E9E))),
      ]),
    );
  }
}
