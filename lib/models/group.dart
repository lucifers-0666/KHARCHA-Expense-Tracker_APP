import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final List<GroupMember> members;
  final String createdBy;
  final DateTime createdAt;
  final String? imageUrl;

  Group({
    required this.id,
    required this.name,
    required this.description,
    required this.members,
    required this.createdBy,
    required this.createdAt,
    this.imageUrl,
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      members:
          (data['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'members': members.map((m) => m.toMap()).toList(),
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
    };
  }

  static const List<String> groupIcons = [
    '🏠', // Home/Family
    '✈️', // Travel
    '🍽️', // Food
    '🎉', // Party
    '🏢', // Office
    '👥', // Friends
    '🎓', // Study
    '💼', // Work
  ];
}

class GroupMember {
  final String userId;
  final String name;
  final String email;
  final bool isAdmin;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.name,
    required this.email,
    this.isAdmin = false,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

enum SplitType { equal, custom, percentage }

class SplitExpense {
  final String id;
  final String groupId;
  final String title;
  final double totalAmount;
  final String paidBy;
  final DateTime date;
  final String category;
  final String? description;
  final SplitType splitType;
  final Map<String, double> splits; // userId -> amount
  final Map<String, bool> settledBy; // userId -> settled status
  final bool isSettled;

  SplitExpense({
    required this.id,
    required this.groupId,
    required this.title,
    required this.totalAmount,
    required this.paidBy,
    required this.date,
    required this.category,
    this.description,
    required this.splitType,
    required this.splits,
    required this.settledBy,
    this.isSettled = false,
  });

  factory SplitExpense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SplitExpense(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      title: data['title'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paidBy: data['paidBy'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      description: data['description'],
      splitType: SplitType.values.firstWhere(
        (e) => e.name == data['splitType'],
        orElse: () => SplitType.equal,
      ),
      splits: Map<String, double>.from(
        (data['splits'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      ),
      settledBy: Map<String, bool>.from(data['settledBy'] ?? {}),
      isSettled: data['isSettled'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'title': title,
      'totalAmount': totalAmount,
      'paidBy': paidBy,
      'date': Timestamp.fromDate(date),
      'category': category,
      'description': description,
      'splitType': splitType.name,
      'splits': splits,
      'settledBy': settledBy,
      'isSettled': isSettled,
    };
  }

  // Calculate simplified debts across the group
  static Map<String, Map<String, double>> calculateDebts(
    List<SplitExpense> expenses,
  ) {
    // Calculate net balance for each person
    final Map<String, double> balances = {};

    for (var expense in expenses) {
      if (expense.isSettled) continue;

      // Payer gets credited
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.totalAmount;

      // Debtors get debited
      expense.splits.forEach((userId, amount) {
        balances[userId] = (balances[userId] ?? 0) - amount;
      });
    }

    // Simplified debt settlement using greedy algorithm
    final creditors = <String, double>{};
    final debtors = <String, double>{};

    balances.forEach((userId, balance) {
      if (balance > 0.01) {
        creditors[userId] = balance;
      } else if (balance < -0.01) {
        debtors[userId] = -balance;
      }
    });

    final settlements = <String, Map<String, double>>{};

    // Match debtors with creditors
    debtors.forEach((debtor, debt) {
      settlements[debtor] = {};
      var remaining = debt;

      creditors.forEach((creditor, credit) {
        if (remaining > 0.01 && credit > 0.01) {
          final payment = remaining < credit ? remaining : credit;
          settlements[debtor]![creditor] = payment;
          creditors[creditor] = credit - payment;
          remaining -= payment;
        }
      });
    });

    return settlements;
  }
}
