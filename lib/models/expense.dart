class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  factory Expense.fromFirestore(Map<String, dynamic> data, String Id) {
    return Expense(
      id: Id,
      title: data['title'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'other',
      date: data['date'] != null
          ? DateTime.parse(data['date'])
          : DateTime.now(),
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}
