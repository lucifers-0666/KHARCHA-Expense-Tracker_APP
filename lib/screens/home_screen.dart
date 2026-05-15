import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_services.dart';
import '../theme/app_theme.dart';
import '../widgets/kharcha_widgets.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final DateTime _selectedMonth = DateTime.now();
  final _firestoreService = FirestoreServices();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardPage(month: _selectedMonth, service: _firestoreService),
      const AnalyticsDashboardScreen(),
      const IncomeScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor  = isDark ? AppColors.bgDark : AppColors.bg;
    final navBg    = isDark ? AppColors.surfaceDark : AppColors.surface;
    final navBdr   = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(index: _navIndex, children: _pages),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              mini: false,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 26),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: navBdr)),
          boxShadow: isDark ? [] : [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _navIndex,
          onDestinationSelected: (i) => setState(() => _navIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
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

class _DashboardPage extends StatelessWidget {
  final DateTime month;
  final FirestoreServices service;

  const _DashboardPage({required this.month, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    final bgColor  = isDark ? AppColors.bgDark : AppColors.bg;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textFaint = isDark ? AppColors.textFaintDark : AppColors.textFaint;

    final monthFmt = DateFormat('MMMM yyyy').format(month);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
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
                          const SizedBox(height: 2),
                          Text(
                            user?.displayName?.split(' ').first ?? 'there',
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Search
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchAndFilterScreen(),
                        ),
                      ),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: borderColor),
                          boxShadow: isDark ? [] : [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: textMuted,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Main Balance Card ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: StreamBuilder<double>(
                  stream: service.getTotalExpensesByMonth(month),
                  builder: (ctx, expSnap) {
                    return StreamBuilder<double>(
                      stream: service.getTotalIncomeByMonth(month),
                      builder: (ctx2, incSnap) {
                        final exp = expSnap.data ?? 0;
                        final inc = incSnap.data ?? 0;
                        final savings = inc - exp;
                        final fmt = NumberFormat('#,##,###');

                        return Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(color: borderColor),
                            boxShadow: isDark ? [] : [
                              BoxShadow(
                                color: AppColors.shadowMd,
                                blurRadius: 16,
                                offset: const Offset(0, 4),
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
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: savings >= 0
                                          ? AppColors.successSoft
                                          : AppColors.dangerSoft,
                                      borderRadius: BorderRadius.circular(AppRadius.full),
                                    ),
                                    child: Text(
                                      savings >= 0 ? 'Surplus' : 'Deficit',
                                      style: TextStyle(
                                        color: savings >= 0
                                            ? AppColors.success
                                            : AppColors.danger,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Net Balance',
                                style: TextStyle(
                                  color: textFaint,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${fmt.format(savings.abs().toInt())}',
                                style: TextStyle(
                                  color: savings >= 0
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 1,
                                color: isDark ? AppColors.borderDark : AppColors.border,
                              ),
                              const SizedBox(height: 16),
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
                                    width: 1,
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
                      },
                    );
                  },
                ),
              ),
            ),

            // ── KPI Row ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                            icon: AppColors.categoryIcons[topCat] ??
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

            // ── Recent Transactions ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: SectionHeader(
                  title: 'Recent Transactions',
                  action: 'See all',
                  onAction: () {},
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
              sliver: StreamBuilder(
                stream: service.getExpensesByMonth(month),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load your data. Please try again later.',
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
                        subtitle: 'Add your first expense to get started',
                      ),
                    );
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final e = expenses[i];
                        return TransactionTile(
                          title: e.title,
                          category: e.category,
                          amount: e.amount.toStringAsFixed(0),
                          isExpense: true,
                          date: _fmtDate(e.date),
                          onDelete: () async {
                            await service.deleteExpense(e.id);
                          },
                        );
                      },
                      childCount: expenses.length > 20 ? 20 : expenses.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
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
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: textMuted, fontSize: 11)),
              const SizedBox(height: 1),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
