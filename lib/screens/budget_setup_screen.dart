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
  final _ctrl = TextEditingController();
  bool _loading = false;
  DateTime _month = DateTime.now();

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];

  Future<void> _save() async {
    final val = double.tryParse(_ctrl.text.trim());
    if (val == null || val <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid budget amount'),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final budget = Budget(
        id: '',
        amount: val,
        year: _month.year,
        month: _month.month,
      );
      await _service.saveBudget(budget);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Budget saved!'),
            ]),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context);
      }
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month selector
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppColors.textMuted, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      '${_months[_month.month - 1]} ${_month.year}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() =>
                          _month = DateTime(_month.year, _month.month - 1)),
                      child: const Icon(Icons.chevron_left_rounded,
                          color: AppColors.textMuted),
                    ),
                    GestureDetector(
                      onTap: () {
                        final next =
                            DateTime(_month.year, _month.month + 1);
                        if (!next.isAfter(
                            DateTime(_month.year + 1, _month.month)))
                          setState(() => _month = next);
                      },
                      child: const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Budget amount
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text('Monthly Budget',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('\u20b9',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.w600)),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _ctrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 44,
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
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Current budget status
              StreamBuilder<Budget?>(
                stream: _service.getBudgetForMonth(
                    _month.year, _month.month),
                builder: (ctx, snap) {
                  if (!snap.hasData || snap.data == null) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.textMuted, size: 18),
                          SizedBox(width: 10),
                          Text('No budget set for this month',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }
                  final budget = snap.data!;
                  return StreamBuilder<double>(
                    stream: _service.getTotalExpensesByMonth(_month),
                    builder: (ctx2, expSnap) {
                      final spent = expSnap.data ?? 0;
                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Current Month Progress',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                )),
                            const SizedBox(height: 14),
                            BudgetProgressBar(
                                spent: spent,
                                total: budget.amount),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 32),
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
                      : const Text('Save Budget',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
