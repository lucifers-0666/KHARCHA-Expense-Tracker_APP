import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/expense.dart';
import '../services/firestore_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/primary_button.dart';

void showQuickAddSheet(BuildContext context, {VoidCallback? onAdded}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => QuickAddSheet(onAdded: onAdded),
  );
}

class QuickAddSheet extends StatefulWidget {
  final VoidCallback? onAdded;
  const QuickAddSheet({super.key, this.onAdded});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _service = FirestoreServices();
  final _amountCtrl = TextEditingController();
  final _descCtrl   = TextEditingController();
  String _category = 'Food';
  bool _loading = false;

  final List<String> _categories = [
    'Food', 'Transport', 'Shopping', 'Entertainment',
    'Bills', 'Health', 'Education', 'Other',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')));
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.addExpense(Expense(
        id: '',
        title: _descCtrl.text.isEmpty ? _category : _descCtrl.text,
        amount: amount,
        category: _category,
        date: DateTime.now(),
        description: _descCtrl.text,
      ));
      if (mounted) {
        Navigator.pop(context);
        widget.onAdded?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: AppRadius.sheetRadius,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding, 8, AppSpacing.pagePadding,
          AppSpacing.xl + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Quick Add Expense', style: AppTextStyles.headline),
          const SizedBox(height: AppSpacing.xl),

          // Amount
          _AmountInput(controller: _amountCtrl),
          const SizedBox(height: AppSpacing.xl),

          // Category
          Text('Category',
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8)),
          const SizedBox(height: AppSpacing.md),
          _CategoryGrid(
            categories: _categories,
            selected: _category,
            onSelect: (c) => setState(() => _category = c),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Description
          TextField(
            controller: _descCtrl,
            style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Description (optional)',
              hintStyle:
                  AppTextStyles.body.copyWith(color: AppColors.textDisabled),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputRadius,
                  borderSide:
                      const BorderSide(color: AppColors.accent, width: 1.5)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Actions
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: 'Cancel',
                  variant: ButtonVariant.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Add Expense',
                  isLoading: _loading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  final TextEditingController controller;
  const _AmountInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.inputRadius,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('₹',
              style: AppTextStyles.amount.copyWith(color: AppColors.accent)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              style: AppTextStyles.amount,
              textAlign: TextAlign.start,
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle:
                    AppTextStyles.amount.copyWith(color: AppColors.textDisabled),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols  = 4;
      final itemW = (constraints.maxWidth - (cols - 1) * 8) / cols;
      final itemH = itemW * 0.95;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: categories.map((cat) {
          final isSelected = cat == selected;
          final color = AppColors.categoryColor(cat);
          final icon  = AppColors.categoryIcon(cat);
          return GestureDetector(
            onTap: () => onSelect(cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: itemW,
              height: itemH,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.20)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 22,
                      color: isSelected ? color : AppColors.textMuted),
                  const SizedBox(height: 4),
                  Text(
                    cat,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected ? color : AppColors.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
