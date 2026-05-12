import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/firebase_options.dart';
import 'package:flutter_application_1/models/budget.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/models/recurring_expense.dart';
import 'package:flutter_application_1/screens/income_screen.dart';
import 'package:flutter_application_1/screens/SplaceScreen.dart';
import 'package:flutter_application_1/screens/add_expense.dart';
import 'package:flutter_application_1/screens/analytics_dashboard_screen.dart';
import 'package:flutter_application_1/screens/budget_setup_screen.dart';
import 'package:flutter_application_1/screens/expense_card.dart';
import 'package:flutter_application_1/screens/export_reports_screen.dart';
import 'package:flutter_application_1/screens/financial_health_screen.dart';
import 'package:flutter_application_1/screens/groups_screen.dart';
import 'package:flutter_application_1/screens/quick_add_dialog.dart';
import 'package:flutter_application_1/screens/recurring_expenses_screen.dart';
import 'package:flutter_application_1/widgets/offline_status_indicator.dart';
import 'package:flutter_application_1/screens/search_filter_screen.dart';
import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/services/notification_service.dart';
import 'package:flutter_application_1/services/recurring_background_service.dart';
import 'package:flutter_application_1/theme/app_colors.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await NotificationService.instance.initialize();
  await RecurringBackgroundService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const KharchaApp(),
    ),
  );
}

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'KHARCHA',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeProvider.themeMode,
          home: SplaceScreen(),
          routes: {'/home': (context) => const ExpenseTrackerHome()},
        );
      },
    );
  }
}

class ExpenseTrackerHome extends StatefulWidget {
  const ExpenseTrackerHome({super.key});

  @override
  State<ExpenseTrackerHome> createState() => _ExpenseTrackerHomeState();
}

class _ExpenseTrackerHomeState extends State<ExpenseTrackerHome> {
  int _currentTab = 0;
  late DateTime month = DateTime.now();
  bool monthView = false;
  bool _isSpeedDialOpen = false;
  final _service = FirestoreServices();
  final Set<String> _sentBudgetAlerts = <String>{};

  void chgMonth(int offset) => setState(() {
        month = DateTime(month.year, month.month + offset, 1);
      });

