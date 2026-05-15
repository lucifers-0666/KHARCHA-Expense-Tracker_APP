import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  DateTime _selectedMonth = DateTime.now();
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _navIndex, children: _pages),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Expense',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              elevation: 0,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.12),
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
    );
  }
}

class _DashboardPage extends StatelessWidget {
  final DateTime month;
  final FirestoreServices service;

  const _DashboardPage({required this.month, required this.service});

  String _monthLabel(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good ${_greeting()},',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.displayName?.split(' ').first ?? 'there',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SearchFilterScreen()),
                    ),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(Icons.search_rounded,
                          color: AppColors.textMuted, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                      return Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDark.withOpacity(0.8),
                              const Color(0xFF0D1A1F),
                            ],
                          ),
                          border: Border.all(
                              color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _monthLabel(month),
                              style: TextStyle(
                                color:
                                    AppColors.primary.withOpacity(0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Net Balance',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${savings.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                color: savings >= 0
                                    ? AppColors.income
                                    : AppColors.expense,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _miniStat('Income', '₹${inc.toStringAsFixed(0)}',
                                    AppColors.income),
                                const SizedBox(width: 24),
                                _miniStat('Spent', '₹${exp.toStringAsFixed(0)}',
                                    AppColors.expense),
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
          // KPI Row
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
                          icon: AppColors.categoryIcons[topCat] ?? Icons.category_rounded,
                          iconBg: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: KpiCard(
                          title: 'Categories',
                          amount: cats.length.toString(),
                          amountColor: AppColors.warning,
                          icon: Icons.grid_view_rounded,
                          iconBg: AppColors.warning.withOpacity(0.1),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Recent Transactions
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
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  );
                }
                final expenses = snap.data ?? [];
                if (expenses.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyStateWidget(
                      icon: Icons.receipt_long_rounded,
                      title: 'No transactions yet',
                      subtitle:
                          'Tap the button below to add your first expense',
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
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ],
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
    return '${d.day}/${d.month}';
  }
}
