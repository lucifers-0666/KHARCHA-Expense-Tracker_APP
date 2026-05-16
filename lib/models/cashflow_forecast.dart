class DailyForecast {
  final DateTime date;
  final double projectedBalance;
  final String? warning;

  DailyForecast({
    required this.date,
    required this.projectedBalance,
    this.warning,
  });
}

class CashflowForecast {
  final List<DailyForecast> days;
  final double currentBalance;
  final double projectedMonthEnd;
  final DateTime? lowBalanceDate;
  final double lowBalanceThreshold;
  final List<String> warnings;

  CashflowForecast({
    required this.days,
    required this.currentBalance,
    required this.projectedMonthEnd,
    this.lowBalanceDate,
    required this.lowBalanceThreshold,
    required this.warnings,
  });

  bool get hasLowBalanceRisk => lowBalanceDate != null;
}
