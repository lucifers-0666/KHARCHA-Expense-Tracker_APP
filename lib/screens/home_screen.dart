import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/burn_rate_card.dart';
import '../widgets/kharcha_widgets.dart';
import '../widgets/smart_insights_card.dart';
import 'add_expense.dart';
import 'analytics_dashboard_screen.dart';
import 'settings_screen.dart';
import 'income_screen.dart';
import 'search_filter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  final DateTime _selectedMonth = DateTime.now();
  final _firestoreService = FirestoreServices();

  late final List<Widget> _pages;
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardPage(month: _selectedMonth, service: _firestoreService),
      const AnalyticsDashboardScreen(),
      const IncomeScreen(),
      const SettingsScreen(),
    ];
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack);
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _navIndex) return;
    if (index == 0) {
      _fabCtrl.forward(from: 0);
    } else {
      _fabCtrl.reverse();
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bg;
    final navBg = isDark ? AppColors.surfaceDark : AppColors.surface;
    final navBdr = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _navIndex, children: _pages),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a1, a2) => const AddExpenseScreen(),
                transitionsBuilder: (_, a1, a2, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: a1,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 340),
              ),
            );
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          mini: false,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 26),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBdr, width: 0.8)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, -3),
                  ),
                ],
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: _onNavTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          animationDuration: const Duration(milliseconds: 300),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.trending_up_outlined),
              selectedIcon: Icon(Icons.trending_up_rounded),
              label: 'Income',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'morning';
  if (h < 17) return 'afternoon';
  return 'evening';
}

String _fmtDate(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return 'Today';
  }
  return DateFormat('d MMM').format(d);
}

class _DashboardPage extends StatelessWidget {
  final DateTime month;
  final FirestoreServices service;

