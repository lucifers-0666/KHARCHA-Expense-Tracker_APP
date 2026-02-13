import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/models/income.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/services/local_database_helper.dart';

class OfflineSyncManager {
  final _firestoreService = FirestoreServices();
  final _localDb = LocalDatabaseHelper.instance;
  final _connectivity = Connectivity();

  bool _isOnline = true;
  bool _isSyncing = false;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  OfflineSyncManager() {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        syncPendingData();
      }
    });
  }

  /// Add expense (handles offline/online automatically)
  Future<void> addExpense(Expense expense) async {
    if (_isOnline) {
      try {
        await _firestoreService.addExpense(expense);
        // If Firebase succeeds, also save to local DB for offline reference
        await _localDb.insertExpense(expense);
      } catch (e) {
        // If Firebase fails, save to local DB with pending sync
        await _localDb.insertExpense(expense);
        rethrow;
      }
    } else {
      // Offline: save to local DB only
      await _localDb.insertExpense(expense);
    }
  }

  /// Update expense (handles offline/online automatically)
  Future<void> updateExpense(Expense expense) async {
    if (_isOnline) {
      try {
        await _firestoreService.updateExpense(expense);
        await _localDb.updateExpense(expense);
      } catch (e) {
        await _localDb.updateExpense(expense);
        rethrow;
      }
    } else {
      await _localDb.updateExpense(expense);
    }
  }

  /// Delete expense (handles offline/online automatically)
  Future<void> deleteExpense(String id) async {
    if (_isOnline) {
      try {
        await _firestoreService.deleteExpense(id);
        await _localDb.deleteExpense(id);
      } catch (e) {
        await _localDb.deleteExpense(id);
        rethrow;
      }
    } else {
      await _localDb.deleteExpense(id);
    }
  }

  /// Add income (handles offline/online automatically)
  Future<void> addIncome(Income income) async {
    if (_isOnline) {
      try {
        await _firestoreService.addIncome(income);
        await _localDb.insertIncome(income);
      } catch (e) {
        await _localDb.insertIncome(income);
        rethrow;
      }
    } else {
      await _localDb.insertIncome(income);
    }
  }

  /// Update income (handles offline/online automatically)
  Future<void> updateIncome(Income income) async {
    if (_isOnline) {
      try {
        await _firestoreService.updateIncome(income);
        await _localDb.updateIncome(income);
      } catch (e) {
        await _localDb.updateIncome(income);
        rethrow;
      }
    } else {
      await _localDb.updateIncome(income);
    }
  }

  /// Delete income (handles offline/online automatically)
  Future<void> deleteIncome(String id) async {
    if (_isOnline) {
      try {
        await _firestoreService.deleteIncome(id);
        await _localDb.deleteIncome(id);
      } catch (e) {
        await _localDb.deleteIncome(id);
        rethrow;
      }
    } else {
      await _localDb.deleteIncome(id);
    }
  }

  /// Get all expenses (from local DB, use for offline-first experience)
  Future<List<Expense>> getAllExpenses() async {
    return await _localDb.getAllExpenses();
  }

  /// Get expenses by month (from local DB)
  Future<List<Expense>> getExpensesByMonth(DateTime month) async {
    return await _localDb.getExpensesByMonth(month);
  }

  /// Get all income (from local DB)
  Future<List<Income>> getAllIncome() async {
    return await _localDb.getAllIncome();
  }

  /// Sync all pending operations with Firebase
  Future<void> syncPendingData() async {
    if (_isSyncing || !_isOnline) return;

    _isSyncing = true;

    try {
      final pendingItems = await _localDb.getPendingSyncItems();

      for (var item in pendingItems) {
        try {
          final operation = item['operation'] as String;
          final table = item['table'] as String;
          final recordId = item['recordId'] as String;
          final syncId = item['id'] as String;

          if (table == 'expenses') {
            await _syncExpense(operation, recordId);
          } else if (table == 'income') {
            await _syncIncome(operation, recordId);
          }

          // Mark as complete only if successful
          await _localDb.markSyncItemAsComplete(syncId);
        } catch (e) {
          // Increment retry count and continue with next item
          await _localDb.incrementRetryCount(item['id']);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncExpense(String operation, String expenseId) async {
    final localDb = LocalDatabaseHelper.instance;
    final expenses = await localDb.getAllExpenses();
    final expense = expenses.firstWhere((e) => e.id == expenseId);

    switch (operation) {
      case 'INSERT':
      case 'UPDATE':
        await _firestoreService.addExpense(expense);
        await localDb.markExpenseAsSynced(expenseId);
        break;
      case 'DELETE':
        await _firestoreService.deleteExpense(expenseId);
        await localDb.deleteLocalExpense(expenseId);
        break;
    }
  }

  Future<void> _syncIncome(String operation, String incomeId) async {
    final localDb = LocalDatabaseHelper.instance;
    final incomeList = await localDb.getAllIncome();
    final income = incomeList.firstWhere((i) => i.id == incomeId);

    switch (operation) {
      case 'INSERT':
      case 'UPDATE':
        await _firestoreService.addIncome(income);
        await localDb.markIncomeAsSynced(incomeId);
        break;
      case 'DELETE':
        await _firestoreService.deleteIncome(incomeId);
        await localDb.deleteLocalIncome(incomeId);
        break;
    }
  }

  /// Check if there are pending syncs
  Future<bool> hasPendingSync() async {
    return await _localDb.hasPendingSync();
  }

  /// Get count of pending syncs
  Future<int> getPendingSyncCount() async {
    return await _localDb.getPendingSyncCount();
  }
}
