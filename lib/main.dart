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
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
          home: const SplaceScreen(),
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
  late DateTime month = DateTime.now();
  bool monthView = false;
  bool _isSpeedDialOpen = false;
  final _service = FirestoreServices();
  final Set<String> _sentBudgetAlerts = <String>{};

  void chgMonth(int offset) {
    setState(() {
      month = DateTime(month.year, month.month + offset, 1);
    });
  }

  void snack(String msg, [bool err = false]) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                err ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: err ? AppColors.danger : AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );

  void _showBudgetAlertIfNeeded(double spent, double limit) {
    if (limit <= 0) return;

    final ratio = spent / limit;
    final keyBase = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    void sendThresholdAlert(double threshold, String message) {
      final key = '$keyBase-$threshold';
      if (ratio >= threshold && !_sentBudgetAlerts.contains(key)) {
        _sentBudgetAlerts.add(key);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          snack(message, threshold >= 1);
        });
      }
    }

    sendThresholdAlert(0.75, 'Budget crossed 75% for this month');
    sendThresholdAlert(0.90, 'Budget crossed 90% for this month');
    sendThresholdAlert(1.00, 'Budget limit reached/exceeded');
  }

  void sheet([Expense? expense]) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) => AddExpenseScreen(
      onSave: () => snack(
        expense == null
            ? 'Expense saved successfully'
            : 'Expense updated successfully',
      ),
      expenseToEdit: expense,
    ),
  );

  void delete(String id) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.danger,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Delete Expense'),
        ],
      ),
      content: const Text(
        'Are you sure you want to delete this expense? This action cannot be undone.',
        style: TextStyle(fontSize: 15),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await _service.deleteExpense(id);
              if (!mounted) return;
              Navigator.pop(context);
              snack('Expense deleted successfully');
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context);
              snack('Error deleting expense: $e', true);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  Color _budgetColor(double ratio) {
    if (ratio < 0.75) return AppColors.success;
    if (ratio < 0.90) return const Color(0xFFF1A24A);
    return AppColors.danger;
  }

  Widget _buildBudgetProgressCard() {
    return StreamBuilder<Budget?>(
      stream: _service.getBudgetForMonth(month.year, month.month),
      builder: (context, budgetSnapshot) {
        final budget = budgetSnapshot.data;

        return StreamBuilder<double>(
          stream: _service.getTotalExpensesByMonth(month),
          builder: (context, spentSnapshot) {
            final spent = spentSnapshot.data ?? 0.0;

            if (budgetSnapshot.connectionState == ConnectionState.waiting ||
                spentSnapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }

            if (budget == null || budget.monthlyLimit <= 0) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'No monthly budget set for this month.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetSetupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Set Budget',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            final ratio = spent / budget.monthlyLimit;
            final progress = ratio.isFinite
                ? ratio.clamp(0, 1).toDouble()
                : 0.0;
            final color = _budgetColor(ratio);
            _showBudgetAlertIfNeeded(spent, budget.monthlyLimit);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 80,
                    width: 80,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        Center(
                          child: Text(
                            '${(ratio * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budget Progress',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spent: Rs ${spent.toStringAsFixed(2)} / Rs ${budget.monthlyLimit.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIncomeVsExpenseCard() {
    return StreamBuilder<double>(
      stream: _service.getTotalIncomeByMonth(month),
      builder: (context, incomeSnapshot) {
        return StreamBuilder<double>(
          stream: _service.getTotalExpensesByMonth(month),
          builder: (context, expenseSnapshot) {
            if (incomeSnapshot.connectionState == ConnectionState.waiting ||
                expenseSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox.shrink();
            }

            final income = incomeSnapshot.data ?? 0.0;
            final expense = expenseSnapshot.data ?? 0.0;
            final netCashFlow = income - expense;
            final savingsRate = income > 0
                ? ((netCashFlow / income) * 100)
                : 0.0;

            // Hide if no income recorded
            if (income == 0) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: netCashFlow >= 0
                      ? [AppColors.success, const Color(0xFF4CAF50)]
                      : [AppColors.danger, const Color(0xFFE57373)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color:
                        (netCashFlow >= 0
                                ? AppColors.success
                                : AppColors.danger)
                            .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Cash Flow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncomeScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Manage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '+₹${NumberFormat('#,##,###').format(income)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Expenses',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '-₹${NumberFormat('#,##,###').format(expense)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Net',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${netCashFlow >= 0 ? '+' : ''}₹${NumberFormat('#,##,###').format(netCashFlow)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          savingsRate >= 20
                              ? Icons.trending_up
                              : savingsRate >= 0
                              ? Icons.trending_flat
                              : Icons.trending_down,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Savings Rate: ${savingsRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecurringSummary() {
    return StreamBuilder<List<RecurringExpense>>(
      stream: _service.getActiveRecurringExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final recurring = snapshot.data ?? [];
        if (recurring.isEmpty) {
          return const SizedBox.shrink();
        }

        final topItems = recurring.take(3).toList(growable: false);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Recurring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...topItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, size: 16, color: Colors.white70),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${item.title} (${item.frequency})',
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${item.nextDueDate.day}/${item.nextDueDate.month}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openMenuAction(String value) {
    switch (value) {
      case 'income':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IncomeScreen()),
        );
      case 'health':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FinancialHealthScreen()),
        );
      case 'groups':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GroupsScreen()),
        );
      case 'budget':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetSetupScreen()),
        );
      case 'analytics':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
        );
      case 'recurring':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecurringExpensesScreen()),
        );
      case 'export':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExportReportsScreen()),
        );
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'KHARCHA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchAndFilterScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.white, size: 28),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                monthView = !monthView;
              });
            },
            icon: Icon(
              monthView ? Icons.calendar_view_day : Icons.calendar_month,
              color: Colors.white,
              size: 28,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: _openMenuAction,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'income', child: Text('Income Tracker')),
              PopupMenuItem(value: 'health', child: Text('Financial Health')),
              PopupMenuItem(value: 'groups', child: Text('Split Expenses')),
              PopupMenuItem(value: 'budget', child: Text('Budget Setup')),
              PopupMenuItem(
                value: 'analytics',
                child: Text('Analytics Dashboard'),
              ),
              PopupMenuItem(
                value: 'recurring',
                child: Text('Recurring Expenses'),
              ),
              PopupMenuItem(value: 'export', child: Text('Export & Reports')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
          ),
        ),
        child: Column(
          children: [
            const OfflineStatusIndicator(),
            const SizedBox(height: 96),
            if (monthView)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => chgMonth(-1),
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Text(
                        '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][month.month - 1]} ${month.year}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => chgMonth(1),
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<double>(
                stream: monthView
                    ? _service.getTotalExpensesByMonth(month)
                    : _service.getTotalExpenses(),
                builder: (context, snapshot) => Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.primary],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        monthView ? 'Monthly Spending' : 'Total Spending',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Rs ${(snapshot.data ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _buildBudgetProgressCard(),
            _buildIncomeVsExpenseCard(),
            _buildRecurringSummary(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: StreamBuilder<List<Expense>>(
                  stream: monthView
                      ? _service.getExpensesByMonth(month)
                      : _service.getAllExpenses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (context, index) => _buildShimmerCard(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final expenses = snapshot.data ?? [];
                    if (expenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 80,
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap the + button below to add your first expense',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) => ExpenseCard(
                        expense: expenses[index],
                        onEdit: () => sheet(expenses[index]),
                        onDelete: () => delete(expenses[index].id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  Widget _buildSpeedDial() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        if (_isSpeedDialOpen) ...[
          GestureDetector(
            onTap: () => setState(() => _isSpeedDialOpen = false),
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
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
                _buildSpeedDialOption(
                  icon: Icons.flash_on,
                  label: 'Quick Add',
                  onTap: () async {
                    setState(() => _isSpeedDialOpen = false);
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => const QuickAddDialog(),
                    );
                    if (result == true) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 12),
                _buildSpeedDialOption(
                  icon: Icons.add_box,
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
          onPressed: () => setState(() => _isSpeedDialOpen = !_isSpeedDialOpen),
          backgroundColor: AppColors.accent,
          elevation: 8,
          child: AnimatedRotation(
            turns: _isSpeedDialOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isSpeedDialOpen ? Icons.close : Icons.add_rounded,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedDialOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          mini: true,
          onPressed: onTap,
          backgroundColor: AppColors.primary,
          child: Icon(icon, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 60,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
