import 'orange_money_service.dart';
import 'wave_service.dart';
import 'moov_money_service.dart';
import 'mtn_money_service.dart';
import 'card_payment_service.dart';
import '../payment_simulator.dart';

// Re-export CardData pour faciliter l'accès
export 'card_payment_service.dart' show CardData;

/// Gestionnaire centralisé pour tous les opérateurs de paiement
class PaymentOperatorsManager {
  /// When true, payments are simulated and restricted to Côte d'Ivoire (+225).
  /// Toggle this flag in development to enable CI-only simulation.
  // Enabled: the app runs in CI-only mode by default (Côte d'Ivoire)
  static bool simulateCI = true;
  /// Énumération des opérateurs supportés
  static const List<String> supportedOperators = [
    'orange_money',
    'wave',
    'moov_money',
    'mtn_money',
    'card',
  ];

  /// Informations sur les opérateurs
  static const Map<String, Map<String, dynamic>> operatorInfo = {
    'orange_money': {
      'name': 'Orange Money',
      'countries': ['SN', 'ML', 'CI', 'CM'],
      'ussdCode': '#150#',
      'minAmount': 100,
      'maxAmount': 500000,
      'fees': 1.0, // %
    },
    'wave': {
      'name': 'Wave',
      'countries': ['SN', 'CI', 'ML', 'BJ', 'TG', 'BF'],
      'ussdCode': '*557#',
      'minAmount': 500,
      'maxAmount': 1000000,
      'fees': 1.0,
    },
    'moov_money': {
      'name': 'Moov Money',
      // Added 'SN' so Moov Money is available in Senegal as requested
      'countries': ['TG', 'BJ', 'ML', 'CI', 'SN'],
      'ussdCode': '*556#',
      'minAmount': 100,
      'maxAmount': 500000,
      'fees': 1.5,
    },
    'mtn_money': {
      'name': 'MTN Money',
      // Added 'SN' so MTN Money is available in Senegal as requested
      'countries': ['CM', 'ML', 'CI', 'BJ', 'BF', 'SN'],
      'ussdCode': '*156#',
      'minAmount': 100,
      'maxAmount': 500000,
      'fees': 1.0,
    },
    'card': {
      'name': 'Carte Bancaire',
      'icon': '💳',
      'countries': ['Global'],
      'minAmount': 1000,
      'maxAmount': 10000000,
      'fees': 2.5,
    },
  };

  /// Obtient la liste des opérateurs disponibles pour un pays
  static List<String> getAvailableOperators(String countryCode) {
    final operators = <String>[];

    operatorInfo.forEach((operator, info) {
      if (info['countries'].contains(countryCode) ||
          info['countries'].contains('Global')) {
        operators.add(operator);
      }
    });

    return operators;
  }

  /// Obtient les informations d'un opérateur
  static Map<String, dynamic>? getOperatorInfo(String operator) {
    return operatorInfo[operator];
  }

  /// Valide le montant pour un opérateur
  static bool validateAmount(String operator, double amount) {
    final info = operatorInfo[operator];
    if (info == null) return false;

    return amount >= info['minAmount'] && amount <= info['maxAmount'];
  }

  /// Calcule les frais de transaction
  static double calculateFees(String operator, double amount) {
    final info = operatorInfo[operator];
    if (info == null) return 0;

    return amount * (info['fees'] as double) / 100;
  }

  /// Calcule le montant total (montant + frais)
  static double calculateTotal(String operator, double amount) {
    return amount + calculateFees(operator, amount);
  }

