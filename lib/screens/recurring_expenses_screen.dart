import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recurring_expense.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class RecurringExpensesScreen extends StatelessWidget {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreServices();
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Recurring'),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddSheet(context, service),
          ),
        ],
      ),
      body: StreamBuilder<List<RecurringExpense>>(
        stream: service.getRecurringExpenses(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primary),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.repeat_rounded,
              title: 'No recurring expenses',
              subtitle: 'Add subscriptions, rent, EMIs that repeat automatically',
              buttonLabel: '+ Add Recurring',
              onButton: () => _showAddSheet(context, service),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _RecurringCard(
              item: items[i],
              service: service,
              onEdit: () => _showAddSheet(context, service, item: items[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, service),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Recurring',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
    );
  }

  void _showAddSheet(BuildContext context, FirestoreServices service,
      {RecurringExpense? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecurringSheet(item: item, service: service),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  final RecurringExpense item;
  final FirestoreServices service;
  final VoidCallback onEdit;

  const _RecurringCard({required this.item, required this.service, required this.onEdit});

  String _dueBadge() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
    final diff = due.difference(today).inDays;
    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    return 'Due in ${diff}d';
  }

  Color _dueColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
    final diff = due.difference(today).inDays;
    if (diff <= 0) return AppColors.expense;
    if (diff <= 2) return AppColors.warning;
    return AppColors.textMuted;
  }

  String _freqLabel(String f) {
    switch (f.toLowerCase()) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'yearly': return 'Yearly';
      default: return 'Monthly';
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[item.category] ?? AppColors.primary;
    final catIcon = AppColors.categoryIcons[item.category] ?? Icons.repeat_rounded;
    final dueColor = _dueColor();

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(item.category,
                                style: TextStyle(
                                    color: catColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceOffset,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_freqLabel(item.frequency),
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('-₹${item.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Active toggle
                        GestureDetector(
                          onTap: () async {
                            await service.updateRecurringStatus(
                                item.id, !item.isActive);
                          },
                          child: Container(
                            width: 36,
                            height: 20,
                            decoration: BoxDecoration(
                              color: item.isActive
                                  ? AppColors.income.withOpacity(0.2)
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: item.isActive
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                width: 16,
                                height: 16,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: item.isActive
                                      ? AppColors.income
                                      : AppColors.textFaint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Due date row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: dueColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: dueColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, color: dueColor, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    'Next: ${item.nextDueDate.day}/${item.nextDueDate.month}/${item.nextDueDate.year}',
                    style: TextStyle(
                        color: dueColor, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(_dueBadge(),
                      style: TextStyle(
                          color: dueColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add/Edit Sheet ───────────────────────────────────────────────────────────
class _AddRecurringSheet extends StatefulWidget {
  final RecurringExpense? item;
  final FirestoreServices service;
  const _AddRecurringSheet({this.item, required this.service});

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Bills';
  String _frequency = 'monthly';
  DateTime _nextDue = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;

  final List<String> _categories = [
    'Bills', 'Food', 'Transport', 'Shopping', 'Health', 'Education', 'Others'
  ];
  final List<String> _frequencies = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _titleCtrl.text = widget.item!.title;
      _amountCtrl.text = widget.item!.amount.toString();
      _category = widget.item!.category;
      _frequency = widget.item!.frequency;
      _nextDue = widget.item!.nextDueDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final rec = RecurringExpense(
        id: widget.item?.id ?? '',
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        category: _category,
        frequency: _frequency,
        nextDueDate: _nextDue,
        isActive: widget.item?.isActive ?? true,
        lastCreatedDate: widget.item?.lastCreatedDate,
        lastReminderDate: widget.item?.lastReminderDate,
      );
      if (widget.item == null) {
        await widget.service.addRecurringExpense(rec);
      } else {
        await widget.service.updateRecurringExpense(rec);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.item == null ? 'Add Recurring' : 'Edit Recurring',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                validator: (v) => v!.isEmpty ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Netflix, Rent)',
                  prefixIcon: Icon(Icons.repeat_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              // Frequency selector
              const Text('Frequency',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Row(
                children: _frequencies.map((f) {
                  final isSelected = f == _frequency;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _frequency = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.15)
                              : AppColors.surfaceOffset,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1),
                        ),
                        child: Text(
                          f[0].toUpperCase() + f.substring(1),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Category chips
              const Text('Category',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat == _category;
                  final color = AppColors.categoryColors[cat] ?? AppColors.primary;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? color.withOpacity(0.15) : AppColors.surfaceOffset,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: isSelected ? color : AppColors.border,
                            width: isSelected ? 1.5 : 1),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              color: isSelected ? color : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(widget.item == null ? 'Save' : 'Update',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
