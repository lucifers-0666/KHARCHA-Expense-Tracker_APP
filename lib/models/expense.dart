class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;
  final String? description;
  final String? receiptUrl;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.description,
    this.receiptUrl,
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
      description: data['description'],
      receiptUrl: data['receiptUrl'],
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      if (description != null) 'description': description,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
    String? receiptUrl,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
    );
  }

  // Category icons mapping
  static const Map<String, String> categoryIcons = {
    'Food': '🍔',
    'Transport': '🚗',
    'Entertainment': '🎬',
    'Shopping': '🛍️',
    'Utilities': '💡',
    'Health': '🏥',
    'Education': '📚',
    'Other': '💰',
  };
}
