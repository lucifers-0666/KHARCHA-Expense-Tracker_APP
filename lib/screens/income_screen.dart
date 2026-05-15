import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _service = FirestoreServices();
  DateTime _month = DateTime.now();

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddIncomeSheet(service: _service),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('Income',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAddSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.income.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.income.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: AppColors.income, size: 16),
                          SizedBox(width: 4),
                          Text('Add',
                              style: TextStyle(
                                color: AppColors.income,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Month selector
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _monthBtn(Icons.chevron_left_rounded,
                      () => setState(() => _month =
                          DateTime(_month.year, _month.month - 1))),
                  const SizedBox(width: 12),
                  Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _monthBtn(Icons.chevron_right_rounded, () {
                    final next =
                        DateTime(_month.year, _month.month + 1);
                    if (!next.isAfter(DateTime.now()))
                      setState(() => _month = next);
                  }),
                ],
              ),
            ),
            // Summary card
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: StreamBuilder<double>(
                stream: _service.getTotalIncomeByMonth(_month),
                builder: (ctx, snap) {
                  final total = snap.data ?? 0;
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.income.withValues(alpha: 0.15),
                          AppColors.income.withValues(alpha: 0.04),
                        ],
                      ),
                      border: Border.all(
                          color: AppColors.income.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.income.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.income,
                              size: 22),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '\u20b9${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: AppColors.income,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SectionHeader(title: 'Income Records'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Income>>(
                stream: _service.getIncomeByMonth(_month),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary));
                  }
                  final incomes = snap.data ?? [];
                  if (incomes.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.savings_rounded,
                      title: 'No income recorded',
                      subtitle:
                          'Tap the Add button to record your income',
                    );
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: incomes.length,
                    itemBuilder: (ctx, i) {
                      final inc = incomes[i];
                      return TransactionTile(
                        title: inc.source,           // Income uses 'source'
                        category: inc.category,
                        amount: inc.amount.toStringAsFixed(0),
                        isExpense: false,
                        date: '${inc.date.day}/${inc.date.month}',
                        onDelete: () async {
                          await _service.deleteIncome(inc.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 18),
      ),
    );
  }
}

// ─── Add Income Bottom Sheet ─────────────────────────────────────────────────
class _AddIncomeSheet extends StatefulWidget {
  final FirestoreServices service;
  const _AddIncomeSheet({required this.service});

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sourceCtrl = TextEditingController();  // Income uses 'source'
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Salary';
  bool _loading = false;

  static const _categories = [
    'Salary', 'Freelance', 'Investment', 'Business', 'Gift', 'Other'
  ];

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final income = Income(
        id: '',
        source: _sourceCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        category: _selectedCategory,
        date: DateTime.now(),
        description: _descCtrl.text.trim(),
      );
      await widget.service.addIncome(income);
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
              const Text('Add Income',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[\d.]'))
                ],
                style:
                    const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(
                      Icons.currency_rupee_rounded,
                      color: AppColors.income,
                      size: 20),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter amount';
                  if (double.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _sourceCtrl,
                style:
                    const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Source (e.g. Employer name)',
                  prefixIcon: Icon(Icons.work_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Enter income source' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descCtrl,
                style:
                    const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.notes_rounded,
                      color: AppColors.textMuted, size: 20),
                ),
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
                  final isSelected = cat == _selectedCategory;
                  final color =
                      AppColors.categoryColors[cat] ?? AppColors.income;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.surfaceOffset,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : AppColors.border,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.income,
                    foregroundColor: Colors.black,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Income',
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
