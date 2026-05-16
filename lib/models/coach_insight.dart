enum InsightPriority { high, medium, low }
enum InsightCategory {
  spending, savings, emi, budget, subscription, goal, cashflow, weekly
}

class CoachInsight {
  final String id;
  final String message;
  final String? actionLabel;
  final InsightPriority priority;
  final InsightCategory category;
  final DateTime generatedAt;
  final String emoji;

  CoachInsight({
    required this.id,
    required this.message,
    required this.priority,
    required this.category,
    required this.emoji,
    this.actionLabel,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory CoachInsight.from({
    required String id,
    required String message,
    required InsightPriority priority,
    required InsightCategory category,
    required String emoji,
    String? actionLabel,
  }) =>
      CoachInsight(
        id: id,
        message: message,
        priority: priority,
        category: category,
        emoji: emoji,
        actionLabel: actionLabel,
      );
}