  /// Initialise une transaction selon l'opérateur
  static Map<String, dynamic> initiateTransaction({
    required String operator,
    required Map<String, dynamic> data,
  }) {
    // Normalize amount to double to accept int or String inputs from tests
    final dynamic rawAmount = data['amount'];
    final double amount = rawAmount is num
        ? rawAmount.toDouble()
        : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;
    final phone = data['phoneNumber'] as String? ?? '';
    final country = detectCountryFromPhone(phone);

    // Only trigger CI simulator when explicitly CI and phone number is CI (+225)
    if (simulateCI && country == 'CI' && phone.startsWith('+225')) {
      return PaymentSimulator.simulatePayment(
        operator: operator,
        phoneNumber: phone,
        amount: amount,
        currency: data['currency'] ?? 'XOF',
      );
    }

    switch (operator) {
      case 'orange_money':
        return OrangeMoneyService.initiateTransaction(
          phoneNumber: data['phoneNumber'],
          amount: amount,
          transactionId: data['transactionId'],
          currency: data['currency'] ?? 'XOF',
        );

      case 'wave':
        return WaveService.initiateTransaction(
          phoneNumber: data['phoneNumber'],
          amount: amount,
          transactionId: data['transactionId'],
          currency: data['currency'] ?? 'XOF',
        );

      case 'moov_money':
        return MoovMoneyService.initiateTransaction(
          phoneNumber: data['phoneNumber'],
          amount: amount,
          transactionId: data['transactionId'],
          currency: data['currency'] ?? 'XOF',
        );

      case 'mtn_money':
        return MTNMoneyService.initiateTransaction(
          phoneNumber: data['phoneNumber'],
          amount: amount,
          transactionId: data['transactionId'],
          currency: data['currency'] ?? 'XOF',
        );

      case 'card':
        return CardPaymentService.initiateTransaction(
          cardData: CardData(
            cardNumber: data['cardNumber'],
            cardHolder: data['cardHolder'],
            expiryDate: data['expiryDate'],
            cvv: data['cvv'],
            country: data['country'] ?? 'SN',
          ),
          amount: amount,
          transactionId: data['transactionId'],
          currency: data['currency'] ?? 'XOF',
        );

      default:
        throw Exception('Opérateur non supporté: $operator');
    }
  }

  /// Vérifie le statut d'une transaction
  static Map<String, dynamic> checkTransactionStatus(
    String operator,
    String reference,
  ) {
    switch (operator) {
      case 'orange_money':
        return OrangeMoneyService.checkTransactionStatus(reference);
      case 'wave':
        return WaveService.checkTransactionStatus(reference);
      case 'moov_money':
        return MoovMoneyService.checkTransactionStatus(reference);
      case 'mtn_money':
        return MTNMoneyService.checkTransactionStatus(reference);
      case 'card':
        return CardPaymentService.checkTransactionStatus(reference);
      default:
        throw Exception('Opérateur non supporté: $operator');
    }
  }

  /// Annule une transaction
  static void cancelTransaction(String operator, String reference) {
    switch (operator) {
      case 'orange_money':
        OrangeMoneyService.cancelTransaction(reference);
        break;
      case 'wave':
        WaveService.cancelTransaction(reference);
        break;
      case 'moov_money':
        MoovMoneyService.cancelTransaction(reference);
        break;
      case 'mtn_money':
        MTNMoneyService.cancelTransaction(reference);
        break;
      case 'card':
        CardPaymentService.cancelTransaction(reference);
        break;
      default:
        throw Exception('Opérateur non supporté: $operator');
    }
  }

  /// Formate les informations de paiement pour l'affichage
  static String formatPaymentInfo({
    required String operator,
    required Map<String, dynamic> data,
  }) {
    final info = operatorInfo[operator];
    if (info == null) return 'Opérateur inconnu';

    switch (operator) {
      case 'card':
        final last4 = data['cardLast4'] as String?;
        return '${info['name']} (**$last4)';
      default:
        final phone = data['phoneNumber'] as String?;
        return '${info['name']} ($phone)';
    }
  }

  /// Détecte le pays depuis un numéro de téléphone
  static String detectCountryFromPhone(String phoneNumber) {
    // Map common international dialing prefixes to country codes
    const prefixMap = {
      '+221': 'SN', // Senegal
      '+225': 'CI', // Côte d'Ivoire
      '+237': 'CM', // Cameroun
      '+226': 'BF', // Burkina Faso
      '+223': 'ML', // Mali
      '+229': 'BJ', // Benin
      '+228': 'TG', // Togo
    };

    for (final entry in prefixMap.entries) {
      if (phoneNumber.startsWith(entry.key)) return entry.value;
    }

    // Unknown or unsupported prefix
    return 'Unknown';
  }

  /// Obtient les instructions de paiement pour un opérateur
  static String getPaymentInstructions(String operator) {
    final info = operatorInfo[operator];
    if (info == null) return '';

    switch (operator) {
      case 'orange_money':
        return 'Composez ${info['ussdCode']} sur votre téléphone Orange et suivez les instructions';
      case 'wave':
        return 'Composez ${info['ussdCode']} ou utilisez l\'application Wave';
      case 'moov_money':
        return 'Composez ${info['ussdCode']} pour confirmer le paiement';
      case 'mtn_money':
        return 'Composez ${info['ussdCode']} pour autoriser la transaction';
      case 'card':
        return 'Confirmez le paiement avec 3D Secure sur votre application bancaire';
      default:
        return '';
    }
  }
}
