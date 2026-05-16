import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/emi.dart';
import '../theme/app_theme.dart';

class EmiTrackerScreen extends StatefulWidget {
  const EmiTrackerScreen({super.key});
  @override
  State<EmiTrackerScreen> createState() => _EmiTrackerScreenState();
}

class _EmiTrackerScreenState extends State<EmiTrackerScreen> {
  final _col = FirebaseFirestore.instance.collection('emis');
  final _fmt = NumberFormat('#,##,###', 'en_IN');

  Stream<List<Emi>> _stream() => _col
      .orderBy('nextDueDate')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Emi.fromFirestore(d.data(), d.id)).toList(),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          'EMI Tracker',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddEmi(context),
            tooltip: 'Add EMI',
          ),
        ],
      ),
      body: StreamBuilder<List<Emi>>(
        stream: _stream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final emis = snap.data ?? [];
          if (emis.isEmpty) return _buildEmpty();

          final totalDebt = emis.fold<double>(
            0,
            (s, e) => s + e.remainingAmount,
          );
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(totalDebt, emis.length)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _EmiCard(emi: emis[i], onMarkPaid: _markPaid),
                    childCount: emis.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(double totalDebt, int count) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Remaining Debt',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_fmt.format(totalDebt)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count active loan${count == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 56,
            color: AppColors.textFaint,
          ),
          const SizedBox(height: 16),
          const Text(
            'No EMIs tracked',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first loan EMI',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => _showAddEmi(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add EMI'),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaid(Emi emi) async {
    if (emi.paidMonths >= emi.totalMonths) return;
    final nextDue = DateTime(
      emi.nextDueDate.year,
      emi.nextDueDate.month + 1,
      emi.nextDueDate.day,
    );
    await _col.doc(emi.id).update({
      'paidMonths': emi.paidMonths + 1,
      'nextDueDate': nextDue.toIso8601String(),
    });
  }

  void _showAddEmi(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEmiSheet(collection: _col),
    );
  }
}

class _EmiCard extends StatefulWidget {
  final Emi emi;
  final Future<void> Function(Emi) onMarkPaid;
  const _EmiCard({required this.emi, required this.onMarkPaid});
  @override
  State<_EmiCard> createState() => _EmiCardState();
}

class _EmiCardState extends State<_EmiCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;
  final _fmt = NumberFormat('#,##,###', 'en_IN');
  final _dateFmt = DateFormat('dd MMM');

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = Tween<double>(
      begin: 0,
      end: widget.emi.progressPercent,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emi = widget.emi;
    final statusColor = emi.isOverdue
        ? AppColors.danger
        : emi.isDueSoon
        ? AppColors.warning
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    emi.loanName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    emi.isOverdue
                        ? 'Overdue'
                        : emi.isDueSoon
                        ? 'Due Soon'
                        : 'Active',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _progress.value,
                        color: AppColors.primary,
                        bg: AppColors.surfaceOffset,
                      ),
                      child: Center(
                        child: Text(
                          '${(emi.progressPercent * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('EMI/month', '₹${_fmt.format(emi.emiAmount)}'),
                      const SizedBox(height: 4),
                      _kv('Remaining', '${emi.remainingMonths} months'),
                      const SizedBox(height: 4),
                      _kv('Next due', _dateFmt.format(emi.nextDueDate)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => widget.onMarkPaid(emi),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.accentSoft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Mark Paid',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => LinearProgressIndicator(
                  value: _progress.value,
                  backgroundColor: AppColors.surfaceOffset,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${_fmt.format(emi.paidAmount)} paid',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  '₹${_fmt.format(emi.remainingAmount)} left',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Row(
    children: [
      Text('$k  ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
      Text(
        v,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      ),
    ],
  );
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bg;
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = (size.shortestSide - 8) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    paint.color = bg;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.progress != progress;
}

class _AddEmiSheet extends StatefulWidget {
  final CollectionReference collection;
  const _AddEmiSheet({required this.collection});
  @override
  State<_AddEmiSheet> createState() => _AddEmiSheetState();
}

class _AddEmiSheetState extends State<_AddEmiSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _total = TextEditingController();
  final _emi = TextEditingController();
  final _months = TextEditingController();
  final _rate = TextEditingController();
  bool _saving = false;
  DateTime _nextDue = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    _emi.dispose();
    _months.dispose();
    _rate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add EMI / Loan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _field(_name, 'Loan Name (e.g. Home Loan)', required: true),
            _field(
              _total,
              'Total Loan Amount (₹)',
              keyboard: TextInputType.number,
            ),
            _field(_emi, 'Monthly EMI (₹)', keyboard: TextInputType.number),
            _field(_months, 'Total Months', keyboard: TextInputType.number),
            _field(
              _rate,
              'Interest Rate % (optional)',
              keyboard: TextInputType.number,
              required: false,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save EMI',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = true,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surfaceOffset,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border, width: 0.8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.border, width: 0.8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final emi = Emi(
        id: '',
        loanName: _name.text.trim(),
        totalAmount: double.tryParse(_total.text) ?? 0,
        emiAmount: double.tryParse(_emi.text) ?? 0,
        totalMonths: int.tryParse(_months.text) ?? 0,
        paidMonths: 0,
        interestRate: double.tryParse(_rate.text) ?? 0,
        startDate: DateTime.now(),
        nextDueDate: _nextDue,
      );
      await widget.collection.add(emi.toFirestore());
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
    }
  }
}
