enum BadgeType {
  budgetHero,
  savingsStreak,
  expenseMaster,
  emiFinisher,
  goalAchiever,
  firstGoal,
  weeklyStreak,
  monthlyChallenge,
}

extension BadgeTypeExt on BadgeType {
  String get title {
    switch (this) {
      case BadgeType.budgetHero:       return 'Budget Hero';
      case BadgeType.savingsStreak:    return 'Savings Streak';
      case BadgeType.expenseMaster:    return 'Expense Master';
      case BadgeType.emiFinisher:      return 'EMI Finisher';
      case BadgeType.goalAchiever:     return 'Goal Achiever';
      case BadgeType.firstGoal:        return 'First Goal';
      case BadgeType.weeklyStreak:     return 'Weekly Streak';
      case BadgeType.monthlyChallenge: return 'Monthly Champion';
    }
  }

  String get description {
    switch (this) {
      case BadgeType.budgetHero:       return 'Stayed within budget for a full month';
      case BadgeType.savingsStreak:    return 'Saved money for 4 consecutive weeks';
      case BadgeType.expenseMaster:    return 'Tracked every expense for 30 days';
      case BadgeType.emiFinisher:      return 'Cleared an EMI ahead of schedule';
      case BadgeType.goalAchiever:     return 'Completed a savings goal';
      case BadgeType.firstGoal:        return 'Created your first savings goal';
      case BadgeType.weeklyStreak:     return 'Logged expenses 7 days in a row';
      case BadgeType.monthlyChallenge: return 'Won a monthly savings challenge';
    }
  }

  String get emoji {
    switch (this) {
      case BadgeType.budgetHero:       return '🏆';
      case BadgeType.savingsStreak:    return '🔥';
      case BadgeType.expenseMaster:    return '🎯';
      case BadgeType.emiFinisher:      return '✅';
      case BadgeType.goalAchiever:     return '⭐';
      case BadgeType.firstGoal:        return '🚀';
      case BadgeType.weeklyStreak:     return '📅';
      case BadgeType.monthlyChallenge: return '👑';
    }
  }
}

class Badge {
  final BadgeType type;
  final DateTime earnedAt;
  final bool isNew;

  Badge({required this.type, required this.earnedAt, this.isNew = false});

  Map<String, dynamic> toMap() => {
        'type': type.name,
        'earnedAt': earnedAt.toIso8601String(),
        'isNew': isNew,
      };

  factory Badge.fromMap(Map<String, dynamic> m) => Badge(
        type: BadgeType.values.firstWhere(
          (e) => e.name == m['type'],
          orElse: () => BadgeType.firstGoal,
        ),
        earnedAt: DateTime.parse(m['earnedAt']),
        isNew: m['isNew'] ?? false,
      );
}
