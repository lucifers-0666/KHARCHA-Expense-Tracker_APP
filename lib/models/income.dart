class Income {
  final String id;
  final String source;
  final double amount;
  final String category;
  final DateTime date;
  final String description;

  Income({
    required this.id,
    required this.source,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
  });

  factory Income.fromFirestore(Map<String, dynamic> data, String id) {
    return Income(
      id: id,
      source: data['source'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? 'Other',
      date: data['date'] != null
          ? DateTime.parse(data['date'])
          : DateTime.now(),
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'source': source,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  Income copyWith({
    String? id,
    String? source,
    double? amount,
    String? category,
    DateTime? date,
    String? description,
  }) {
    return Income(
      id: id ?? this.id,
      source: source ?? this.source,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
    );
  }

  // Income categories
  static const List<String> categories = [
    'Salary',
    'Freelance',
    'Investment',
    'Gift',
    'Business',
    'Other',
  ];

  // Category icons
  static const Map<String, String> categoryIcons = {
    'Salary': '💼',
    'Freelance': '💻',
    'Investment': '📈',
    'Gift': '🎁',
    'Business': '🏢',
    'Other': '💰',
  };
}
