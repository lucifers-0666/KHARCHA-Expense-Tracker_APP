import 'package:cloud_firestore/cloud_firestore.dart';

enum WalletType {
  cash,
  bank,
  creditCard,
  savings,
  upi,
}

extension WalletTypeExt on WalletType {
  String get label {
    switch (this) {
      case WalletType.cash:       return 'Cash';
      case WalletType.bank:       return 'Bank Account';
      case WalletType.creditCard: return 'Credit Card';
      case WalletType.savings:    return 'Savings Account';
      case WalletType.upi:        return 'UPI Wallet';
    }
  }

  String get emoji {
    switch (this) {
      case WalletType.cash:       return '💵';
      case WalletType.bank:       return '🏦';
      case WalletType.creditCard: return '💳';
      case WalletType.savings:    return '🏧';
      case WalletType.upi:        return '📲';
    }
  }

  static WalletType fromString(String s) =>
      WalletType.values.firstWhere((e) => e.name == s, orElse: () => WalletType.cash);
}

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final double balance;
  final String? bankName;
  final String? last4;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.createdAt,
    this.bankName,
    this.last4,
  });

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.name,
        'balance': balance,
        'bankName': bankName,
        'last4': last4,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Wallet.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Wallet(
      id: doc.id,
      name: d['name'] ?? '',
      type: WalletTypeExt.fromString(d['type'] ?? 'cash'),
      balance: (d['balance'] as num? ?? 0).toDouble(),
      bankName: d['bankName'],
      last4: d['last4'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Wallet copyWith({double? balance}) => Wallet(
        id: id,
        name: name,
        type: type,
        balance: balance ?? this.balance,
        createdAt: createdAt,
        bankName: bankName,
        last4: last4,
      );
}
