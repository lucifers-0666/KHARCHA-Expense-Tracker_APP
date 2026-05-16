import 'dart:async';
import '../models/expense.dart';
import '../models/smart_insight.dart';
import '../services/firestore_services.dart';
import 'anomaly_detector.dart';
import 'burn_rate_service.dart';

/// Central singleton that orchestrates all smart insight generation.
class SmartInsightsService {
  static final SmartInsightsService _instance =
      SmartInsightsService._internal();
  factory SmartInsightsService() => _instance;
  SmartInsightsService._internal();

  final _detector = AnomalyDetector();
  final _fs = FirestoreServices();

  final _insightsController =
      StreamController<List<SmartInsight>>.broadcast();
  Stream<List<SmartInsight>> get insightsStream => _insightsController.stream;

  List<SmartInsight> _current = [];
  StreamSubscription<List<Expense>>? _sub;

  void start() {
    _sub?.cancel();
    final now = DateTime.now();

    // Listen to current month expenses
    _sub = _fs.getExpensesByMonth(now).listen((currentExpenses) async {
      // Fetch 3 months of history
      final history = await _fetchThreeMonthHistory(now);

      final anomalies = _detector.detect(
        currentExpenses: currentExpenses,
        historicalExpenses: history,
        currentMonth: now,
      );

      final burnInsight = BurnRateService().getInsight(
        expenses: currentExpenses,
        now: now,
      );

      final all = [
        ...anomalies,
        if (burnInsight != null) burnInsight,
      ];

      // Preserve dismissed state
      for (final insight in all) {
        final prev = _current.firstWhere(
          (c) => c.id == insight.id,
          orElse: () => insight,
        );
        insight.isDismissed = prev.isDismissed;
      }

      _current = all;
      _insightsController.add(List.unmodifiable(_current));
    });
  }

  void dismiss(String id) {
    for (final i in _current) {
      if (i.id == id) i.isDismissed = true;
    }
    _insightsController.add(List.unmodifiable(_current));
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<List<Expense>> _fetchThreeMonthHistory(DateTime now) async {
    final all = <Expense>[];
    for (int i = 1; i <= 3; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      try {
        final expenses = await _fs.fetchExpensesForDateRange(start, end);
        all.addAll(expenses);
      } catch (_) {}
    }
    return all;
  }
}
