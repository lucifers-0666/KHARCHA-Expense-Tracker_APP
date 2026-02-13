import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final double monthlyLimit;
  final Map<String, double> categoryLimits;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.monthlyLimit,
    required this.categoryLimits,
    required this.month,
    required this.year,
  });

  factory Budget.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Budget(
      id: doc.id,
      monthlyLimit: (data['monthlyLimit'] as num).toDouble(),
      categoryLimits: Map<String, double>.from(data['categoryLimits']),
      month: data['month'] as int,
      year: data['year'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthlyLimit': monthlyLimit,
      'categoryLimits': categoryLimits,
      'month': month,
      'year': year,
    };
  }

  Budget copyWith({
    String? id,
    double? monthlyLimit,
    Map<String, double>? categoryLimits,
    int? month,
    int? year,
  }) {
    return Budget(
      id: id ?? this.id,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      categoryLimits: categoryLimits ?? this.categoryLimits,
      month: month ?? this.month,
      year: year ?? this.year,
    );
  }
}