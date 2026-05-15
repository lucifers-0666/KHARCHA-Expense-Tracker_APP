import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';

class AddExpenseScreen extends StatefulWidget {
  final VoidCallback? onSave;
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.onSave, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Entertainment',
    'Health',
    'Bills',
    'Education',
    'Others',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _selectedCategory = e.category;
      _selectedDate = e.date;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final expense = Expense(
        id: widget.expenseToEdit?.id ?? '',
        title: _titleCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        category: _selectedCategory,
        date: _selectedDate,
        description: null,
      );
      if (widget.expenseToEdit == null) {
        await FirestoreServices().addExpense(expense);
      } else {
        await FirestoreServices().updateExpense(expense);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Expense added!'),
              ],
            ),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
        widget.onSave?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface2,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Amount',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IntrinsicWidth(
                            child: TextFormField(
                              controller: _amountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[\d.]'),
                                ),
                              ],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: AppColors.textFaint,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                ),
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Enter amount';
                                if (double.tryParse(v) == null)
                                  return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                TextFormField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(
                      Icons.title_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? 'Enter a title' : null,
                ),
                const SizedBox(height: 16),
                // Date
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textFaint,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Category
                const Text(
                  'Category',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    final color =
                        AppColors.categoryColors[cat] ?? AppColors.primary;
                    final icon =
                        AppColors.categoryIcons[cat] ?? Icons.category_rounded;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? color : AppColors.border,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              icon,
                              color: isSelected ? color : AppColors.textMuted,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? color : AppColors.textMuted,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),
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
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Expense',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
