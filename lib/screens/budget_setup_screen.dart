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

class _BudgetSetupScreenState extends State<BudgetSetupScreen>
    with SingleTickerProviderStateMixin {
  final _service = FirestoreServices();
  final _limitCtrl = TextEditingController();
  final Map<String, TextEditingController> _catCtrls = {};
  bool _loading = false;
  late AnimationController _animCtrl;

  static const _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
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
    _animCtrl.dispose();
    _limitCtrl.dispose();
    for (final c in _catCtrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final limit = double.tryParse(_limitCtrl.text.replaceAll(',', '')) ?? 0;
    if (limit <= 0) {
      _showSnack('Please enter a valid monthly limit', isError: true);
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
        _showSnack('Budget saved successfully ✓');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnack('Unable to save. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.bgFor(isDark);
    final textPrimary = AppColors.textPrimaryFor(isDark);
    final textMuted = AppColors.textMutedFor(isDark);
    final card = AppColors.surfaceFor(isDark);
    final border = AppColors.borderFor(isDark);

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
          'Budget Setup',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          GestureDetector(
            onTap: _loading ? null : _save,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 0.8),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: border.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: StreamBuilder<Budget?>(
        stream: _service.getBudgetForMonth(
          DateTime.now().year,
          DateTime.now().month,
        ),
        builder: (context, snapshot) {
          final budget = snapshot.data;
          return FadeTransition(
            opacity: _animCtrl,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Monthly limit hero card ──
                  _MonthlyLimitCard(
                    isDark: isDark,
                    card: card,
                    border: border,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    ctrl: _limitCtrl,
                    budget: budget,
                    service: _service,
                  ),
                  const SizedBox(height: 28),

                  // ── Section header ──
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CATEGORY LIMITS',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set optional spending caps per category',
                    style: TextStyle(
                        color: AppColors.textFaintFor(isDark), fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  // ── Category rows ──
                  ...List.generate(_categories.length, (i) {
                    final cat = _categories[i];
                    final catColor = AppColors.categoryColor(cat);
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration:
                          Duration(milliseconds: 350 + i * 55),
                      curve: Curves.easeOut,
                      builder: (_, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 16 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: card,
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Icon(
                                AppColors.categoryIcons[cat] ??
                                    Icons.category_rounded,
                                color: catColor,
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  TextField(
                                    controller: _catCtrls[cat],
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly,
                                    ],
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'No limit',
                                      hintStyle: TextStyle(
                                        color:
                                            AppColors.textFaintFor(isDark),
                                        fontSize: 13,
                                      ),
                                      prefixText: '₹ ',
                                      prefixStyle: TextStyle(
                                        color: catColor.withValues(
                                            alpha: 0.8),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                      ),
                    );
                  }),

                  const SizedBox(height: 32),

                  // ── Save button ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.md),
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
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Monthly limit card widget ──────────────────────────────────────────────
class _MonthlyLimitCard extends StatelessWidget {
  final bool isDark;
  final Color card, border, textPrimary, textMuted;
  final TextEditingController ctrl;
  final Budget? budget;
  final FirestoreServices service;

  const _MonthlyLimitCard({
    required this.isDark,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.ctrl,
    required this.budget,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'MONTHLY BUDGET LIMIT',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₹',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textFaintFor(isDark),
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          if (budget != null) ...[
            const SizedBox(height: 16),
            Container(
              height: 1,
              color: AppColors.primary.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 14),
            StreamBuilder<Map<String, double>>(
              stream: service.getCategoryTotalsByMonth(DateTime.now()),
              builder: (ctx, snap) {
                final spent =
                    snap.data?.values.fold(0.0, (a, b) => a + b) ?? 0.0;
                return BudgetProgressBar(
                  label: 'Budget Used',
                  spent: spent,
                  limit: budget!.monthlyLimit,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
