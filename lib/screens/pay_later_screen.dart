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

class _PayLaterScreenState extends State<PayLaterScreen> {
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
          'Pay Later',
          style: AppTextStyles.heading.copyWith(
            color: textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddSheet(
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _service.getPayLaterEntries(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
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
              onButton: () => _showAddSheet(
                context,
                isDark,
                card,
                border,
                textPrimary,
                textMuted,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (unpaid.isNotEmpty) ...[
                Text(
                  'PENDING',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...unpaid.map(
                  (e) => _PayTile(
                    entry: e,
                    isDark: isDark,
                    fmt: _fmt,
                    onMark: () => _service.markPayLaterPaid(e.id),
                    onDelete: () => _service.deletePayLaterEntry(e.id),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (paid.isNotEmpty) ...[
                Text(
                  'PAID',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...paid.map(
                  (e) => _PayTile(
                    entry: e,
                    isDark: isDark,
                    fmt: _fmt,
                    onMark: () {},
                    onDelete: () => _service.deletePayLaterEntry(e.id),
                  ),
                ),
              ],
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
    final titleCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));

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
                'Add Pay Later',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
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
                hint: '',
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setSt(() => dueDate = picked);
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
                        'Due: ${DateFormat('d MMM yyyy').format(dueDate)}',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Save',
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
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
                  await _service.addPayLaterEntry(entry.toMap());
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

class _PayTile extends StatelessWidget {
  final PayLaterEntry entry;
  final bool isDark;
  final NumberFormat fmt;
  final VoidCallback onMark;
  final VoidCallback onDelete;

  const _PayTile({
    required this.entry,
    required this.isDark,
    required this.fmt,
    required this.onMark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final daysLeft = entry.dueDate.difference(DateTime.now()).inDays;

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: entry.isPaid
                ? AppColors.success.withValues(alpha: 0.30)
                : border,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: entry.isPaid ? null : onMark,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.isPaid
                      ? AppColors.success.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: entry.isPaid
                        ? AppColors.success
                        : AppColors.borderFor(isDark),
                    width: 1.5,
                  ),
                ),
                child: entry.isPaid
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 14,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
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
                    ),
                  ),
                  Text(
                    entry.isPaid
                        ? 'Paid'
                        : daysLeft == 0
                        ? 'Due today'
                        : daysLeft < 0
                        ? '${-daysLeft} days overdue'
                        : 'Due in $daysLeft days',
                    style: TextStyle(
                      color: entry.isPaid
                          ? AppColors.success
                          : daysLeft <= 0
                          ? AppColors.danger
                          : textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₹${fmt.format(entry.amount.toInt())}',
              style: TextStyle(
                color: entry.isPaid ? textMuted : AppColors.danger,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: entry.isPaid ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
