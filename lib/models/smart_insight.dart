enum InsightType { anomaly, burnRate, savings, achievement, tip }
enum InsightSeverity { info, warning, danger }

class SmartInsight {
  final String id;
  final String title;
  final String message;
  final InsightType type;
  final InsightSeverity severity;
  final DateTime generatedAt;
  bool isDismissed;
  final String? category;
  final double? deltaAmount;
  final double? deltaPercent;

  SmartInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.generatedAt,
    this.isDismissed = false,
    this.category,
    this.deltaAmount,
    this.deltaPercent,
  });

  String get severityEmoji {
    switch (severity) {
      case InsightSeverity.danger: return '🔴';
      case InsightSeverity.warning: return '🟡';
      case InsightSeverity.info: return '🟢';
    }
  }
}
