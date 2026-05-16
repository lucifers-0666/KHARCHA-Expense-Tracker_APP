import 'merchant_classifier.dart';

/// Parses Indian UPI SMS/notification strings to extract transaction data.
class UpiParser {
  static final _classifier = MerchantClassifier();

  // GPay, PhonePe, Paytm, BHIM patterns
  static final List<RegExp> _amountPatterns = [
    RegExp(
      r'(?:Rs\.?|INR|₹)\s*([0-9,]+(?:\.[0-9]{1,2})?)',
      caseSensitive: false,
    ),
    RegExp(
      r'([0-9,]+(?:\.[0-9]{1,2})?)\s*(?:Rs\.?|INR|₹)',
      caseSensitive: false,
    ),
  ];

  static final List<RegExp> _merchantPatterns = [
    RegExp(
      r'(?:to|paid to|sent to|at)\s+([A-Za-z0-9 &\.\-]+?)(?:\s+(?:via|on|for|ref|upi)|\.|$)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:at|from)\s+([A-Za-z0-9 &\.\-]+?)(?:\s+(?:dated|on|ref)|\.|$)',
      caseSensitive: false,
    ),
    RegExp(r'to VPA\s+([A-Za-z0-9@\.]+)', caseSensitive: false),
  ];

  static final List<RegExp> _creditPatterns = [
    RegExp(r'(?:credited|received|added)', caseSensitive: false),
  ];

  static final List<String> _upiSenders = [
    'gpay',
    'googlepay',
    'phonepe',
    'paytm',
    'bhim',
    'upi',
    'amazonpay',
    'mobikwik',
    'freecharge',
    'airtelbank',
  ];

  /// Returns null if message is not a UPI transaction
  UpiTransaction? parse(String message, {String? sender}) {
    final lower = message.toLowerCase();

    // Quick UPI detection
    final isUpi = sender != null
        ? _upiSenders.any((s) => sender.toLowerCase().contains(s))
        : _upiSenders.any((s) => lower.contains(s)) ||
              lower.contains('upi') ||
              lower.contains('vpa');

    if (!isUpi) return null;

    // Extract amount
    double? amount;
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        final raw = match.group(1)!.replaceAll(',', '');
        amount = double.tryParse(raw);
        if (amount != null) break;
      }
    }
    if (amount == null || amount <= 0) return null;

    // Extract merchant
    String? merchant;
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty) break;
      }
    }

    // Transaction type
    final isCredit = _creditPatterns.any((p) => p.hasMatch(message));
    final type = isCredit ? TransactionType.credit : TransactionType.debit;

    // Classify category
    final classification = merchant != null
        ? _classifier.classify(merchant)
        : ClassifyResult(
            category: 'Other',
            confidence: 0.0,
            isUserOverride: false,
          );

    // Extract UPI ref
    final refMatch = RegExp(
      r'(?:ref|txn|utr)[:\s#]*([0-9A-Za-z]+)',
      caseSensitive: false,
    ).firstMatch(message);
    final refId = refMatch?.group(1);

    return UpiTransaction(
      amount: amount,
      merchant: merchant ?? 'UPI Transfer',
      category: classification.category,
      categoryConfidence: classification.confidence,
      type: type,
      rawMessage: message,
      refId: refId,
      parsedAt: DateTime.now(),
    );
  }
}

enum TransactionType { debit, credit }

class UpiTransaction {
  final double amount;
  final String merchant;
  final String category;
  final double categoryConfidence;
  final TransactionType type;
  final String rawMessage;
  final String? refId;
  final DateTime parsedAt;

  const UpiTransaction({
    required this.amount,
    required this.merchant,
    required this.category,
    required this.categoryConfidence,
    required this.type,
    required this.rawMessage,
    this.refId,
    required this.parsedAt,
  });

  bool get isHighConfidence => categoryConfidence >= 0.7;
  bool get isDebit => type == TransactionType.debit;
}
