import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalType {
  emergencyFund,
  bike,
  car,
  vacation,
  laptop,
  homeDownPayment,
  custom,
}

extension GoalTypeExt on GoalType {
  String get label {
    switch (this) {
      case GoalType.emergencyFund: return 'Emergency Fund';
      case GoalType.bike:          return 'Bike';
      case GoalType.car:           return 'Car';
      case GoalType.vacation:      return 'Vacation';
      case GoalType.laptop:        return 'Laptop';
      case GoalType.homeDownPayment: return 'Home Down Payment';
      case GoalType.custom:        return 'Custom Goal';
    }
  }

  String get emoji {
    switch (this) {
      case GoalType.emergencyFund:   return '🛡️';
      case GoalType.bike:            return '🏍️';
      case GoalType.car:             return '🚗';
      case GoalType.vacation:        return '✈️';
      case GoalType.laptop:          return '💻';
      case GoalType.homeDownPayment: return '🏠';
      case GoalType.custom:          return '🎯';
    }
  }

  static GoalType fromString(String s) {
    return GoalType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => GoalType.custom,
    );
  }
}

class SavingsGoal {
  final String id;
  final String title;
  final GoalType type;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;
  final DateTime createdAt;
  final String? note;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.type,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
    required this.createdAt,
    this.note,
  });

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;

  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);

  int get daysLeft => targetDate.difference(DateTime.now()).inDays;

  double get requiredMonthlySavings {
    final months = (daysLeft / 30).ceil();
    if (months <= 0) return remaining;
    return remaining / months;
  }

  bool get isCompleted => savedAmount >= targetAmount;

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'type': type.name,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'targetDate': Timestamp.fromDate(targetDate),
        'createdAt': Timestamp.fromDate(createdAt),
        'note': note,
      };

  factory SavingsGoal.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SavingsGoal(
      id: doc.id,
      title: d['title'] ?? '',
      type: GoalTypeExt.fromString(d['type'] ?? 'custom'),
      targetAmount: (d['targetAmount'] as num).toDouble(),
      savedAmount: (d['savedAmount'] as num? ?? 0).toDouble(),
      targetDate: (d['targetDate'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      note: d['note'],
    );
  }

  SavingsGoal copyWith({double? savedAmount}) => SavingsGoal(
        id: id,
        title: title,
        type: type,
        targetAmount: targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        targetDate: targetDate,
        createdAt: createdAt,
        note: note,
      );
}
