import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cashflow_forecast.dart';
import '../models/coach_insight.dart';
import '../models/badge.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';
import '../models/savings_goal.dart';
import '../models/wallet.dart';
import '../models/subscription_model.dart';
import '../models/emi.dart';

class FirestoreServices {
  static final FirestoreServices _instance = FirestoreServices._internal();

  factory FirestoreServices() {
    return _instance;
  }

  FirestoreServices._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== COLLECTION PATHS ====================
  static const String collectionPath = 'expenses';
  static const String budgetCollectionPath = 'budgets';
  static const String recurringCollectionPath = 'recurring_expenses';
  static const String incomeCollectionPath = 'income';
  static const String savingsGoalsPath = 'savings_goals';
  static const String payLaterPath = 'pay_later';
  static const String walletPath = 'wallet';
  static const String subscriptionsPath = 'subscriptions';
  static const String emisPath = 'emis';
  static const String badgesPath = 'badges';

  // ==================== HELPERS ====================
  String _monthDocId(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  DateTime _endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  // ==================== EXPENSES ====================

  Stream<List<Expense>> getAllExpenses() {
    return _db
        .collection(collectionPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Expense>> getExpensesByMonth(DateTime month) {
    final firstDay = _startOfMonth(month).toIso8601String();
    final lastDay = _endOfMonth(month).toIso8601String();

    return _db
        .collection(collectionPath)
        .where('date', isGreaterThanOrEqualTo: firstDay)
        .where('date', isLessThanOrEqualTo: lastDay)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Expense>> getExpensesForDateRange(DateTime start, DateTime end) {
    final startDate = _dateOnly(start).toIso8601String();
    final endDate = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toIso8601String();

    return _db
        .collection(collectionPath)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<Expense>> fetchExpensesForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final startDate = _dateOnly(start).toIso8601String();
    final endDate = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    ).toIso8601String();

    final snapshot = await _db
        .collection(collectionPath)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Expense.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<double> getTotalExpensesByMonth(DateTime month) {
    return getExpensesByMonth(month).map((expenses) {
      return expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);
    });
  }

  Stream<Map<String, double>> getCategoryTotalsByMonth(DateTime month) {
    return getExpensesByMonth(month).map((expenses) {
      final totals = <String, double>{};
      for (final expense in expenses) {
        totals[expense.category] =
            (totals[expense.category] ?? 0) + expense.amount;
      }
      return totals;
    });
  }

  Stream<double> getTotalExpenses() {
    return _db.collection(collectionPath).snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    });
  }

  Future<void> addExpense(Expense expense) async {
    await _db.collection(collectionPath).add(expense.toFirestore());
  }

  Future<void> updateExpense(Expense expense) async {
    await _db
        .collection(collectionPath)
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  Future<void> deleteExpense(String id) async {
    await _db.collection(collectionPath).doc(id).delete();
  }

  // ==================== BUDGETS ====================

  Stream<Budget?> getBudgetForMonth(int year, int month) {
    final docId = _monthDocId(year, month);
    return _db.collection(budgetCollectionPath).doc(docId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return Budget.fromFirestore(doc);
    });
  }

  Future<Budget?> fetchBudgetForMonth(int year, int month) async {
    final docId = _monthDocId(year, month);
    final doc = await _db.collection(budgetCollectionPath).doc(docId).get();
    if (!doc.exists) return null;
    return Budget.fromFirestore(doc);
  }

  Future<void> saveBudget(Budget budget) async {
    final docId = _monthDocId(budget.year, budget.month);
    await _db
        .collection(budgetCollectionPath)
        .doc(docId)
        .set(budget.copyWith(id: docId).toFirestore(), SetOptions(merge: true));
  }

  // ==================== RECURRING EXPENSES ====================

  Stream<List<RecurringExpense>> getRecurringExpenses() {
    return _db
        .collection(recurringCollectionPath)
        .orderBy('nextDueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RecurringExpense.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<RecurringExpense>> getActiveRecurringExpenses() {
    return _db
        .collection(recurringCollectionPath)
        .where('isActive', isEqualTo: true)
        .orderBy('nextDueDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RecurringExpense.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addRecurringExpense(RecurringExpense recurringExpense) async {
    await _db
        .collection(recurringCollectionPath)
        .add(recurringExpense.toFirestore());
  }

  Future<void> updateRecurringExpense(RecurringExpense recurringExpense) async {
    await _db
        .collection(recurringCollectionPath)
        .doc(recurringExpense.id)
        .update(recurringExpense.toFirestore());
  }

  Future<void> deleteRecurringExpense(String id) async {
    await _db.collection(recurringCollectionPath).doc(id).delete();
  }

  Future<void> updateRecurringStatus(String id, bool isActive) async {
    await _db.collection(recurringCollectionPath).doc(id).update({
      'isActive': isActive,
    });
  }

  DateTime _nextDateByFrequency(DateTime source, String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return source.add(const Duration(days: 1));
      case 'weekly':
        return source.add(const Duration(days: 7));
      case 'yearly':
        return DateTime(source.year + 1, source.month, source.day);
      case 'monthly':
      default:
        final year = source.month == 12 ? source.year + 1 : source.year;
        final month = source.month == 12 ? 1 : source.month + 1;
        final day = source.day;
        final daysInTargetMonth = DateTime(year, month + 1, 0).day;
        return DateTime(
          year,
          month,
          day > daysInTargetMonth ? daysInTargetMonth : day,
        );
    }
  }

  Future<void> processDueRecurringExpenses({DateTime? now}) async {
    final runAt = _dateOnly(now ?? DateTime.now());

    final snapshot = await _db
        .collection(recurringCollectionPath)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      final recurring = RecurringExpense.fromFirestore(doc.data(), doc.id);
      var nextDue = _dateOnly(recurring.nextDueDate);
      DateTime? createdAt;

      while (!nextDue.isAfter(runAt)) {
        await addExpense(
          Expense(
            id: '',
            title: recurring.title,
            amount: recurring.amount,
            category: recurring.category,
            date: nextDue,
          ),
        );
        createdAt = nextDue;
        nextDue = _nextDateByFrequency(nextDue, recurring.frequency);
      }

      if (createdAt != null || nextDue != _dateOnly(recurring.nextDueDate)) {
        await _db.collection(recurringCollectionPath).doc(recurring.id).update({
          'nextDueDate': nextDue.toIso8601String(),
          'lastCreatedDate': createdAt?.toIso8601String(),
        });
      }
    }
  }

  Future<List<RecurringExpense>> getRecurringDueSoon({DateTime? now}) async {
    final runAt = _dateOnly(now ?? DateTime.now());

    final snapshot = await _db
        .collection(recurringCollectionPath)
        .where('isActive', isEqualTo: true)
        .get();

    final dueSoon = <RecurringExpense>[];
    for (final doc in snapshot.docs) {
      final recurring = RecurringExpense.fromFirestore(doc.data(), doc.id);
      final daysUntilDue = _dateOnly(
        recurring.nextDueDate,
      ).difference(runAt).inDays;
      final alreadyRemindedToday =
          recurring.lastReminderDate != null &&
          _dateOnly(recurring.lastReminderDate!).isAtSameMomentAs(runAt);

      if (daysUntilDue == 2 && !alreadyRemindedToday) {
        dueSoon.add(recurring);
      }
    }

    return dueSoon;
  }

  Future<void> markRecurringReminderSent(String id, DateTime sentDate) async {
    await _db.collection(recurringCollectionPath).doc(id).update({
      'lastReminderDate': sentDate.toIso8601String(),
    });
  }

  // ==================== INCOME ====================

  Stream<List<Income>> getAllIncome() {
    return _db
        .collection(incomeCollectionPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Income.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<Income>> getIncomeByMonth(DateTime month) {
    final start = _startOfMonth(month);
    final end = _endOfMonth(month);

    return _db
        .collection(incomeCollectionPath)
        .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
        .where('date', isLessThanOrEqualTo: end.toIso8601String())
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Income.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<double> getTotalIncomeByMonth(DateTime month) {
    return getIncomeByMonth(month).map((incomes) {
      if (incomes.isEmpty) return 0.0;
      return incomes.fold(0.0, (sum, income) => sum + income.amount);
    });
  }

  Stream<Map<String, double>> getIncomeCategoryTotalsByMonth(DateTime month) {
    return getIncomeByMonth(month).map((incomes) {
      final Map<String, double> categoryTotals = {};
      for (var income in incomes) {
        categoryTotals[income.category] =
            (categoryTotals[income.category] ?? 0) + income.amount;
      }
      return categoryTotals;
    });
  }

  Future<void> addIncome(Income income) async {
    await _db.collection(incomeCollectionPath).add(income.toFirestore());
  }

  Future<void> updateIncome(Income income) async {
    await _db
        .collection(incomeCollectionPath)
        .doc(income.id)
        .update(income.toFirestore());
  }

  Future<void> deleteIncome(String id) async {
    await _db.collection(incomeCollectionPath).doc(id).delete();
  }

  Stream<double> getNetCashFlow(DateTime month) {
    return getTotalIncomeByMonth(month).asyncMap((totalIncome) async {
      final totalExpense = await getTotalExpensesByMonth(month).first;
      return totalIncome - totalExpense;
    });
  }

  Stream<double> getSavingsRate(DateTime month) {
    return getTotalIncomeByMonth(month).asyncMap((totalIncome) async {
      if (totalIncome <= 0) return 0.0;
      final totalExpense = await getTotalExpensesByMonth(month).first;
      final savings = totalIncome - totalExpense;
      return (savings / totalIncome) * 100;
    });
  }

  // ==================== SAVINGS GOALS ====================

  Stream<List<SavingsGoal>> getSavingsGoals() {
    return _db
        .collection(savingsGoalsPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => SavingsGoal.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final ref = _db.collection(savingsGoalsPath).doc();
    await ref.set(goal.toFirestore());
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    await _db
        .collection(savingsGoalsPath)
        .doc(goal.id)
        .update(goal.toFirestore());
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _db.collection(savingsGoalsPath).doc(id).delete();
  }

  Future<void> addToSavingsGoal(String id, double amount) async {
    await _db.collection(savingsGoalsPath).doc(id).update({
      'savedAmount': FieldValue.increment(amount),
    });
  }

  // ==================== PAY LATER ====================

  Stream<List<Map<String, dynamic>>> getPayLaterEntries() {
    return _db
        .collection(payLaterPath)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
        );
  }

  Future<void> addPayLaterEntry(Map<String, dynamic> data) async {
    await _db.collection(payLaterPath).add(data);
  }

  Future<void> markPayLaterPaid(String id) async {
    await _db.collection(payLaterPath).doc(id).update({'isPaid': true});
  }

  Future<void> deletePayLaterEntry(String id) async {
    await _db.collection(payLaterPath).doc(id).delete();
  }

  Future<void> updatePayLaterEntry(String id, Map<String, dynamic> data) async {
    await _db.collection(payLaterPath).doc(id).update(data);
  }

  // ==================== WALLET ====================

  Stream<Wallet?> getWallet() {
    return _db.collection(walletPath).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return Wallet.fromFirestore(doc);
    });
  }

  Stream<List<Wallet>> getWallets() {
    return _db
        .collection(walletPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) => Wallet.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addWallet(Wallet wallet) async {
    final ref = _db.collection(walletPath).doc();
    await ref.set(wallet.toFirestore());
  }

  Future<void> deleteWallet(String id) async {
    await _db.collection(walletPath).doc(id).delete();
  }

  Future<void> saveWallet(Wallet wallet) async {
    if (wallet.id.isEmpty) {
      final ref = _db.collection(walletPath).doc();
      await ref.set(wallet.toFirestore());
    } else {
      await _db
          .collection(walletPath)
          .doc(wallet.id)
          .set(wallet.toFirestore(), SetOptions(merge: true));
    }
  }

  Future<void> updateWalletBalance(String id, double newBalance) async {
    await _db.collection(walletPath).doc(id).update({'balance': newBalance});
  }

  // ==================== SUBSCRIPTIONS ====================

  Stream<List<SubscriptionModel>> getSubscriptions() {
    return _db
        .collection(subscriptionsPath)
        .orderBy('nextRenewal')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => SubscriptionModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addSubscription(SubscriptionModel sub) async {
    final ref = _db.collection(subscriptionsPath).doc();
    await ref.set(sub.toFirestore());
  }

  Future<void> updateSubscription(SubscriptionModel sub) async {
    await _db
        .collection(subscriptionsPath)
        .doc(sub.id)
        .update(sub.toFirestore());
  }

  Future<void> deleteSubscription(String id) async {
    await _db.collection(subscriptionsPath).doc(id).delete();
  }

  Future<void> toggleSubscriptionActive(String id, bool isActive) async {
    await _db.collection(subscriptionsPath).doc(id).update({
      'isActive': isActive,
    });
  }

  // ==================== EMI / LOANS ====================

  Stream<List<Emi>> getEmis() {
    return _db
        .collection(emisPath)
        .orderBy('nextDueDate')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Emi.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addEmi(Emi emi) async {
    final ref = _db.collection(emisPath).doc();
    await ref.set(emi.toFirestore());
  }

  Future<void> updateEmi(Emi emi) async {
    await _db.collection(emisPath).doc(emi.id).update(emi.toFirestore());
  }

  Future<void> deleteEmi(String id) async {
    await _db.collection(emisPath).doc(id).delete();
  }

  Future<void> recordEmiPayment(String id) async {
    final doc = await _db.collection(emisPath).doc(id).get();
    if (!doc.exists) return;
    final emi = Emi.fromFirestore(doc.data()!, id);
    final newPaid = emi.paidMonths + 1;
    // Advance next due date by one month
    final next = DateTime(
      emi.nextDueDate.month == 12
          ? emi.nextDueDate.year + 1
          : emi.nextDueDate.year,
      emi.nextDueDate.month == 12 ? 1 : emi.nextDueDate.month + 1,
      emi.nextDueDate.day,
    );
    await _db.collection(emisPath).doc(id).update({
      'paidMonths': newPaid,
      'nextDueDate': next.toIso8601String(),
    });
  }

  // ==================== BADGES / ACHIEVEMENTS ====================

  Stream<List<Badge>> getBadges() {
    return _db
        .collection(badgesPath)
        .orderBy('earnedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => Badge.fromMap({...doc.data(), 'id': doc.id}))
              .toList(),
        );
  }

  Future<void> unlockBadge(String badgeId, Badge badge) async {
    await _db.collection(badgesPath).doc(badgeId).set(badge.toMap());
  }

  Future<bool> isBadgeUnlocked(String badgeId) async {
    final doc = await _db.collection(badgesPath).doc(badgeId).get();
    return doc.exists;
  }

  // ==================== CASHFLOW FORECAST ====================

  Stream<List<CashflowForecast>> getCashflowForecasts() async* {
    final now = DateTime.now();
    final currentBalance = await getWallet().first.then(
      (wallet) => wallet?.balance ?? 0.0,
    );
    final currentIncome = await getTotalIncomeByMonth(now).first;
    final currentExpense = await getTotalExpensesByMonth(now).first;
    final monthlyNet = currentIncome - currentExpense;

    final forecasts = <CashflowForecast>[];
    for (var i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      final projectedMonthEnd = currentBalance + (monthlyNet * (i + 1));
      final dailyStep = monthlyNet / 30.0;
      final days = <DailyForecast>[];
      var running = currentBalance + (monthlyNet * i);

      for (var d = 0; d < 30; d++) {
        final date = DateTime(month.year, month.month, d + 1);
        running += dailyStep;
        days.add(DailyForecast(date: date, projectedBalance: running));
      }

      final lowBalanceThreshold = 5000.0;
      DailyForecast? lowBalanceDay;
      for (final day in days) {
        if (day.projectedBalance < lowBalanceThreshold) {
          lowBalanceDay = day;
          break;
        }
      }

      final warnings = <String>[];
      if (monthlyNet < 0) {
        warnings.add('Spending is higher than income this month.');
      }
      if (projectedMonthEnd < 0) {
        warnings.add('Projected balance turns negative by month end.');
      }

      forecasts.add(
        CashflowForecast(
          days: days,
          currentBalance: currentBalance,
          projectedMonthEnd: projectedMonthEnd,
          lowBalanceDate: lowBalanceDay?.date,
          lowBalanceThreshold: lowBalanceThreshold,
          warnings: warnings,
        ),
      );
    }

    yield forecasts;
  }

  // ==================== AI COACH ====================

  Stream<List<CoachInsight>> getCoachInsights() async* {
    final now = DateTime.now();
    final income = await getTotalIncomeByMonth(now).first;
    final expense = await getTotalExpensesByMonth(now).first;
    final savings = income - expense;
    final savingsRate = income <= 0 ? 0.0 : (savings / income) * 100;

    final insights = <CoachInsight>[];

    if (income <= 0) {
      insights.add(
        CoachInsight.from(
          id: 'coach-income-setup',
          message:
              'Add your income sources so KHARCHA can calculate savings more accurately.',
          priority: InsightPriority.medium,
          category: InsightCategory.cashflow,
          emoji: '💡',
          actionLabel: 'Add income',
        ),
      );
    } else if (savingsRate < 10) {
      insights.add(
        CoachInsight.from(
          id: 'coach-savings-rate',
          message:
              'Your savings rate is below 10%. Try trimming one recurring expense.',
          priority: InsightPriority.high,
          category: InsightCategory.savings,
          emoji: '⚠️',
          actionLabel: 'Review expenses',
        ),
      );
    } else {
      insights.add(
        CoachInsight.from(
          id: 'coach-savings-win',
          message:
              'Nice work — you are keeping a healthy savings buffer this month.',
          priority: InsightPriority.low,
          category: InsightCategory.savings,
          emoji: '🎉',
          actionLabel: 'Keep it up',
        ),
      );
    }

    if (expense > income) {
      insights.add(
        CoachInsight.from(
          id: 'coach-overbudget',
          message:
              'Spending has crossed income. Consider pausing optional purchases.',
          priority: InsightPriority.high,
          category: InsightCategory.budget,
          emoji: '🧯',
          actionLabel: 'Tighten budget',
        ),
      );
    }

    yield insights;
  }
}
