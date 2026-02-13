import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense.dart';

class FirestoreServices {
  static final FirestoreServices _instance = FirestoreServices._internal();

  factory FirestoreServices() {
    return _instance;
  }

  FirestoreServices._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String collectionPath = 'expenses';

  Stream<List<Expense>> getAllExpenses() {
    return _db
        .collection(collectionPath)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Expense.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  Stream<double> getTotalExpensesByMonth(DateTime month) {
    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 1);

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final lastDayStr = lastDay.toIso8601String();
    final firstDayStr = firstDay.toIso8601String();
    print(firstDayStr);
    print(lastDayStr);

    return _db
        .collection(collectionPath)
        .where('date', isGreaterThanOrEqualTo: firstDayStr)
        .where('date', isLessThanOrEqualTo: lastDayStr)
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            total += amount;
          }
          return total;
        });
  }

  // get total expenses overall
  Stream<double> getTotalExpenses() {
    return _db.collection(collectionPath).snapshots().map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        total += amount;
      }
      return total;
    });
  }

  Stream<List<Expense>> getExpensesByMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final lastDayStr = lastDay.toIso8601String();
    final firstDayStr = firstDay.toIso8601String();
    print(firstDayStr);
    print(lastDayStr);

    return _db
        .collection(collectionPath)
        .where('date', isGreaterThanOrEqualTo: firstDayStr)
        .where('date', isLessThanOrEqualTo: lastDayStr)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Expense.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList(),
        );
  }

  // add Expense
  Future<void> addExpense(Expense expense) async {
    await _db.collection(collectionPath).add(expense.toFirestore());
  }

  // update Expense
  Future<void> updateExpense(Expense expense) async {
    await _db
        .collection(collectionPath)
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  // delete Expense
  Future<void> deleteExpense(String id) async {
    await _db.collection(collectionPath).doc(id).delete();
  }
}
