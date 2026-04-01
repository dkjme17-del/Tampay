import 'package:flutter_test/flutter_test.dart';
import 'package:applicationweb/payment_system_exports.dart';

void main() {
  test('Operators available for CI include moov_money and mtn_money', () {
    final ops = PaymentOperatorsManager.getAvailableOperators('CI');
    expect(ops, contains('moov_money'));
    expect(ops, contains('mtn_money'));
  });

  test('Initiate transactions for Moov and MTN do not throw', () {
    final moov = PaymentOperatorsManager.initiateTransaction(
      operator: 'moov_money',
      data: {
        'phoneNumber': '+2250700000001',
        'amount': 1000,
        'transactionId': 'tx-test-moov',
      },
    );
    expect(moov['operator'], equals('moov_money'));

    final mtn = PaymentOperatorsManager.initiateTransaction(
      operator: 'mtn_money',
      data: {
        'phoneNumber': '+2250700000002',
        'amount': 2000,
        'transactionId': 'tx-test-mtn',
      },
    );
    expect(mtn['operator'], equals('mtn_money'));
  });
}
