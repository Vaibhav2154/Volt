import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/sms/data/datasources/sms_parser.dart';

void main() {
  group('SmsParser Sender Matching', () {
    test('should accept SBIUPI like senders even with hyphens', () {
      const sender = 'VA-SBIUPI-S';
      const body = 'UPI payment of Rs.100 debited to merchant@upi on 03Dec25';

      final isBank = SmsParser.isBankSms(body, sender: sender);
      expect(isBank, true);
    });

    test('should accept AXIS as bank sender name', () {
      const sender = 'AXIS';
      const body = 'Rs.250 debited via UPI to merchant@upi';

      final isBank = SmsParser.isBankSms(body, sender: sender);
      expect(isBank, true);
    });
  });

  group('SmsParser transaction parsing', () {
    test('should parse transaction from SBIUPI sender', () {
      const sender = 'VA-SBIUPI-S';
      const body = 'Dear UPI user A/C X7453 debited by 40.0 on date 03Dec25 trf to KUMARV Refno 533769574254';

      final txn = SmsParser.parseTransaction(body, timestamp: DateTime.now(), sender: sender);
      expect(txn, isNotNull);
      expect(txn!.type.name.toUpperCase(), contains('DEBIT'), reason: 'Should be DEBIT');
      expect(txn.amount, '40.0');
    });

    test('should reject promotional message with price as not a transaction', () {
      const sender = 'AIRTEL';
      const body = 'Never run out of data during important moments. Get 75 GB + 200 GB rollover on Postpaid at just Rs.449. Upgrade now https://i.airtel.in/goldencohort';

      final isBank = SmsParser.isBankSms(body, sender: sender);
      expect(isBank, false, reason: 'Promotional message should not be treated as bank SMS');

      final txn = SmsParser.parseTransaction(body, timestamp: DateTime.now(), sender: sender);
      expect(txn, isNull, reason: 'Promotional message with Rs should not produce a transaction');
    });
  });
}
