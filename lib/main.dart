import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/screens/SplaceScreen.dart';
import 'package:flutter_application_1/screens/add_expense.dart';
import 'package:flutter_application_1/screens/expense_card.dart';
import 'firebase_options.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ExpTrck());
}

class ExpTrck extends StatelessWidget {
  const ExpTrck({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: AppTheme.light(),
      home: const SplaceScreen(),
      routes: {'/home': (context) => const ExpenseTrackerHome()},
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
  final _service = FirestoreServices();

  void chgMonth(int o) {
    setState(() {
      month = DateTime(month.year, month.month + o, 1);
    });
  }

  void snank(String msg, [bool err = false]) =>
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
  void sheet([Expense? expense]) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (context) => AddExpenseScreen(
      onSave: () => snank(
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
              color: AppColors.danger.withOpacity(0.1),
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
              Navigator.pop(context);
              snank('Expense deleted successfully');
            } catch (e) {
              Navigator.pop(context);
              snank('Error deleting expense: $e', true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Expenses',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
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
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 100),
            if (monthView)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            chgMonth(-1);
                          });
                        },
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
                        onPressed: () {
                          setState(() {
                            chgMonth(1);
                          });
                        },
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
              child: StreamBuilder(
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
                        color: Colors.black.withOpacity(0.2),
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
                        '₹ ${(snapshot.data ?? 0).toStringAsFixed(2)}',
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
            Expanded(
              child: Container(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 80,
                              color: AppColors.danger.withOpacity(0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    final exp = snapshot.data ?? [];
                    if (exp.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                size: 80,
                                color: AppColors.primary.withOpacity(0.5),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button below to\nadd your first expense',
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
                      itemCount: exp.length,
                      itemBuilder: (context, index) => ExpenseCard(
                        expense: exp[index],
                        onEdit: () => sheet(exp[index]),
                        onDelete: () => delete(exp[index].id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => sheet(),
        backgroundColor: AppColors.accent,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, size: 28),
        label: const Text(
          'Add Expense',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
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
            color: Colors.black.withOpacity(0.05),
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
