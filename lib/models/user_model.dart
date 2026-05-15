import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final String? profileImageUrl;
  final double totalMonthlyBudget;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.createdAt,
    this.profileImageUrl,
    this.totalMonthlyBudget = 0.0,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtRaw = data['createdAt'];

    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else {
      createdAt = DateTime.now();
    }

    return UserModel(
      uid: (data['uid'] as String?) ?? doc.id,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      createdAt: createdAt,
      profileImageUrl: data['profileImageUrl'] as String?,
      totalMonthlyBudget:
          (data['totalMonthlyBudget'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'profileImageUrl': profileImageUrl,
      'totalMonthlyBudget': totalMonthlyBudget,
    };
  }

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    DateTime? createdAt,
    String? profileImageUrl,
    double? totalMonthlyBudget,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      totalMonthlyBudget: totalMonthlyBudget ?? this.totalMonthlyBudget,
    );
  }
}
