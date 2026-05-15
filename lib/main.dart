import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
import 'package:flutter_application_1/providers/theme_provider.dart';
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
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Kharcha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}

// ─── Legacy MainShell (kept for compat, not used) ────────────────────────────
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showAddExpense(context),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              child: const Icon(Icons.add_rounded, size: 24),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(isDark),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
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

// ─── Budget Progress Card ─────────────────────────────────────────────────────
class BudgetProgressCard extends StatefulWidget {
  const BudgetProgressCard({super.key});
  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard> {
  final _svc = FirestoreServices();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return StreamBuilder<Budget?>(
      stream: _svc.getBudgetForMonth(DateTime.now().year, DateTime.now().month),
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
            final spent = monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
            final limit = budget.monthlyLimit;
            final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;
            final remaining = limit - spent;
            final isOver = spent > limit;

            return Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              padding: const EdgeInsets.all(AppSpacing.cardPad),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Monthly Budget',
                        style: TextStyle(
                          color: textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOver
                              ? AppColors.dangerSoft
                              : AppColors.successSoft,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          isOver ? 'Over Budget' : 'On Track',
                          style: TextStyle(
                            color: isOver ? AppColors.danger : AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
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
                          color: isOver ? AppColors.danger : textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        ' / ₹${NumberFormat('#,##,###').format(limit.toInt())}',
                        style: TextStyle(color: textMuted, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: isDark ? AppColors.borderDark : AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver ? AppColors.danger : AppColors.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isOver
                        ? '₹${NumberFormat('#,##,###').format(remaining.abs().toInt())} over limit'
                        : '₹${NumberFormat('#,##,###').format(remaining.toInt())} remaining',
                    style: TextStyle(
                      color: isOver ? AppColors.danger : textMuted,
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

// ─── Recent Transactions Widget ───────────────────────────────────────────────
class RecentTransactionsWidget extends StatelessWidget {
  const RecentTransactionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final svc = FirestoreServices();
    return StreamBuilder<List<Expense>>(
      stream: svc.getAllExpenses(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Unable to load transactions. Please try again later.',
              style: TextStyle(
                color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        final expenses = snap.data ?? [];
        if (expenses.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(
                  color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }
        final recent = expenses.take(10).toList();
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          itemBuilder: (ctx, i) => _ExpenseTile(expense: recent[i], isDark: isDark),
        );
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final bool isDark;
  const _ExpenseTile({required this.expense, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final e = expense;
    final color = AppColors.categoryColor(e.category);
    final icon = AppColors.categoryIcon(e.category);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.description ?? e.title,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${e.category} · ${DateFormat('MMM d').format(e.date)}',
                  style: TextStyle(
                    color: isDark ? AppColors.textMutedDark : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-₹${NumberFormat('#,##,###.##').format(e.amount)}',
            style: const TextStyle(
              color: AppColors.danger,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Spending Chart ───────────────────────────────────────────────────────────
class SpendingChart extends StatefulWidget {
  const SpendingChart({super.key});
  @override
  State<SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<SpendingChart> {
  int _touchedIndex = -1;
  final _svc = FirestoreServices();

  // Muted premium chart colors (terracotta, slate-blue, olive, amber, rose, steel, stone)
  static const _chartColors = [
    Color(0xFFB85C5C),
    Color(0xFF5577AA),
    Color(0xFF7A8F6B),
    Color(0xFFC6923D),
    Color(0xFFAA6B8B),
    Color(0xFF4A7799),
    Color(0xFF8B8B8B),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;

    return StreamBuilder<Map<String, double>>(
      stream: _svc.getCategoryTotalsByMonth(DateTime.now()),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: borderColor),
            ),
            child: Center(
              child: Text(
                'No spending data this month',
                style: TextStyle(color: textMuted, fontSize: 14),
              ),
            ),
          );
        }
        final data = snap.data!;
        final total = data.values.fold<double>(0, (a, b) => a + b);
        final entries = data.entries.toList();

        return Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base, vertical: AppSpacing.sm,
          ),
          padding: const EdgeInsets.all(AppSpacing.base),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending by Category',
                style: TextStyle(
                  color: textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
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
                          final pct = total > 0 ? entries[i].value / total : 0.0;
                          return PieChartSectionData(
                            color: _chartColors[i % _chartColors.length],
                            value: entries[i].value,
                            title: isTouched
                                ? '${(pct * 100).toStringAsFixed(0)}%'
                                : '',
                            radius: isTouched ? 52 : 44,
                            titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        centerSpaceRadius: 32,
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
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _chartColors[i % _chartColors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  entries[i].key,
                                  style: TextStyle(color: textMuted, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${NumberFormat('#,##,###').format(entries[i].value.toInt())}',
                                style: TextStyle(
                                  color: textPrimary,
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

// ─── Auth helpers ─────────────────────────────────────────────────────────────
User? get currentUser => FirebaseAuth.instance.currentUser;
Stream<User?> get authStateStream => FirebaseAuth.instance.authStateChanges();
