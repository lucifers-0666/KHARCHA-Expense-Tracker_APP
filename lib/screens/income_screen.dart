import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/income.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';
import 'package:intl/intl.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  final _service = FirestoreServices();
  DateTime _selectedMonth = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset);
    });
  }

  String _monthLabel(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const Text('Income',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        )),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showAddIncomeDialog(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.income.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.income.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AppColors.income, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Month Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded,
                            color: AppColors.textMuted),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(
                        _monthLabel(_selectedMonth),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Summary card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: StreamBuilder<double>(
                  stream: _service.getTotalIncomeByMonth(_selectedMonth),
                  builder: (ctx, snap) {
                    final total = snap.data ?? 0;
                    return Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.income.withOpacity(0.25),
                            AppColors.income.withOpacity(0.05),
                          ],
                        ),
                        border: Border.all(
                            color: AppColors.income.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.income.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.trending_up_rounded,
                              color: AppColors.income,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Income',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                '₹${NumberFormat('#,##,###').format(total)}',
                                style: const TextStyle(
                                  color: AppColors.income,
                                  fontSize: 28,
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
            ),
            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: SectionHeader(
                  title: 'Income Sources',
                  action: '+ Add',
                  onAction: () => _showAddIncomeDialog(context),
                ),
              ),
            ),
            // List
            StreamBuilder<List<Income>>(
              stream: _service.getIncomeByMonth(_selectedMonth),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  );
                }
                final incomes = snap.data ?? [];
                if (incomes.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyStateWidget(
                      icon: Icons.savings_rounded,
                      title: 'No income recorded',
                      subtitle: 'Tap "+ Add" to record your income for this month',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _IncomeCard(
                        income: incomes[i],
                        service: _service,
                        onEdit: () => _showAddIncomeDialog(context, income: incomes[i]),
                      ),
                      childCount: incomes.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddIncomeDialog(BuildContext context, {Income? income}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddIncomeSheet(income: income, service: _service),
    );
  }
}

class _IncomeCard extends StatelessWidget {
  final Income income;
  final FirestoreServices service;
  final VoidCallback onEdit;

  const _IncomeCard({required this.income, required this.service, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[income.category] ?? AppColors.income;
    final icon = AppColors.categoryIcons[income.category] ?? Icons.savings_rounded;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(income.source,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(income.category,
                            style: TextStyle(
                                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${income.date.day}/${income.date.month}',
                        style: const TextStyle(
                            color: AppColors.textFaint, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('+₹${NumberFormat('#,##,###').format(income.amount)}',
                    style: const TextStyle(
                        color: AppColors.income,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () async {
                    await service.deleteIncome(income.id);
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.textFaint),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIncomeSheet extends StatefulWidget {
  final Income? income;
  final FirestoreServices service;
  const _AddIncomeSheet({this.income, required this.service});

  @override
  State<_AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<_AddIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _sourceCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _category = 'Salary';
  DateTime _date = DateTime.now();
  bool _loading = false;

  final List<String> _categories = ['Salary', 'Freelance', 'Investment', 'Business', 'Others'];

  @override
  void initState() {
    super.initState();
    if (widget.income != null) {
      _sourceCtrl.text = widget.income!.source;
      _amountCtrl.text = widget.income!.amount.toString();
      _descCtrl.text = widget.income!.description;
      _category = widget.income!.category;
      _date = widget.income!.date;
    }
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final income = Income(
        id: widget.income?.id ?? '',
        source: _sourceCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        category: _category,
        date: _date,
        description: _descCtrl.text.trim(),
      );
      if (widget.income == null) {
        await widget.service.addIncome(income);
      } else {
        await widget.service.updateIncome(income);
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
              widget.income == null ? 'Add Income' : 'Edit Income',
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
                labelText: 'Amount',
                prefixIcon: Icon(Icons.currency_rupee_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
              validator: (v) => v!.isEmpty ? 'Enter amount' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sourceCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Source',
                prefixIcon: Icon(Icons.business_center_rounded,
                    color: AppColors.textMuted, size: 20),
              ),
              validator: (v) => v!.isEmpty ? 'Enter source' : null,
            ),
            const SizedBox(height: 12),
            // Category chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = cat == _category;
                final color = AppColors.categoryColors[cat] ?? AppColors.income;
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.income,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.income == null ? 'Save Income' : 'Update Income',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
