/// Service pour traiter les paiements MTN Money
/// Supporte: Cameroun, Mali, Côte d'Ivoire, Bénin, Burkina Faso
import 'package:logger/logger.dart';

class MTNMoneyService {
  static const String operatorCode = 'mtn_money';
  static const String ussdCode = '*156#';
  static final _logger = Logger();

  static const Map<String, String> supportedCountries = {
    'CM': 'Cameroun',
    'ML': 'Mali',
    'CI': 'Côte d\'Ivoire',
    'BJ': 'Bénin',
    'BF': 'Burkina Faso',
  };

  /// Valide le numéro de téléphone pour MTN Money
  static bool validatePhoneNumber(String phoneNumber, String countryCode) {
    if (!supportedCountries.containsKey(countryCode)) {
      throw Exception('Pays non supporté par MTN Money');
    }

    final regex = RegExp(r'^\+?\d{1,3}\d{8,10}$');
    if (!regex.hasMatch(phoneNumber.replaceAll(' ', ''))) {
      throw Exception('Format de téléphone invalide pour MTN Money');
    }

    return true;
  }

  /// Initialise une transaction MTN Money
  static Map<String, dynamic> initiateTransaction({
    required String phoneNumber,
    required double amount,
    required String transactionId,
    String currency = 'XOF',
  }) {
    validatePhoneNumber(phoneNumber, detectCountry(phoneNumber));

    return {
      'status': 'initiated',
      'operator': operatorCode,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'currency': currency,
      'transactionId': transactionId,
      'reference': 'MTN-${DateTime.now().millisecondsSinceEpoch}',
      'ussdCode': ussdCode,
      'message': 'Composez $ussdCode pour payer avec MTN Money',
      'expiresAt': DateTime.now().add(Duration(minutes: 15)),
    };
  }

  /// Vérification du statut MTN Money
  static Map<String, dynamic> checkTransactionStatus(String reference) {
    // En production: appel API MTN Money

    return {
      'reference': reference,
      'status': 'success',
      'amount': 5000,
      'currency': 'XOF',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Annule une transaction MTN Money
  static void cancelTransaction(String reference) {
    _logger.i('❌ Transaction MTN Money $reference annulée');
  }

  /// Détecte le pays depuis le numéro de téléphone
  static String detectCountry(String phoneNumber) {
    // Limiter aux numéros Côte d'Ivoire pour le développement local
    if (phoneNumber.startsWith('+225')) return 'CI';
    return 'CI';
  }

  /// Obtient le taux de change pour une devise
  static double getExchangeRate(String fromCurrency, String toCurrency) {
    // En production: obtenir les taux en temps réel
    Map<String, Map<String, double>> rates = {
      'XOF': {'USD': 0.0016, 'EUR': 0.0015, 'XOF': 1.0},
      'USD': {'XOF': 625, 'EUR': 0.92, 'USD': 1.0},
    };

    return rates[fromCurrency]?[toCurrency] ?? 1.0;
  }
}
