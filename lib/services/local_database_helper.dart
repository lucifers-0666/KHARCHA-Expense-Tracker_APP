import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/models/income.dart';

class LocalDatabaseHelper {
  static const _databaseName = 'kharcha_local.db';
  static const _databaseVersion = 1;

  static const tableExpenses = 'expenses';
  static const tableIncome = 'income';
  static const tableSyncQueue = 'sync_queue';

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
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Expenses table
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

    // Income table
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

    // Sync queue table (tracks what needs to be synced)
    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        table TEXT NOT NULL,
        recordId TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0
      )
    ''');
  }

  // ===== EXPENSE OPERATIONS =====

  Future<String> insertExpense(Expense expense) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(tableExpenses, {
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
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Add to sync queue
    await _addToSyncQueue(
      'INSERT',
      tableExpenses,
      expense.id,
      expense.toFirestore(),
    );

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
    final endDate = DateTime(month.year, month.month + 1, 0).toIso8601String();

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

    await _addToSyncQueue(
      'UPDATE',
      tableExpenses,
      expense.id,
      expense.toFirestore(),
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;

    // Mark as deleting rather than permanently deleting
    await db.update(
      tableExpenses,
      {'syncStatus': 'deleting', 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );

    await _addToSyncQueue('DELETE', tableExpenses, id, {'id': id});
  }

  // ===== INCOME OPERATIONS =====

  Future<String> insertIncome(Income income) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    await db.insert(tableIncome, {
      'id': income.id,
      'source': income.source,
      'amount': income.amount,
      'category': income.category,
      'date': income.date.toIso8601String(),
      'description': income.description,
      'syncStatus': 'pending',
      'createdAt': now,
      'updatedAt': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await _addToSyncQueue(
      'INSERT',
      tableIncome,
      income.id,
      income.toFirestore(),
    );

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

    await _addToSyncQueue(
      'UPDATE',
      tableIncome,
      income.id,
      income.toFirestore(),
    );
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

  // ===== SYNC QUEUE OPERATIONS =====

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
      'data': data.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    final result = await db.query(
      tableSyncQueue,
      orderBy: 'timestamp ASC',
      limit: 50,
    );
    return result;
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

  // ===== SYNC STATUS =====

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
  }
}
