import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_textfield.dart';
import '../widgets/primary_button.dart';
import '../widgets/kharcha_widgets.dart';

class PayLaterEntry {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String? note;

  PayLaterEntry({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.note,
  });

  factory PayLaterEntry.fromMap(Map<String, dynamic> m, String id) {
    return PayLaterEntry(
      id: id,
      title: m['title'] ?? '',
      amount: (m['amount'] ?? 0).toDouble(),
      dueDate: DateTime.fromMillisecondsSinceEpoch(m['dueDate'] ?? 0),
      isPaid: m['isPaid'] ?? false,
      note: m['note'],
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'amount': amount,
    'dueDate': dueDate.millisecondsSinceEpoch,
    'isPaid': isPaid,
    'note': note,
  };
}

class PayLaterScreen extends StatefulWidget {
  const PayLaterScreen({super.key});

  @override
  State<PayLaterScreen> createState() => _PayLaterScreenState();
}

class _PayLaterScreenState extends State<PayLaterScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreServices();
  final _fmt = NumberFormat('#,##,###');
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

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
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pay Later',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => _showAddSheet(context, isDark, card, border,
                textPrimary, textMuted),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.8),
              ),
              child: const Icon(Icons.add_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: border.withValues(alpha: 0.5)),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getPayLaterEntries(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            );
          }
          final raw = snap.data ?? [];
          final entries = raw
              .map((m) => PayLaterEntry.fromMap(m, m['id'] ?? ''))
              .toList();
          final unpaid = entries.where((e) => !e.isPaid).toList();
          final paid = entries.where((e) => e.isPaid).toList();

          if (entries.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.payment_outlined,
              title: 'No pending payments',
              subtitle: 'Track IOUs and upcoming bills here',
              buttonLabel: 'Add Entry',
              onButton: () => _showAddSheet(context, isDark, card, border,
                  textPrimary, textMuted),
            );
          }

          // ── Summary bar ──
          final totalUnpaid =
              unpaid.fold(0.0, (sum, e) => sum + e.amount);
          final overdue = unpaid
              .where((e) =>
                  e.dueDate.difference(DateTime.now()).inDays < 0)
              .length;

          return FadeTransition(
            opacity: _animCtrl,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _SummaryBanner(
                    totalUnpaid: totalUnpaid,
                    overdueCount: overdue,
                    pendingCount: unpaid.length,
                    fmt: _fmt,
                    isDark: isDark,
                  ),
                ),
                if (unpaid.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                        label: 'PENDING',
                        color: AppColors.danger,
                        textMuted: textMuted),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PayTile(
                      entry: unpaid[i],
                      isDark: isDark,
                      fmt: _fmt,
                      index: i,
                      onMark: () =>
                          _service.markPayLaterPaid(unpaid[i].id),
                      onDelete: () =>
                          _service.deletePayLaterEntry(unpaid[i].id),
                    ),
                    childCount: unpaid.length,
                  ),
                ),
                if (paid.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                        label: 'PAID',
                        color: AppColors.success,
                        textMuted: textMuted),
                  ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PayTile(
                      entry: paid[i],
                      isDark: isDark,
                      fmt: _fmt,
                      index: i,
                      onMark: () {},
                      onDelete: () =>
                          _service.deletePayLaterEntry(paid[i].id),
                    ),
                    childCount: paid.length,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
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
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: card,
      shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.sheetRadius),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
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
              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          AppColors.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payment_rounded,
                        color: AppColors.danger, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add Pay Later',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              PremiumTextField(
                controller: titleCtrl,
                label: 'Title',
                hint: 'e.g. Rent to Rohan',
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: amtCtrl,
                label: 'Amount (₹)',
                hint: '500',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              PremiumTextField(
                controller: noteCtrl,
                label: 'Note (optional)',
                hint: 'Any additional info',
              ),
              const SizedBox(height: 12),
              // Due date picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 3650)),
                    builder: (c, child) => Theme(
                      data: Theme.of(c).copyWith(
                        colorScheme: ColorScheme.dark(
                          primary: AppColors.primary,
                          surface: AppColors.surface2,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) setSt(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOffsetFor(isDark),
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                        color: AppColors.borderFor(isDark),
                        width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Due date',
                              style: TextStyle(
                                  color: textMuted, fontSize: 11)),
                          Text(
                            DateFormat('d MMM yyyy').format(dueDate),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          color: textMuted, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: 'Save Entry',
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amt =
                      double.tryParse(amtCtrl.text) ?? 0;
                  if (title.isEmpty || amt <= 0) return;
                  final entry = PayLaterEntry(
                    id: '',
                    title: title,
                    amount: amt,
                    dueDate: dueDate,
                    note: noteCtrl.text.trim().isNotEmpty
                        ? noteCtrl.text.trim()
                        : null,
                  );
                  await _service
                      .addPayLaterEntry(entry.toMap());
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

// ── Summary banner ────────────────────────────────────────────────────────
class _SummaryBanner extends StatelessWidget {
  final double totalUnpaid;
  final int overdueCount;
  final int pendingCount;
  final NumberFormat fmt;
  final bool isDark;

  const _SummaryBanner({
    required this.totalUnpaid,
    required this.overdueCount,
    required this.pendingCount,
    required this.fmt,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.danger.withValues(alpha: 0.12),
            AppColors.danger.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PENDING',
                  style: TextStyle(
                    color: AppColors.danger.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${fmt.format(totalUnpaid.toInt())}',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatChip(
                label: '$pendingCount pending',
                color: AppColors.warning,
              ),
              if (overdueCount > 0) ...[
                const SizedBox(height: 6),
                _StatChip(
                  label: '$overdueCount overdue',
                  color: AppColors.danger,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  final Color textMuted;
  const _SectionLabel(
      {required this.label,
      required this.color,
      required this.textMuted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pay tile ──────────────────────────────────────────────────────────────
class _PayTile extends StatelessWidget {
  final PayLaterEntry entry;
  final bool isDark;
  final NumberFormat fmt;
  final int index;
  final VoidCallback onMark;
  final VoidCallback onDelete;

  const _PayTile({
    required this.entry,
    required this.isDark,
    required this.fmt,
    required this.index,
    required this.onMark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final daysLeft =
        entry.dueDate.difference(DateTime.now()).inDays;
    final isOverdue = !entry.isPaid && daysLeft < 0;
    final isDueToday = !entry.isPaid && daysLeft == 0;

    Color statusColor = entry.isPaid
        ? AppColors.success
        : isOverdue
            ? AppColors.danger
            : isDueToday
                ? AppColors.warning
                : textMuted;

    String statusText = entry.isPaid
        ? 'Paid ✓'
        : isOverdue
            ? '${-daysLeft}d overdue'
            : isDueToday
                ? 'Due today!'
                : 'Due in ${daysLeft}d';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOut,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child:
            Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: Dismissible(
        key: Key(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline_rounded,
                  color: AppColors.danger, size: 22),
              const SizedBox(height: 2),
              Text('Delete',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: Container(
          margin: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: entry.isPaid
                  ? AppColors.success.withValues(alpha: 0.25)
                  : isOverdue
                      ? AppColors.danger.withValues(alpha: 0.25)
                      : border,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: entry.isPaid ? null : onMark,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: entry.isPaid
                        ? AppColors.success.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(
                      color: entry.isPaid
                          ? AppColors.success
                          : isOverdue
                              ? AppColors.danger
                              : AppColors.borderFor(isDark),
                      width: 1.5,
                    ),
                  ),
                  child: entry.isPaid
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.success, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: entry.isPaid
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor:
                            textMuted.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 11,
                          color: statusColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (entry.note != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '· ${entry.note}',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${fmt.format(entry.amount.toInt())}',
                    style: TextStyle(
                      color: entry.isPaid
                          ? textMuted
                          : isOverdue
                              ? AppColors.danger
                              : textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      decoration: entry.isPaid
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor:
                          textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    DateFormat('d MMM').format(entry.dueDate),
                    style: TextStyle(
                        color: textMuted.withValues(alpha: 0.6),
                        fontSize: 10),
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