  const _DashboardPage({required this.month, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bg;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textFaint = isDark ? AppColors.textFaintDark : AppColors.textFaint;
    final monthFmt = DateFormat('MMMM yyyy').format(month);
    final fmt = NumberFormat('#,##,###');

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            user?.displayName?.split(' ').first ?? 'there',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TappableIconButton(
                      icon: Icons.search_rounded,
                      color: textMuted,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchAndFilterScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: StreamBuilder<double>(
                  stream: service.getTotalExpensesByMonth(month),
                  builder: (ctx2, expSnap) {
                    return StreamBuilder<double>(
                      stream: service.getTotalIncomeByMonth(month),
                      builder: (ctx3, incSnap) {
                        final exp = expSnap.data ?? 0.0;
                        final inc = incSnap.data ?? 0.0;
                        final savings = inc - exp;

                        return _BalanceCard(
                          isDark: isDark,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          textMuted: textMuted,
                          textFaint: textFaint,
                          monthFmt: monthFmt,
                          savings: savings,
                          inc: inc,
                          exp: exp,
                          fmt: fmt,
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SmartInsightsCard()),
            SliverToBoxAdapter(
              child: StreamBuilder<List<dynamic>>(
                stream: StreamZip<dynamic>([
                  service.getExpensesByMonth(month),
                  service.getBudgetForMonth(month.year, month.month),
                ]),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final data = snapshot.data!;
                  final expenses = List.from(data[0]);
                  final budget = data[1];
                  if (budget == null) return const SizedBox.shrink();
                  return BurnRateCard(
                    expenses: expenses.cast(),
                    monthlyBudget: budget.monthlyLimit,
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: StreamBuilder<Map<String, double>>(
                  stream: service.getCategoryTotalsByMonth(month),
                  builder: (ctx, snap) {
                    final cats = snap.data ?? {};
                    final topCat = cats.isNotEmpty
                        ? cats.entries
                              .reduce((a, b) => a.value > b.value ? a : b)
                              .key
                        : 'None';
                    return Row(
                      children: [
                        Expanded(
                          child: KpiCard(
                            title: 'Top Category',
                            amount: topCat,
                            amountColor: AppColors.primary,
                            icon:
                                AppColors.categoryIcons[topCat] ??
                                Icons.category_rounded,
                            iconBg: isDark
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.accentSoft,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            title: 'Categories',
                            amount: cats.length.toString(),
                            amountColor: AppColors.warning,
                            icon: Icons.grid_view_rounded,
                            iconBg: isDark
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : AppColors.warningSoft,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                child: SectionHeader(
                  title: 'Recent Transactions',
                  action: 'See all',
                  onAction: () {},
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
              sliver: StreamBuilder(
                stream: service.getExpensesByMonth(month),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return SliverToBoxAdapter(
                      child: _ShimmerList(isDark: isDark),
                    );
                  }
                  if (snap.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load your data. Please try again.',
                          style: TextStyle(color: textMuted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  final expenses = snap.data ?? [];
                  if (expenses.isEmpty) {
                    return SliverToBoxAdapter(
                      child: EmptyStateWidget(
                        icon: Icons.receipt_long_rounded,
                        title: 'No transactions yet',
                        subtitle: 'Tap + to add your first expense',
                        buttonLabel: 'Add Expense',
                        onButton: () {},
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final e = expenses[i];
                      return _AnimatedTile(
                        index: i,
                        child: TransactionTile(
                          title: e.title,
                          category: e.category,
                          amount: e.amount.toStringAsFixed(0),
                          isExpense: true,
                          date: _fmtDate(e.date),
                          onDelete: () async {
                            await service.deleteExpense(e.id);
                          },
                        ),
                      );
                    }, childCount: expenses.length),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor, borderColor, textPrimary, textMuted, textFaint;
  final String monthFmt;
  final double savings, inc, exp;
  final NumberFormat fmt;

  const _BalanceCard({
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.monthFmt,
    required this.savings,
    required this.inc,
    required this.exp,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
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
          Row(
            children: [
              Text(
                monthFmt,
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: savings >= 0
                      ? AppColors.successSoft
                      : AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  savings >= 0 ? 'Surplus' : 'Deficit',
                  style: TextStyle(
                    color: savings >= 0 ? AppColors.success : AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Net Balance', style: TextStyle(color: textFaint, fontSize: 12)),
          const SizedBox(height: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: savings >= 0 ? AppColors.success : AppColors.danger,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              fontFamily: 'Inter',
            ),
            child: Text('₹${fmt.format(savings.abs().toInt())}'),
          ),
          const SizedBox(height: 18),
          Divider(
            color: isDark ? AppColors.borderDark : AppColors.border,
            height: 1,
            thickness: 0.8,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income',
                  value: '₹${fmt.format(inc.toInt())}',
                  color: AppColors.success,
                  icon: Icons.arrow_downward_rounded,
                  isDark: isDark,
                ),
              ),
              Container(
                width: 0.8,
                height: 36,
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
              Expanded(
                child: _MiniStat(
                  label: 'Expenses',
                  value: '₹${fmt.format(exp.toInt())}',
                  color: AppColors.danger,
                  icon: Icons.arrow_upward_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textFaint = AppColors.textFaintFor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textFaint, fontSize: 11)),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedTile extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedTile({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 360)),
      curve: Curves.easeOutCubic,
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 12), child: c),
      ),
      child: child,
    );
  }
}

class _ShimmerList extends StatelessWidget {
  final bool isDark;
  const _ShimmerList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ShimmerTile(isDark: isDark),
        ),
      ),
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  final bool isDark;
  const _ShimmerTile({required this.isDark});
  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceOffset;
    final shine = widget.isDark
        ? AppColors.surface2Dark
        : AppColors.bgSecondary;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: widget.isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: shine,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 11,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: shine,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 9,
                    width: 120,
                    decoration: BoxDecoration(
                      color: shine,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 11,
              width: 56,
              decoration: BoxDecoration(
                color: shine,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TappableIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TappableIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_TappableIconButton> createState() => _TappableIconButtonState();
}

class _TappableIconButtonState extends State<_TappableIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(widget.icon, color: widget.color, size: 20),
        ),
      ),
    );
  }
}
