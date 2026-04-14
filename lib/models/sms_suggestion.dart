enum SmsSuggestionStatus { newSuggestion, imported, ignored }

class SmsSuggestion {
  final String id;
  final String rawSms;
  final double? parsedAmount;
  final String? parsedMerchant;
  final DateTime? parsedDate;
  final double confidence;
  final SmsSuggestionStatus status;
  final String? detectedAccount;
  final String? sender;
  final DateTime createdAt;

  const SmsSuggestion({
    required this.id,
    required this.rawSms,
    required this.parsedAmount,
    required this.parsedMerchant,
    required this.parsedDate,
    required this.confidence,
    required this.status,
    required this.detectedAccount,
    required this.sender,
    required this.createdAt,
  });

  SmsSuggestion copyWith({
    String? id,
    String? rawSms,
    double? parsedAmount,
    bool clearParsedAmount = false,
    String? parsedMerchant,
    bool clearParsedMerchant = false,
    DateTime? parsedDate,
    bool clearParsedDate = false,
    double? confidence,
    SmsSuggestionStatus? status,
    String? detectedAccount,
    bool clearDetectedAccount = false,
    String? sender,
    bool clearSender = false,
    DateTime? createdAt,
  }) {
    return SmsSuggestion(
      id: id ?? this.id,
      rawSms: rawSms ?? this.rawSms,
      parsedAmount: clearParsedAmount
          ? null
          : (parsedAmount ?? this.parsedAmount),
      parsedMerchant: clearParsedMerchant
          ? null
          : (parsedMerchant ?? this.parsedMerchant),
      parsedDate: clearParsedDate ? null : (parsedDate ?? this.parsedDate),
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      detectedAccount: clearDetectedAccount
          ? null
          : (detectedAccount ?? this.detectedAccount),
      sender: clearSender ? null : (sender ?? this.sender),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rawSms': rawSms,
      'parsedAmount': parsedAmount,
      'parsedMerchant': parsedMerchant,
      'parsedDate': parsedDate?.toIso8601String(),
      'confidence': confidence,
      'status': status.name,
      'detectedAccount': detectedAccount,
      'sender': sender,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SmsSuggestion.fromMap(Map<String, dynamic> map) {
    return SmsSuggestion(
      id: map['id'] as String,
      rawSms: (map['rawSms'] ?? '') as String,
      parsedAmount: map['parsedAmount'] == null
          ? null
          : (map['parsedAmount'] as num).toDouble(),
      parsedMerchant: map['parsedMerchant'] as String?,
      parsedDate: map['parsedDate'] == null
          ? null
          : DateTime.tryParse(map['parsedDate'] as String),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0,
      status: _statusFromString(map['status'] as String?),
      detectedAccount: map['detectedAccount'] as String?,
      sender: map['sender'] as String?,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static SmsSuggestionStatus _statusFromString(String? value) {
    switch (value) {
      case 'imported':
        return SmsSuggestionStatus.imported;
      case 'ignored':
        return SmsSuggestionStatus.ignored;
      case 'newSuggestion':
      default:
        return SmsSuggestionStatus.newSuggestion;
    }
  }
}
