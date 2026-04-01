/// Service pour traiter les paiements Moov Money
/// Supporte: Togo, Bénin, Mali, Côte d'Ivoire
import 'package:logger/logger.dart';

class MoovMoneyService {
  static const String operatorCode = 'moov_money';
  static const String ussdCode = '*556#';
  static final _logger = Logger();

  static const Map<String, String> supportedCountries = {
    'TG': 'Togo',
    'BJ': 'Bénin',
    'ML': 'Mali',
    'CI': 'Côte d\'Ivoire',
  };

  /// Valide le numéro de téléphone pour Moov Money
  static bool validatePhoneNumber(String phoneNumber, String countryCode) {
    if (!supportedCountries.containsKey(countryCode)) {
      throw Exception('Pays non supporté par Moov Money');
    }

    final regex = RegExp(r'^\+?\d{1,3}\d{8,10}$');
    if (!regex.hasMatch(phoneNumber.replaceAll(' ', ''))) {
      throw Exception('Format de téléphone invalide pour Moov Money');
    }

    return true;
  }

  /// Initialise une transaction Moov Money
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
      'reference': 'MM-${DateTime.now().millisecondsSinceEpoch}',
      'ussdCode': ussdCode,
      'message': 'Composez $ussdCode pour payer avec Moov Money',
      'expiresAt': DateTime.now().add(Duration(minutes: 15)),
    };
  }

  /// Vérification du statut Moov Money
  static Map<String, dynamic> checkTransactionStatus(String reference) {
    // En production: appel API Moov Money

    return {
      'reference': reference,
      'status': 'success',
      'amount': 5000,
      'currency': 'XOF',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Annule une transaction Moov Money
  static void cancelTransaction(String reference) {
    _logger.i('❌ Transaction Moov Money $reference annulée');
  }

  /// Détecte le pays depuis le numéro de téléphone
  static String detectCountry(String phoneNumber) {
    // Limiter aux numéros Côte d'Ivoire pour le développement local
    if (phoneNumber.startsWith('+225')) return 'CI';
    return 'CI';
  }

  /// Génère le formulaire d'inscription pour un nouveau compte
  static Map<String, dynamic> generateSignupFlow({
    required String phoneNumber,
  }) {
    return {
      'operator': operatorCode,
      'phoneNumber': phoneNumber,
      'signupUSSD': '*5560#',
      'instructions':
          'Créez un compte Moov Money en composant le code ci-dessus',
      'terms': 'Conditions Moov Money s\'appliquent',
    };
  }
}
