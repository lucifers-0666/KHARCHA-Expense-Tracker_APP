import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/models/income.dart';
import 'package:flutter_application_1/models/sms_suggestion.dart';

class LocalDatabaseHelper {
  static const _databaseName = 'kharcha_local.db';
  // Bumped to 2 so the sms_suggestions table is created on upgrade
  static const _databaseVersion = 2;

  static const tableExpenses    = 'expenses';
  static const tableIncome      = 'income';
  static const tableSyncQueue   = 'sync_queue';
  static const tableSmsSuggestions = 'sms_suggestions';

  LocalDatabaseHelper._();
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final basePath = await getDatabasesPath();
    final path = join(basePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableExpenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        receiptUrl TEXT,
        syncStatus TEXT DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableIncome (
        id TEXT PRIMARY KEY,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        syncStatus TEXT DEFAULT 'pending',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        "table" TEXT NOT NULL,
        recordId TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');

    await _createSmsSuggestionsTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSmsSuggestionsTable(db);
    }
  }

  Future<void> _createSmsSuggestionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableSmsSuggestions (
        id TEXT PRIMARY KEY,
        rawSms TEXT NOT NULL,
        parsedAmount REAL,
        parsedMerchant TEXT,
        parsedDate TEXT,
        confidence REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'newSuggestion',
        detectedAccount TEXT,
        sender TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // =========================================================
  // SMS SUGGESTION OPERATIONS
  // =========================================================

  Future<void> insertSmsSuggestion(SmsSuggestion suggestion) async {
    final db = await database;
    await db.insert(
      tableSmsSuggestions,
      suggestion.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<SmsSuggestion?> getSmsSuggestionById(String id) async {
    final db = await database;
    final rows = await db.query(
      tableSmsSuggestions,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SmsSuggestion.fromMap(rows.first);
  }

  Future<List<SmsSuggestion>> getSmsSuggestionsByStatus(
    SmsSuggestionStatus status,
  ) async {
    final db = await database;
    final rows = await db.query(
      tableSmsSuggestions,
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'createdAt DESC',
    );
    return rows.map(SmsSuggestion.fromMap).toList();
  }

  Future<void> updateSmsSuggestionStatus(
    String id,
    SmsSuggestionStatus status,
  ) async {
    final db = await database;
    await db.update(
      tableSmsSuggestions,
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================================================
  // EXPENSE OPERATIONS
  // =========================================================

  Future<String> insertExpense(Expense expense) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      tableExpenses,
      {
        'id': expense.id,
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'description': expense.description,
        'receiptUrl': expense.receiptUrl,
        'syncStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _addToSyncQueue('INSERT', tableExpenses, expense.id, expense.toFirestore());
    return expense.id;
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query(tableExpenses);
    return result
        .map((map) => Expense.fromFirestore(map, map['id'] as String))
        .toList();
  }

  Future<List<Expense>> getExpensesByMonth(DateTime month) async {
    final db = await database;
    final startDate = DateTime(month.year, month.month, 1).toIso8601String();
    final endDate   = DateTime(month.year, month.month + 1, 0).toIso8601String();

    final result = await db.query(
      tableExpenses,
      where: 'date BETWEEN ? AND ? AND syncStatus != ?',
      whereArgs: [startDate, endDate, 'deleting'],
    );
    return result
        .map((map) => Expense.fromFirestore(map, map['id'] as String))
        .toList();
  }

  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      tableExpenses,
      {
        'title': expense.title,
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date.toIso8601String(),
        'description': expense.description,
        'receiptUrl': expense.receiptUrl,
        'syncStatus': 'pending',
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    await _addToSyncQueue('UPDATE', tableExpenses, expense.id, expense.toFirestore());
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.update(
      tableExpenses,
      {'syncStatus': 'deleting', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _addToSyncQueue('DELETE', tableExpenses, id, {'id': id});
  }

  // =========================================================
  // INCOME OPERATIONS
  // =========================================================

  Future<String> insertIncome(Income income) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      tableIncome,
      {
        'id': income.id,
        'source': income.source,
        'amount': income.amount,
        'category': income.category,
        'date': income.date.toIso8601String(),
        'description': income.description,
        'syncStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _addToSyncQueue('INSERT', tableIncome, income.id, income.toFirestore());
    return income.id;
  }

  Future<List<Income>> getAllIncome() async {
    final db = await database;
    final result = await db.query(tableIncome);
    return result
        .map((map) => Income.fromFirestore(map, map['id'] as String))
        .toList();
  }

  Future<void> updateIncome(Income income) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      tableIncome,
      {
        'source': income.source,
        'amount': income.amount,
        'category': income.category,
        'date': income.date.toIso8601String(),
        'description': income.description,
        'syncStatus': 'pending',
        'updatedAt': now,
      },
      where: 'id = ?',
      whereArgs: [income.id],
    );
    await _addToSyncQueue('UPDATE', tableIncome, income.id, income.toFirestore());
  }

  Future<void> deleteIncome(String id) async {
    final db = await database;
    await db.update(
      tableIncome,
      {'syncStatus': 'deleting', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _addToSyncQueue('DELETE', tableIncome, id, {'id': id});
  }

  // =========================================================
  // SYNC QUEUE
  // =========================================================

  Future<void> _addToSyncQueue(
    String operation,
    String table,
    String recordId,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    final id = '${table}_${recordId}_${DateTime.now().millisecondsSinceEpoch}';
    await db.insert(tableSyncQueue, {
      'id': id,
      'operation': operation,
      'table': table,
      'recordId': recordId,
      'data': jsonEncode(data),
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query(tableSyncQueue, orderBy: 'timestamp ASC', limit: 50);
  }

  Future<void> markSyncItemAsComplete(String syncId) async {
    final db = await database;
    await db.delete(tableSyncQueue, where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> incrementRetryCount(String syncId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $tableSyncQueue SET retryCount = retryCount + 1 WHERE id = ?',
      [syncId],
    );
  }

  Future<void> markExpenseAsSynced(String expenseId) async {
    final db = await database;
    await db.update(
      tableExpenses,
      {'syncStatus': 'synced'},
      where: 'id = ?',
      whereArgs: [expenseId],
    );
  }

  Future<void> markIncomeAsSynced(String incomeId) async {
    final db = await database;
    await db.update(
      tableIncome,
      {'syncStatus': 'synced'},
      where: 'id = ?',
      whereArgs: [incomeId],
    );
  }

  Future<void> deleteLocalExpense(String expenseId) async {
    final db = await database;
    await db.delete(tableExpenses, where: 'id = ?', whereArgs: [expenseId]);
  }

  Future<void> deleteLocalIncome(String incomeId) async {
    final db = await database;
    await db.delete(tableIncome, where: 'id = ?', whereArgs: [incomeId]);
  }

  Future<bool> hasPendingSync() async {
    final db = await database;
    final result = await db.query(tableSyncQueue, limit: 1);
    return result.isNotEmpty;
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableSyncQueue',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(tableExpenses);
    await db.delete(tableIncome);
    await db.delete(tableSyncQueue);
    await db.delete(tableSmsSuggestions);
  }
}
