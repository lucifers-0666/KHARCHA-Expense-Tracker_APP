import 'package:flutter_application_1/models/sms_suggestion.dart';

class SmsParserService {
  static const Set<String> debitKeywords = {
    'debited',
    'spent',
    'purchase',
    'upi',
    'imps',
    'pos',
    'atm',
  };

  static const double defaultConfidenceThreshold = 0.55;

  static final RegExp _currencyAmountRegex = RegExp(
    r'(?:₹|rs\.?|inr)\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _contextAmountRegex = RegExp(
    r'(?:debited|spent|purchase(?:\s+of)?|upi|imps|pos|atm)[^\d₹]*(?:₹|rs\.?|inr)?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)',
    caseSensitive: false,
  );

  static final RegExp _fallbackAmountRegex = RegExp(
    r'\b(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+(?:\.\d{1,2})?)\b',
    caseSensitive: false,
  );

  static final List<RegExp> _merchantPatterns = [
    RegExp(
      r'(?:to|at|from|towards)\s+([A-Za-z0-9&._\- ]{3,40})',
      caseSensitive: false,
    ),
    RegExp(
      r'merchant\s*[:\-]\s*([A-Za-z0-9&._\- ]{3,40})',
      caseSensitive: false,
    ),
    RegExp(r'vpa\s*[:\-]?\s*([A-Za-z0-9._\-@]{3,60})', caseSensitive: false),
  ];

  static final List<RegExp> _accountPatterns = [
    RegExp(
      r'(?:a/c|acct|account)\s*(?:ending|xx|x|no\.?|number)?\s*[:\-*xX ]*(\d{2,6})',
      caseSensitive: false,
    ),
    RegExp(r'\bxx(\d{4})\b', caseSensitive: false),
  ];

  SmsSuggestion parse({
    required String rawSms,
    required DateTime? smsDate,
    required String? sender,
    String? id,
  }) {
    final normalized = rawSms.toLowerCase();
    final hasDebitKeyword = debitKeywords.any(normalized.contains);

    final amount = _extractAmount(rawSms);
    final merchant = _extractMerchant(rawSms);
    final account = _extractAccount(rawSms);

    var confidence = 0.0;
    if (hasDebitKeyword) confidence += 0.40;
    if (amount != null && amount > 0) confidence += 0.35;
    if (merchant != null && merchant.trim().isNotEmpty) confidence += 0.20;
    if (account != null && account.trim().isNotEmpty) confidence += 0.05;
    confidence = confidence.clamp(0, 1).toDouble();

    final now = DateTime.now();
    return SmsSuggestion(
      id: id ?? 'sms_${now.millisecondsSinceEpoch}',
      rawSms: rawSms,
      parsedAmount: amount,
      parsedMerchant: merchant,
      parsedDate: smsDate,
      confidence: confidence,
      status: SmsSuggestionStatus.newSuggestion,
      detectedAccount: account,
      sender: sender,
      createdAt: now,
    );
  }

  bool isLikelyDebitMessage(String smsBody) {
    final normalized = smsBody.toLowerCase();
    return debitKeywords.any(normalized.contains);
  }

  double? _extractAmount(String body) {
    for (final regex in [
      _contextAmountRegex,
      _currencyAmountRegex,
      _fallbackAmountRegex,
    ]) {
      final match = regex.firstMatch(body);
      final raw = (match?.group(1) ?? '').replaceAll(',', '').trim();
      final value = double.tryParse(raw);
      if (value != null && value > 0) {
        return value;
      }
    }
    return null;
  }

  String? _extractMerchant(String body) {
    for (final pattern in _merchantPatterns) {
      final match = pattern.firstMatch(body);
      final value = match?.group(1)?.trim();
      if (value != null && value.length >= 3) {
        return _cleanupMerchant(value);
      }
    }
    return null;
  }

  String? _extractAccount(String body) {
    for (final pattern in _accountPatterns) {
      final match = pattern.firstMatch(body);
      final value = match?.group(1)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _cleanupMerchant(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.,;:-]+$'), '')
        .trim();
  }
}
