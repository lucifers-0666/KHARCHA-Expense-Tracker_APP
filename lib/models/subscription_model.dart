import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String name;
  final String category;
  final double monthlyAmount;
  final DateTime nextRenewal;
  final bool isActive;
  final String? iconEmoji;
  final bool autoDetected;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.category,
    required this.monthlyAmount,
    required this.nextRenewal,
    required this.isActive,
    this.iconEmoji,
    this.autoDetected = false,
  });

  int get daysUntilRenewal => nextRenewal.difference(DateTime.now()).inDays;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'monthlyAmount': monthlyAmount,
        'nextRenewal': Timestamp.fromDate(nextRenewal),
        'isActive': isActive,
        'iconEmoji': iconEmoji,
        'autoDetected': autoDetected,
      };

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SubscriptionModel(
      id: doc.id,
      name: d['name'] ?? '',
      category: d['category'] ?? 'Entertainment',
      monthlyAmount: (d['monthlyAmount'] as num).toDouble(),
      nextRenewal: (d['nextRenewal'] as Timestamp).toDate(),
      isActive: d['isActive'] ?? true,
      iconEmoji: d['iconEmoji'],
      autoDetected: d['autoDetected'] ?? false,
    );
  }
}
