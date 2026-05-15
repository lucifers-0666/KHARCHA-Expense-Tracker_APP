import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/budget.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  final _service = FirestoreServices();
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  double _sliderValue = 10000;
  static const double _minBudget = 1000;
  static const double _maxBudget = 200000;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _onSliderChanged(double val) {
    setState(() {
      _sliderValue = val;
      _amountCtrl.text = val.toStringAsFixed(0);
    });
  }

  void _onTextChanged(String val) {
    final parsed = double.tryParse(val);
    if (parsed != null) {
      setState(() {
        _sliderValue = parsed.clamp(_minBudget, _maxBudget);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final budget = Budget(
        id: '',
        year: now.year,
        month: now.month,
        totalBudget: double.parse(_amountCtrl.text.trim()),
        categoryBudgets: {},
      );
      await _service.saveBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Budget saved!'),
              ],
            ),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
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
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Set Budget'),
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<double>(
        stream: _service.getTotalExpensesByMonth(now),
        builder: (ctx, expSnap) {
          final spent = expSnap.data ?? 0;
          return StreamBuilder<Budget?>(
            stream: _service.getBudgetForMonth(now.year, now.month),
            builder: (ctx2, budgetSnap) {
              final existing = budgetSnap.data;
              if (existing != null && _amountCtrl.text.isEmpty) {
                _amountCtrl.text = existing.totalBudget.toStringAsFixed(0);
                _sliderValue = existing.totalBudget.clamp(_minBudget, _maxBudget);
              }
              final budgetAmt = existing?.totalBudget ?? _sliderValue;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month label
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          '${months[now.month - 1]} ${now.year}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Budget progress if set
                      if (existing != null) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Current Budget',
                                      style: TextStyle(
                                          color: AppColors.textMuted, fontSize: 12)),
                                  const Spacer(),
                                  Text('₹${budgetAmt.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              const SizedBox(height: 14),
                              BudgetProgressBar(spent: spent, total: budgetAmt),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _statPill('Spent', '₹${spent.toStringAsFixed(0)}', AppColors.expense),
                                  const SizedBox(width: 10),
                                  _statPill(
                                    'Remaining',
                                    '₹${(budgetAmt - spent).clamp(0, budgetAmt).toStringAsFixed(0)}',
                                    AppColors.income,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Input
                      const Text('Monthly Budget',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800),
                        onChanged: _onTextChanged,
                        decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 16, right: 8),
                            child: Text('₹',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700)),
                          ),
                          prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintText: '10,000',
                          hintStyle: TextStyle(
                              color: AppColors.textFaint,
                              fontSize: 28,
                              fontWeight: FontWeight.w800),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a budget';
                          if (double.tryParse(v) == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      // Slider
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 4,
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.primary,
                          overlayColor: AppColors.primary.withOpacity(0.15),
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _sliderValue,
                          min: _minBudget,
                          max: _maxBudget,
                          divisions: 199,
                          onChanged: _onSliderChanged,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${_minBudget.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.textFaint, fontSize: 11)),
                            Text('₹${_maxBudget.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.textFaint, fontSize: 11)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Quick presets
                      const Text('Quick Presets',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [5000, 10000, 20000, 30000, 50000].map((amt) {
                          final isSelected = _sliderValue == amt.toDouble();
                          return GestureDetector(
                            onTap: () => _onSliderChanged(amt.toDouble()),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withOpacity(0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                    width: isSelected ? 1.5 : 1),
                              ),
                              child: Text('₹${(amt / 1000).toStringAsFixed(0)}K',
                                  style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
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
                              ? const SizedBox(width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Save Budget',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
