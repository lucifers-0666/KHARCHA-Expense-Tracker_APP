import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:flutter_application_1/models/expense.dart';
import 'package:flutter_application_1/models/sms_suggestion.dart';
import 'package:flutter_application_1/services/firestore_services.dart';
import 'package:flutter_application_1/services/local_database_helper.dart';
import 'package:flutter_application_1/services/sms_parser_service.dart';

class SmsImportService {
  SmsImportService({
    SmsQuery? smsQuery,
    LocalDatabaseHelper? localDb,
    FirestoreServices? firestoreServices,
    SmsParserService? parser,
  })  : _smsQuery         = smsQuery         ?? SmsQuery(),
        _localDb          = localDb          ?? LocalDatabaseHelper.instance,
        _firestoreServices= firestoreServices ?? FirestoreServices(),
        _parser           = parser           ?? SmsParserService();

  final SmsQuery _smsQuery;
  final LocalDatabaseHelper _localDb;
  final FirestoreServices _firestoreServices;
  final SmsParserService _parser;

  /// Reads up to [lookBackCount] inbox messages, parses debit transactions,
  /// and stores new suggestions in the local SQLite DB.
  /// Returns the number of newly inserted suggestions.
  Future<int> pullAndParseRecentSms({int lookBackCount = 300}) async {
    final messages = await _smsQuery.querySms(
      kinds: [SmsQueryKind.inbox],
      count: lookBackCount,
    );

    var inserted = 0;
    for (final SmsMessage message in messages) {
      final body = message.body?.trim();
      if (body == null || body.isEmpty) continue;
      if (!_parser.isLikelyDebitMessage(body)) continue;

      final uniqueId  = _buildSuggestionId(message);
      final existing  = await _localDb.getSmsSuggestionById(uniqueId);
      if (existing != null) continue;

      // message.date is DateTime? in flutter_sms_inbox ≥ 1.0.4
      final smsDate = message.date;

      final suggestion = _parser.parse(
        rawSms : body,
        smsDate: smsDate,
        sender : message.address,
        id     : uniqueId,
      );

      await _localDb.insertSmsSuggestion(suggestion);
      inserted++;
    }
    return inserted;
  }

  Future<List<SmsSuggestion>> getSuggestionsByStatus(
    SmsSuggestionStatus status,
  ) {
    return _localDb.getSmsSuggestionsByStatus(status);
  }

  Future<void> ignoreSuggestion(String id) {
    return _localDb.updateSmsSuggestionStatus(id, SmsSuggestionStatus.ignored);
  }

  Future<void> markAsImported(String id) {
    return _localDb.updateSmsSuggestionStatus(id, SmsSuggestionStatus.imported);
  }

  Future<void> confirmAndCreateExpense({
    required SmsSuggestion suggestion,
    String?   titleOverride,
    double?   amountOverride,
    DateTime? dateOverride,
    String?   categoryOverride,
  }) async {
    final expense = Expense(
      id         : '',
      title      : (titleOverride ?? suggestion.parsedMerchant ?? 'SMS Import').trim(),
      amount     : amountOverride ?? suggestion.parsedAmount ?? 0,
      category   : (categoryOverride ?? 'Other').trim(),
      date       : dateOverride ?? suggestion.parsedDate ?? DateTime.now(),
      description: suggestion.rawSms, // raw SMS stored for reference
    );

    await _firestoreServices.addExpense(expense);
    await markAsImported(suggestion.id);
  }

  // ── private ──────────────────────────────────────────────

  String _buildSuggestionId(SmsMessage message) {
    final datePart   = message.date?.millisecondsSinceEpoch ?? 0;
    final senderPart = (message.address ?? 'unknown').replaceAll(' ', '_');
    final bodyHash   = (message.body ?? '').hashCode;
    return 'sms_${senderPart}_${datePart}_$bodyHash';
  }
}
