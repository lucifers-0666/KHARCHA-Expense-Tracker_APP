class RecurringExpense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String frequency;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime? lastCreatedDate;
  final DateTime? lastReminderDate;

  RecurringExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    required this.frequency,
    required this.nextDueDate,
    required this.isActive,
    this.lastCreatedDate,
    this.lastReminderDate,
  });

  factory RecurringExpense.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic value, DateTime fallback) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value) ?? fallback;
      }
      return fallback;
    }

    DateTime? parseNullableDate(dynamic value) {
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return RecurringExpense(
      id: id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Other',
      date: parseDate(data['date'], DateTime.now()),
      frequency: data['frequency'] ?? 'monthly',
      nextDueDate: parseDate(data['nextDueDate'], DateTime.now()),
      isActive: data['isActive'] ?? true,
      lastCreatedDate: parseNullableDate(data['lastCreatedDate']),
      lastReminderDate: parseNullableDate(data['lastReminderDate']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'frequency': frequency,
      'nextDueDate': nextDueDate.toIso8601String(),
      'isActive': isActive,
      'lastCreatedDate': lastCreatedDate?.toIso8601String(),
      'lastReminderDate': lastReminderDate?.toIso8601String(),
    };
  }

  RecurringExpense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? frequency,
    DateTime? nextDueDate,
    bool? isActive,
    DateTime? lastCreatedDate,
    DateTime? lastReminderDate,
    bool clearLastCreatedDate = false,
    bool clearLastReminderDate = false,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      lastCreatedDate: clearLastCreatedDate
          ? null
          : (lastCreatedDate ?? this.lastCreatedDate),
      lastReminderDate: clearLastReminderDate
          ? null
          : (lastReminderDate ?? this.lastReminderDate),
    );
  }
}