  void snack(String msg, [bool err = false]) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(err ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: err ? AppColors.danger : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

  void _showBudgetAlertIfNeeded(double spent, double limit) {
    if (limit <= 0) return;
    final ratio = spent / limit;
    final keyBase =
        '${month.year}-${month.month.toString().padLeft(2, '0')}';
    void alert(double threshold, String message) {
      final key = '$keyBase-$threshold';
      if (ratio >= threshold && !_sentBudgetAlerts.contains(key)) {
        _sentBudgetAlerts.add(key);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          snack(message, threshold >= 1);
        });
      }
    }
    alert(0.75, 'Budget crossed 75% for this month');
    alert(0.90, 'Budget crossed 90% for this month');
    alert(1.00, 'Budget limit reached/exceeded');
  }

  void sheet([Expense? expense]) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddExpenseScreen(
          onSave: () => snack(expense == null
              ? 'Expense saved successfully'
              : 'Expense updated successfully'),
          expenseToEdit: expense,
        ),
      );

  void delete(String id) => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Delete Expense'),
          ]),
          content: const Text(
              'Are you sure you want to delete this expense? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _service.deleteExpense(id);
                  if (!mounted) return;
                  Navigator.pop(context);
                  snack('Expense deleted');
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  snack('Error: $e', true);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

  Color _budgetColor(double ratio) {
    if (ratio < 0.75) return AppColors.success;
    if (ratio < 0.90) return const Color(0xFFF1A24A);
    return AppColors.danger;
  }

  // ── Screens for bottom nav ──────────────────────────────────
  Widget _homeTab() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryDark, AppColors.primary],
          stops: [0.0, 0.55],
        ),
      ),
      child: Column(
        children: [
          const OfflineStatusIndicator(),
          const SizedBox(height: 96),
          // ── Month Selector ─────────────────────────────────────
          if (monthView)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        onPressed: () => chgMonth(-1),
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white)),
                    Text(
                      DateFormat('MMMM yyyy').format(month),
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                    IconButton(
                        onPressed: () => chgMonth(1),
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          // ── Total Spending Card ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: StreamBuilder<double>(
              stream: monthView
                  ? _service.getTotalExpensesByMonth(month)
                  : _service.getTotalExpenses(),
              builder: (context, snapshot) => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.9),
                      AppColors.accentSoft.withValues(alpha: 0.6)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monthView ? 'Monthly Spending' : 'Total Spending',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(snapshot.data ?? 0)}',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading...'
                          : 'Tap + to add a new expense',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Budget Progress ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _buildBudgetProgressCard(),
          ),
          // ── Expense List ───────────────────────────────────────
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: StreamBuilder<List<Expense>>(
                stream: monthView
                    ? _service.getExpensesByMonth(month)
                    : _service.getAllExpenses(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                      itemCount: 6,
                      itemBuilder: (_, __) => _shimmerCard(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error: ${snapshot.error}',
                            style:
                                const TextStyle(color: AppColors.danger)),
                      ),
                    );
                  }
                  final expenses = snapshot.data ?? [];
                  if (expenses.isEmpty) return _emptyState();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          'Recent Expenses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary
                                .withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) => ExpenseCard(
                            expense: expenses[index],
                            onEdit: () => sheet(expenses[index]),
                            onDelete: () => delete(expenses[index].id),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetProgressCard() {
    return StreamBuilder<Budget?>(
      stream: _service.getBudgetForMonth(month.year, month.month),
      builder: (context, budgetSnap) {
        return StreamBuilder<double>(
          stream: _service.getTotalExpensesByMonth(month),
          builder: (context, spentSnap) {
            final budget = budgetSnap.data;
            final spent = spentSnap.data ?? 0.0;
            if (budget == null || budget.monthlyLimit <= 0) {
              return GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const BudgetSetupScreen())),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.savings_outlined,
                          color: Colors.white70, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('No budget set for this month',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('Set Budget',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              );
            }
            final ratio =
                (spent / budget.monthlyLimit).clamp(0.0, 1.0);
            final color = _budgetColor(ratio);
            _showBudgetAlertIfNeeded(spent, budget.monthlyLimit);
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly Budget',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '${(ratio * 100).toStringAsFixed(0)}%',
                        style:
                            TextStyle(color: color, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${NumberFormat('#,##,###').format(spent)} of ₹${NumberFormat('#,##,###').format(budget.monthlyLimit)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 64, color: AppColors.accent.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),
          const Text('No expenses yet',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to add\nyour first expense',
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(
                    width: 90,
                    height: 10,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
              width: 60,
              height: 16,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _homeTab(),
      const AnalyticsDashboardScreen(),
      const IncomeScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'KHARCHA',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => const SearchAndFilterScreen())),
            icon: const Icon(Icons.search_rounded,
                color: Colors.white, size: 26),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () => setState(() => monthView = !monthView),
            icon: Icon(
                monthView
                    ? Icons.calendar_view_day_rounded
                    : Icons.calendar_month_rounded,
                color: Colors.white,
                size: 26),
            tooltip: monthView ? 'All Time' : 'Month View',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: _openMenuAction,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            itemBuilder: (context) => const [
              PopupMenuItem(
                  value: 'health', child: Text('Financial Health')),
              PopupMenuItem(
                  value: 'groups', child: Text('Split Expenses')),
              PopupMenuItem(
                  value: 'budget', child: Text('Budget Setup')),
              PopupMenuItem(
                  value: 'recurring',
                  child: Text('Recurring Expenses')),
              PopupMenuItem(
                  value: 'export', child: Text('Export & Reports')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _currentTab, children: tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          border: Border(
              top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: (i) => setState(() => _currentTab = i),
          backgroundColor: AppColors.bgSecondary,
          indicatorColor: AppColors.accent.withValues(alpha: 0.18),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 65,
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
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
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
      floatingActionButton: _currentTab == 0 ? _buildSpeedDial() : null,
    );
  }

  void _openMenuAction(String value) {
    final routes = {
      'health': const FinancialHealthScreen(),
      'groups': const GroupsScreen(),
      'budget': const BudgetSetupScreen(),
      'recurring': const RecurringExpensesScreen(),
      'export': const ExportReportsScreen(),
    };
    final screen = routes[value];
    if (screen != null) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => screen));
    }
  }

  Widget _buildSpeedDial() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isSpeedDialOpen) ...[
          GestureDetector(
            onTap: () => setState(() => _isSpeedDialOpen = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Positioned(
            bottom: 80,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _speedDialOption(
                  icon: Icons.flash_on_rounded,
                  label: 'Quick Add',
                  onTap: () async {
                    setState(() => _isSpeedDialOpen = false);
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => QuickAddDialog(),
                    );
                    if (result == true) setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                _speedDialOption(
                  icon: Icons.add_box_rounded,
                  label: 'Detailed Add',
                  onTap: () {
                    setState(() => _isSpeedDialOpen = false);
                    sheet();
                  },
                ),
              ],
            ),
          ),
        ],
        FloatingActionButton(
          onPressed: () =>
              setState(() => _isSpeedDialOpen = !_isSpeedDialOpen),
          backgroundColor: AppColors.accent,
          elevation: 6,
          child: AnimatedRotation(
            turns: _isSpeedDialOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSpeedDialOpen
                  ? Icons.close_rounded
                  : Icons.add_rounded,
              size: 28,
              color: AppColors.bgPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _speedDialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 3))
            ],
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          mini: true,
          onPressed: onTap,
          backgroundColor: AppColors.primary,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}
