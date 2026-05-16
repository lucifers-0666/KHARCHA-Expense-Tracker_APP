import 'package:cloud_firestore/cloud_firestore.dart';

class Emi {
  final String id;
  final String loanName;
  final double totalAmount;
  final double emiAmount;
  final int totalMonths;
  final int paidMonths;
  final double interestRate;
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? notes;

  Emi({
    required this.id,
    required this.loanName,
    required this.totalAmount,
    required this.emiAmount,
    required this.totalMonths,
    required this.paidMonths,
    required this.interestRate,
    required this.startDate,
    required this.nextDueDate,
    this.notes,
  });

  int get remainingMonths => (totalMonths - paidMonths).clamp(0, totalMonths);
  double get paidAmount => emiAmount * paidMonths;
  double get remainingAmount => (totalAmount - paidAmount).clamp(0, totalAmount);
  double get progressPercent => totalMonths > 0 ? (paidMonths / totalMonths).clamp(0.0, 1.0) : 0.0;
  double get interestPaid => (paidAmount - (totalAmount / totalMonths * paidMonths)).clamp(0, double.infinity);
  bool get isDueSoon {
    final daysUntilDue = nextDueDate.difference(DateTime.now()).inDays;
    return daysUntilDue >= 0 && daysUntilDue <= 5;
  }
  bool get isOverdue => nextDueDate.isBefore(DateTime.now());

  factory Emi.fromFirestore(Map<String, dynamic> data, String id) {
    return Emi(
      id: id,
      loanName: data['loanName'] ?? '',
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      emiAmount: (data['emiAmount'] as num?)?.toDouble() ?? 0,
      totalMonths: (data['totalMonths'] as num?)?.toInt() ?? 0,
      paidMonths: (data['paidMonths'] as num?)?.toInt() ?? 0,
      interestRate: (data['interestRate'] as num?)?.toDouble() ?? 0,
      startDate: data['startDate'] != null ? DateTime.parse(data['startDate']) : DateTime.now(),
      nextDueDate: data['nextDueDate'] != null ? DateTime.parse(data['nextDueDate']) : DateTime.now(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'loanName': loanName,
    'totalAmount': totalAmount,
    'emiAmount': emiAmount,
    'totalMonths': totalMonths,
    'paidMonths': paidMonths,
    'interestRate': interestRate,
    'startDate': startDate.toIso8601String(),
    'nextDueDate': nextDueDate.toIso8601String(),
    if (notes != null) 'notes': notes,
  };

  Emi copyWith({
    int? paidMonths,
    DateTime? nextDueDate,
    String? notes,
  }) => Emi(
    id: id,
    loanName: loanName,
    totalAmount: totalAmount,
    emiAmount: emiAmount,
    totalMonths: totalMonths,
    paidMonths: paidMonths ?? this.paidMonths,
    interestRate: interestRate,
    startDate: startDate,
    nextDueDate: nextDueDate ?? this.nextDueDate,
    notes: notes ?? this.notes,
  );
}
