import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/recurring_expense.dart';

class FirestoreServices {
  static final FirestoreServices _instance = FirestoreServices._internal();

  factory FirestoreServices() {
    return _instance;
  }

  FirestoreServices._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collectionPath = 'expenses';
  static const String budgetCollectionPath = 'budgets';
  static const String recurringCollectionPath = 'recurring_expenses';
  static const String incomeCollectionPath = 'income';

  String _monthDocId(int year, int month) =>
      '$year-${month.toString().padLeft(2, '0')}';

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  DateTime _endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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

  Stream<Budget?> getBudgetForMonth(int year, int month) {
    final docId = _monthDocId(year, month);
    return _db.collection(budgetCollectionPath).doc(docId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) {
        return null;
      }
      return Budget.fromFirestore(doc);
    });
  }

  Future<Budget?> fetchBudgetForMonth(int year, int month) async {
    final docId = _monthDocId(year, month);
    final doc = await _db.collection(budgetCollectionPath).doc(docId).get();
    if (!doc.exists) {
      return null;
    }
    return Budget.fromFirestore(doc);
  }

  Future<void> saveBudget(Budget budget) async {
    final docId = _monthDocId(budget.year, budget.month);
    await _db
        .collection(budgetCollectionPath)
        .doc(docId)
        .set(budget.copyWith(id: docId).toFirestore(), SetOptions(merge: true));
  }

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

  // ==================== INCOME METHODS ====================

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

  // Get net cash flow (income - expenses)
  Stream<double> getNetCashFlow(DateTime month) {
    return getTotalIncomeByMonth(month).asyncMap((totalIncome) async {
      final totalExpense = await getTotalExpensesByMonth(month).first;
      return totalIncome - totalExpense;
    });
  }

  // Get savings rate percentage
  Stream<double> getSavingsRate(DateTime month) {
    return getTotalIncomeByMonth(month).asyncMap((totalIncome) async {
      if (totalIncome <= 0) return 0.0;
      final totalExpense = await getTotalExpensesByMonth(month).first;
      final savings = totalIncome - totalExpense;
      return (savings / totalIncome) * 100;
    });
  }
}
