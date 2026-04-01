import 'package:flutter_test/flutter_test.dart';
import 'package:applicationweb/services/payment_operators/payment_operators_manager.dart';
import 'package:applicationweb/services/payment_operators/card_payment_service.dart';

void main() {
  // Build a dynamic future expiry date for card tests to remain valid
  final futureMonth = DateTime.now().month.toString().padLeft(2, '0');
  final futureYear = DateTime.now().year.toString().substring(2);
  final futureExpiry = '$futureMonth/$futureYear';

  group('PaymentOperatorsManager Tests', () {
    test('getAvailableOperators retourne les opérateurs pour un pays', () {
      final operators = PaymentOperatorsManager.getAvailableOperators('SN');
      expect(operators.isNotEmpty, true);
      expect(operators.contains('orange_money'), true);
      expect(operators.contains('wave'), true);
    });

    test('validateAmount valide les montants', () {
      // Montant valide
      expect(
        PaymentOperatorsManager.validateAmount('orange_money', 5000),
        true,
      );

      // Montant trop bas
      expect(PaymentOperatorsManager.validateAmount('orange_money', 50), false);

      // Montant trop haut
      expect(
        PaymentOperatorsManager.validateAmount('orange_money', 1000000),
        false,
      );
    });

    test('calculateFees calcule correctement les frais', () {
      // Orange Money: 1%
      final orangeFees = PaymentOperatorsManager.calculateFees(
        'orange_money',
        5000,
      );
      expect(orangeFees, 50);

      // Card: 2.5%
      final cardFees = PaymentOperatorsManager.calculateFees('card', 5000);
      expect(cardFees, 125);
    });

    test('calculateTotal inclut les frais', () {
      final total = PaymentOperatorsManager.calculateTotal(
        'orange_money',
        5000,
      );
      expect(total, 5050);
    });

    test('getOperatorInfo retourne les bonnes informations', () {
      final info = PaymentOperatorsManager.getOperatorInfo('wave');
      expect(info?['name'], 'Wave');
      expect(info?['fees'], 1.0);
      expect(info?['countries'], contains('SN'));
    });

    test('detectCountryFromPhone détecte le pays', () {
      expect(
        PaymentOperatorsManager.detectCountryFromPhone('+221701234567'),
        'SN',
      );
      expect(
        PaymentOperatorsManager.detectCountryFromPhone('+225701234567'),
        'CI',
      );
      expect(
        PaymentOperatorsManager.detectCountryFromPhone('+237701234567'),
        'CM',
      );
    });

    test('initiateTransaction crée une transaction correcte', () {
      final transaction = PaymentOperatorsManager.initiateTransaction(
        operator: 'orange_money',
        data: {
          'phoneNumber': '+221701234567',
          'amount': 5000,
          'transactionId': 'TEST123',
          'currency': 'XOF',
        },
      );

      expect(transaction['status'], 'initiated');
      expect(transaction['operator'], 'orange_money');
      expect(transaction['amount'], 5000);
      expect(transaction['reference'].startsWith('OM-'), true);
    });
  });

  group('CardPaymentService Tests', () {
    test('validateCardNumber utilise l\'algorithme de Luhn', () {
      // Visa valide
      expect(CardPaymentService.validateCardNumber('4242424242424242'), true);

      // Mastercard valide
      expect(CardPaymentService.validateCardNumber('5555555555554444'), true);

      // Numéro invalide
      expect(
        () => CardPaymentService.validateCardNumber('1234567890123456'),
        throwsException,
      );
    });

    test('validateExpiryDate valide les dates', () {
      // Date valide dans le futur
      final futureDate = DateTime.now().year.toString().substring(2);
      final futureMonth = DateTime.now().month;
      expect(
        CardPaymentService.validateExpiryDate('$futureMonth/$futureDate'),
        true,
      );

      // Date expirée
      expect(
        () => CardPaymentService.validateExpiryDate('01/20'),
        throwsException,
      );

      // Format invalide
      expect(
        () => CardPaymentService.validateExpiryDate('13/25'),
        throwsException,
      );
    });

    test('validateCVV valide les CVV', () {
      expect(CardPaymentService.validateCVV('123'), true);
      expect(CardPaymentService.validateCVV('1234'), true);

      expect(() => CardPaymentService.validateCVV('12'), throwsException);

      expect(() => CardPaymentService.validateCVV('abcd'), throwsException);
    });

    test('detectCardType détecte le type de carte', () {
      expect(CardPaymentService.detectCardType('4242424242424242'), 'Visa');
      expect(
        CardPaymentService.detectCardType('5555555555554444'),
        'Mastercard',
      );
      expect(
        CardPaymentService.detectCardType('371449635398431'),
        'American Express',
      );
    });

    test('formatCardNumber formate correctement', () {
      final formatted = CardPaymentService.formatCardNumber('4242424242424242');
      expect(formatted, 'xxxx-xxxx-xxxx-4242');
    });

    test('initiateTransaction crée une transaction sécurisée', () {
      final cardData = CardData(
        cardNumber: '4242424242424242',
        cardHolder: 'Test User',
        expiryDate: futureExpiry,
        cvv: '123',
        country: 'SN',
      );

      final transaction = CardPaymentService.initiateTransaction(
        cardData: cardData,
        amount: 5000,
        transactionId: 'CARD123',
        currency: 'XOF',
      );

      expect(transaction['status'], 'initiated');
      expect(transaction['operator'], 'card');
      expect(transaction['cardLast4'], '4242');
      expect(transaction['reference'].startsWith('CARD-'), true);
    });
  });

  group('Integration Tests', () {
    test('Flux complet de paiement Orange Money', () {
      // 1. Sélectionner opérateur
      const operator = 'orange_money';

      // 2. Vérifier disponibilité
      final operators = PaymentOperatorsManager.getAvailableOperators('SN');
      expect(operators.contains(operator), true);

      // 3. Valider montant
      expect(PaymentOperatorsManager.validateAmount(operator, 5000), true);

      // 4. Calculer frais
      final fees = PaymentOperatorsManager.calculateFees(operator, 5000);
      expect(fees, 50);

      // 5. Créer transaction
      final transaction = PaymentOperatorsManager.initiateTransaction(
        operator: operator,
        data: {
          'phoneNumber': '+221701234567',
          'amount': 5000,
          'transactionId': 'FLOW123',
        },
      );

      expect(transaction['status'], 'initiated');
      expect(transaction['reference'].isNotEmpty, true);
    });

    test('Flux complet de paiement par carte', () {
      // 1. Sélectionner opérateur
      const operator = 'card';

      // 2. Vérifier disponibilité
      expect(
        PaymentOperatorsManager.supportedOperators.contains(operator),
        true,
      );

      // 3. Valider montant
      expect(PaymentOperatorsManager.validateAmount(operator, 50000), true);

      // 4. Créer données de carte
      final cardData = CardData(
        cardNumber: '4242424242424242',
        cardHolder: 'John Doe',
        expiryDate: futureExpiry,
        cvv: '123',
        country: 'SN',
      );

      // 5. Créer transaction
      final transaction = PaymentOperatorsManager.initiateTransaction(
        operator: operator,
        data: {
          'cardNumber': cardData.cardNumber,
          'cardHolder': cardData.cardHolder,
          'expiryDate': cardData.expiryDate,
          'cvv': cardData.cvv,
          'country': cardData.country,
          'amount': 50000,
          'transactionId': 'CARD-FLOW123',
        },
      );

      expect(transaction['status'], 'initiated');
      expect(transaction['cardLast4'], '4242');
    });

    test('Vérification du statut de paiement', () {
      // Initier une transaction
      const operator = 'wave';
      final transaction = PaymentOperatorsManager.initiateTransaction(
        operator: operator,
        data: {
          'phoneNumber': '+221701234567',
          'amount': 5000,
          'transactionId': 'STATUS-TEST',
        },
      );

      final reference = transaction['reference'] as String;

      // Vérifier le statut
      final status = PaymentOperatorsManager.checkTransactionStatus(
        operator,
        reference,
      );

      expect(status['reference'], reference);
      expect(status['status'], isNotEmpty);
    });
  });

  group('Error Handling Tests', () {
    test('Rejecter un opérateur invalide', () {
      expect(
        () => PaymentOperatorsManager.initiateTransaction(
          operator: 'invalid_operator',
          data: {},
        ),
        throwsException,
      );
    });

    test('Rejecter une carte avec un numéro invalide', () {
      expect(
        () => CardPaymentService.validateCardNumber('123'),
        throwsException,
      );
    });

    test('Rejecter une date d\'expiration invalide', () {
      expect(
        () => CardPaymentService.validateExpiryDate('99/99'),
        throwsException,
      );
    });
  });
}
