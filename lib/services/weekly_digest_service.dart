import 'package:workmanager/workmanager.dart';
import '../models/expense.dart';
import '../services/firestore_services.dart';
import '../services/notification_service.dart';

const _kDigestTask = 'kharcha_weekly_digest';

/// Register weekly digest background task. Call from main.dart after Firebase init.
void registerWeeklyDigest() {
  Workmanager().registerPeriodicTask(
    _kDigestTask,
    _kDigestTask,
    frequency: const Duration(days: 7),
    initialDelay: _nextSundayDelay(),
    constraints: Constraints(networkType: NetworkType.not_required),
    existingWorkPolicy: ExistingWorkPolicy.replace,
  );
}

Duration _nextSundayDelay() {
  final now = DateTime.now();
  // Days until next Sunday (weekday 7)
  final daysUntilSunday = (7 - now.weekday) % 7;
  final nextSunday = DateTime(
    now.year, now.month,
    now.day + (daysUntilSunday == 0 ? 7 : daysUntilSunday),
    9, 0, // 9 AM
  );
  return nextSunday.difference(now);
}

/// Called by Workmanager dispatcher
Future<void> executeWeeklyDigest() async {
  try {
    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final expenses =
        await FirestoreServices().fetchExpensesForDateRange(weekStart, now);

    if (expenses.isEmpty) return;

    final digest = _buildDigest(expenses, now);
    await NotificationService().showNotification(
      id: 300,
      title: '📊 Your Weekly KHARCHA Digest',
      body: digest,
      payload: 'analytics',
    );
  } catch (_) {}
}

String _buildDigest(List<Expense> expenses, DateTime now) {
  if (expenses.isEmpty) return 'No expenses recorded this week.';

  final totalSpent = expenses.fold<double>(0, (s, e) => s + e.amount);

  // Top category
  final catTotals = <String, double>{};
  for (final e in expenses) {
    catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
  }
  final topCategory = catTotals.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

  // Biggest transaction
  final biggest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);

  return '• Top expense: $topCategory\n'
      '• Biggest: ${biggest.title} ₹${biggest.amount.toStringAsFixed(0)}\n'
      '• Total spent: ₹${totalSpent.toStringAsFixed(0)}';
}
