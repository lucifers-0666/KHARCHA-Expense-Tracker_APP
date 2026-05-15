import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  final _limitCtrl = TextEditingController();
  final Map<String, TextEditingController> _catCtrls = {};
  bool _loading = false;
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  static const _categories = [
    'Food', 'Transport', 'Shopping', 'Bills',
    'Entertainment', 'Health', 'Education', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    for (final c in _categories) {
      _catCtrls[c] = TextEditingController();
    }
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final now = DateTime.now();
    _service.getBudgetForMonth(now.year, now.month).first.then((b) {
      if (b != null && mounted) {
        setState(() {
          _limitCtrl.text = b.monthlyLimit.toStringAsFixed(0);
          for (final c in _categories) {
            final v = b.categoryLimits[c];
            if (v != null) _catCtrls[c]!.text = v.toStringAsFixed(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    for (final c in _catCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '')) ?? 0;
    if (limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid monthly limit')),
      );
      return;
    }
    setState(() => _loading = true);
    final catLimits = <String, double>{};
    for (final c in _categories) {
      final v = double.tryParse(_catCtrls[c]!.text.replaceAll(',', ''));
      if (v != null && v > 0) catLimits[c] = v;
    }
    final now = DateTime.now();
    final budget = Budget(
      id: '${now.year}-${now.month.toString().padLeft(2, '0')}',
      monthlyLimit: limit,
      categoryLimits: catLimits,
      month: now.month,
      year: now.year,
    );
    try {
      await _service.saveBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save budget. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bg;
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final cardColor = AppColors.surfaceFor(isDark);
    final borderColor = AppColors.borderFor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Budget Setup',
          style: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Budget?>(
        stream: _service.getBudgetForMonth(
          DateTime.now().year,
          DateTime.now().month,
        ),
        builder: (context, snapshot) {
          final budget = snapshot.data;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.pageHPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monthly limit card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark ? [] : [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY LIMIT',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _limitCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(color: AppColors.textFaintFor(isDark)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (budget != null) ...
                        [
                          const SizedBox(height: 14),
                          StreamBuilder<Map<String, double>>(
                            stream: _service.getCategoryTotalsByMonth(DateTime.now()),
                            builder: (ctx, snap) {
                              final spent = snap.data?.values.fold(0.0, (a, b) => a + b) ?? 0.0;
                              return BudgetProgressBar(
                                  label: 'Budget',
                                  spent: spent,
                                  limit: budget.monthlyLimit);
                            },
                          ),
                        ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'CATEGORY LIMITS',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_categories.length, (idx) {
                  final cat = _categories[idx];
                  final catColor = AppColors.categoryColor(cat);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            AppColors.categoryIcons[cat] ?? Icons.category_rounded,
                            color: catColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _catCtrls[cat],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(color: textPrimary, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'No limit',
                                  hintStyle: TextStyle(
                                    color: AppColors.textFaintFor(isDark),
                                    fontSize: 13,
                                  ),
                                  prefixText: '₹ ',
                                  prefixStyle: TextStyle(color: textMuted, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Budget',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
