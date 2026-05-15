import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'package:flutter_application_1/models/budget.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/screens/income_screen.dart';
import 'package:flutter_application_1/screens/SplaceScreen.dart';
import 'package:flutter_application_1/screens/settings_screen.dart';
import 'package:flutter_application_1/screens/add_expense.dart';
import 'package:flutter_application_1/screens/analytics_dashboard_screen.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bgPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const KharchaApp());
}

class KharchaApp extends StatelessWidget {
  const KharchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AnalyticsDashboardScreen(),
    const IncomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _showAddExpense(context),
              backgroundColor: AppColors.accent,
              icon: const Icon(Icons.add_rounded, color: Colors.black),
              label: const Text(
                'Add Expense',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        border: Border(
          top: BorderSide(
            color: AppColors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  void _showAddExpense(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseScreen(),
    );
  }
}

// ── Budget Progress Card ──────────────────────────────────────────────────────

class BudgetProgressCard extends StatefulWidget {
  const BudgetProgressCard({super.key});

  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard> {
  final _svc = FirestoreServices();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Budget?>(
      stream: _svc.getBudgetForMonth(
        DateTime.now().year,
        DateTime.now().month,
      ),
      builder: (ctx, budgetSnap) {
        final budget = budgetSnap.data;
        if (budget == null) return const SizedBox.shrink();

        return StreamBuilder<List<Expense>>(
          stream: _svc.getAllExpenses(),
          builder: (ctx, expSnap) {
            final expenses = expSnap.data ?? [];
            final now = DateTime.now();
            final monthExpenses = expenses.where(
              (e) => e.date.month == now.month && e.date.year == now.year,
            );
            final spent = monthExpenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );
            final limit = budget.monthlyLimit;
            final progress =
                limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
            final remaining = limit - spent;
            final isOver = spent > limit;

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Budget',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        isOver ? 'Over Budget' : 'On Track',
                        style: TextStyle(
                          color:
                              isOver ? AppColors.expense : AppColors.income,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${NumberFormat('#,##,###').format(spent.toInt())}',
                        style: TextStyle(
                          color: isOver
                              ? AppColors.expense
                              : AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' / ₹${NumberFormat('#,##,###').format(limit.toInt())}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceOffset,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? AppColors.expense : AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isOver
                        ? '₹${NumberFormat('#,##,###').format(remaining.abs().toInt())} over limit'
                        : '₹${NumberFormat('#,##,###').format(remaining.toInt())} remaining',
                    style: TextStyle(
                      color: isOver ? AppColors.expense : AppColors.textMuted,
                      fontSize: 12,
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
}

// ── Recent Transactions Widget ────────────────────────────────────────────────

class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirestoreServices();
    return StreamBuilder<List<Expense>>(
      stream: svc.getAllExpenses(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        final expenses = snap.data ?? [];
        if (expenses.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.x2l),
            child: Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }
        final recent = expenses.take(10).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          itemBuilder: (ctx, i) {
            final e = recent[i];
            return _ExpenseTile(expense: e);
          },
        );
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final color = _categoryColor(e.category);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: 3,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _categoryIcon(e.category),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.description ?? e.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${e.category} • ${DateFormat('MMM d').format(e.date)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-₹${NumberFormat('#,##,###.##').format(e.amount)}',
            style: const TextStyle(
              color: AppColors.expense,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String cat) {
    const map = {
      'food': Color(0xFFFF6B6B),
      'transport': Color(0xFF4ECDC4),
      'shopping': Color(0xFFFFE66D),
      'entertainment': Color(0xFFA8E6CF),
      'health': Color(0xFFFF8B94),
      'bills': Color(0xFFB4A7D6),
      'education': Color(0xFF88D8C0),
    };
    return map[cat.toLowerCase()] ?? AppColors.accent;
  }

  IconData _categoryIcon(String cat) {
    const map = {
      'food': Icons.restaurant_rounded,
      'transport': Icons.directions_car_rounded,
      'shopping': Icons.shopping_bag_rounded,
      'entertainment': Icons.movie_rounded,
      'health': Icons.favorite_rounded,
      'bills': Icons.receipt_rounded,
      'education': Icons.school_rounded,
    };
    return map[cat.toLowerCase()] ?? Icons.attach_money_rounded;
  }
}

// ── Spending Chart ────────────────────────────────────────────────────────────

class SpendingChart extends StatefulWidget {
  const SpendingChart({super.key});

  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int _touchedIndex = -1;
  final _svc = FirestoreServices();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: _svc.getCategoryTotalsByMonth(DateTime.now()),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(
            height: 200,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: const Center(
              child: Text(
                'No spending data this month',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }

        final data = snap.data!;
        final total = data.values.fold<double>(0, (a, b) => a + b);
        final colors = [
          const Color(0xFFFF6B6B),
          const Color(0xFF4ECDC4),
          const Color(0xFFFFE66D),
          const Color(0xFFA8E6CF),
          const Color(0xFFFF8B94),
          const Color(0xFFB4A7D6),
          const Color(0xFF88D8C0),
        ];
        final entries = data.entries.toList();

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Spending by Category',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (evt, resp) {
                            setState(() {
                              if (!evt.isInterestedForInteractions ||
                                  resp == null ||
                                  resp.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex =
                                  resp.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: List.generate(entries.length, (i) {
                          final isTouched = i == _touchedIndex;
                          final pct =
                              total > 0 ? entries[i].value / total : 0.0;
                          return PieChartSectionData(
                            color: colors[i % colors.length],
                            value: entries[i].value,
                            title: isTouched
                                ? '${(pct * 100).toStringAsFixed(1)}%'
                                : '',
                            radius: isTouched ? 58 : 50,
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        }),
                        centerSpaceRadius: 28,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        entries.length > 5 ? 5 : entries.length,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entries[i].key,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${NumberFormat('#,##,###').format(entries[i].value.toInt())}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Auth helpers (used by screens) ───────────────────────────────────────────

User? get currentUser => FirebaseAuth.instance.currentUser;
Stream<User?> get authStateStream => FirebaseAuth.instance.authStateChanges();
