import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/services/sms_parser_service.dart';

void main() {
  group('SmsParserService', () {
    final parser = SmsParserService();

    test('extracts amount and merchant from UPI debit SMS', () {
      final suggestion = parser.parse(
        rawSms:
            'Your A/c XX1234 debited by INR 250.00 on UPI to SWIGGY@okhdfc. Avl bal: 5000',
        smsDate: DateTime(2026, 2, 20, 10, 30),
        sender: 'HDFCBK',
      );

      expect(suggestion.parsedAmount, 250.00);
      expect(suggestion.parsedMerchant, isNotNull);
      expect(suggestion.confidence, greaterThanOrEqualTo(0.6));
      expect(suggestion.detectedAccount, isNotNull);
    });

    test('handles amount format with rupee symbol and commas', () {
      final suggestion = parser.parse(
        rawSms: 'Rs alert: purchase of ₹1,250 at DMART using card ending 4455',
        smsDate: DateTime.now(),
        sender: 'ICICIB',
      );

      expect(suggestion.parsedAmount, 1250);
      expect(suggestion.confidence, greaterThan(0.5));
    });

    test('keeps low confidence when merchant/amount are unclear', () {
      final suggestion = parser.parse(
        rawSms: 'UPI alert received.',
        smsDate: DateTime.now(),
        sender: 'BANK',
      );

      expect(suggestion.confidence, lessThan(0.55));
      expect(suggestion.parsedAmount, isNull);
    });
  });
}
