/// Service pour traiter les paiements Orange Money
/// Supporte: Sénégal, Mali, Côte d'Ivoire, Cameroun
import 'package:logger/logger.dart';

class OrangeMoneyService {
  static const String operatorCode = 'orange_money';
  static const String ussdCode = '#150#';
  static final _logger = Logger();

  // Pays et codes supportés
  static const Map<String, String> supportedCountries = {
    'SN': 'Sénégal',
    'ML': 'Mali',
    'CI': 'Côte d\'Ivoire',
    'CM': 'Cameroun',
  };

  /// Valide le numéro de téléphone pour Orange Money
  static bool validatePhoneNumber(String phoneNumber, String countryCode) {
    if (!supportedCountries.containsKey(countryCode)) {
      throw Exception('Pays non supporté par Orange Money');
    }

    // Format: +221XXXXXXXXX pour le Sénégal
    // Format générique: +XXX9XX (devrait commencer par 9)
    final regex = RegExp(r'^\+?\d{1,3}\d{8,10}$');
    if (!regex.hasMatch(phoneNumber.replaceAll(' ', ''))) {
      throw Exception('Format de téléphone invalide');
    }

    return true;
  }

  /// Initialise une transaction Orange Money
  static Map<String, dynamic> initiateTransaction({
    required String phoneNumber,
    required double amount,
    required String transactionId,
    String currency = 'XOF',
  }) {
    // For simulation we restrict to Côte d'Ivoire; validate accordingly
    validatePhoneNumber(phoneNumber, 'CI');

    return {
      'status': 'initiated',
      'operator': operatorCode,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'currency': currency,
      'transactionId': transactionId,
      'reference': 'OM-${DateTime.now().millisecondsSinceEpoch}',
      'ussdCode': ussdCode,
      'message': 'Composez $ussdCode sur votre téléphone Orange',
      'expiresAt': DateTime.now().add(Duration(minutes: 15)),
    };
  }

  /// Simule la vérification du paiement (à remplacer par API Orange)
  static Map<String, dynamic> checkTransactionStatus(String reference) {
    // En production: appel API Orange Money API
    // Orange Money API: https://developer.orange.sn/...

    return {
      'reference': reference,
      'status': 'success', // En production: récupérer du serveur Orange
      'amount': 5000,
      'currency': 'XOF',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Annule une transaction en cours
  static void cancelTransaction(String reference) {
    // En production: appel API Orange Money
    _logger.i('❌ Transaction Orange Money $reference annulée');
  }

  /// Génère un code USSD pour Orange Money
  static String generateUSSDCode({
    required double amount,
    required String phoneNumber,
  }) {
    // Format USSD: *150*<amount>#
    return '*150*${amount.toInt()}#';
  }
}
