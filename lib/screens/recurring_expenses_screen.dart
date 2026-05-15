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
            icon:
                const Icon(Icons.add_rounded, color: AppColors.primary),
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
                    strokeWidth: 2, color: AppColors.primary));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.repeat_rounded,
              title: 'No recurring expenses',
              subtitle:
                  'Add subscriptions, rent, EMIs to track automatically',
              buttonLabel: 'Add Recurring',
              onButton: () => _showAddSheet(context, service),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final r = items[i];
              final color =
                  AppColors.categoryColors[r.category] ??
                      AppColors.primary;
              final icon = AppColors.categoryIcon(r.category);
              final daysLeft = r.nextDueDate
                  .difference(DateTime.now())
                  .inDays;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.title,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _chip(r.frequency, AppColors.primary),
                              const SizedBox(width: 6),
                              _chip(
                                daysLeft <= 0
                                    ? 'Due today'
                                    : daysLeft == 1
                                        ? 'Due tomorrow'
                                        : 'Due in ${daysLeft}d',
                                daysLeft <= 2
                                    ? AppColors.warning
                                    : AppColors.textFaint,
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
                          '\u20b9${r.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.expense,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            await service.updateRecurringStatus(
                                r.id, !r.isActive);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: r.isActive
                                  ? AppColors.income.withOpacity(0.1)
                                  : AppColors.border,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              r.isActive ? 'Active' : 'Paused',
                              style: TextStyle(
                                color: r.isActive
                                    ? AppColors.income
                                    : AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          )),
    );
  }

  void _showAddSheet(
      BuildContext context, FirestoreServices service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddRecurringSheet(service: service),
    );
  }
}

// ─── Add Recurring Bottom Sheet ───────────────────────────────────────────────
class _AddRecurringSheet extends StatefulWidget {
  final FirestoreServices service;
  const _AddRecurringSheet({required this.service});

  @override
  State<_AddRecurringSheet> createState() => _AddRecurringSheetState();
}

class _AddRecurringSheetState extends State<_AddRecurringSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _frequency = 'monthly';
  String _category = 'Bills';
  bool _loading = false;

  static const _frequencies = ['daily', 'weekly', 'monthly', 'yearly'];
  static const _categories = [
    'Bills', 'Food', 'Transport', 'Entertainment', 'Health', 'Others'
  ];

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
      final now = DateTime.now();
      // RecurringExpense model requires 'date' field
      final expense = RecurringExpense(
        id: '',
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        category: _category,
        date: now,
        frequency: _frequency,
        nextDueDate: DateTime(now.year, now.month + 1, now.day),
        isActive: true,
      );
      await widget.service.addRecurringExpense(expense);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.expense),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Recurring Expense',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Netflix, Rent)',
                  prefixIcon: Icon(Icons.repeat_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\d.]'))
                ],
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Frequency',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: _frequencies.map((f) {
                  final isSelected = f == _frequency;
                  return GestureDetector(
                    onTap: () => setState(() => _frequency = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.15)
                            : AppColors.surfaceOffset,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        f[0].toUpperCase() + f.substring(1),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Category',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = cat == _category;
                  final color =
                      AppColors.categoryColors[cat] ?? AppColors.primary;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : AppColors.surfaceOffset,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? color : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Recurring',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
