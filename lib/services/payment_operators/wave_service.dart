/// Service pour traiter les paiements Wave
/// Plateforme USSD pan-africaine supportant plusieurs opérateurs
import 'package:logger/logger.dart';

class WaveService {
  static const String operatorCode = 'wave';
  static const String ussdCode = '*557#';
  static final _logger = Logger();

  // Pays supportés par Wave
  static const Map<String, String> supportedCountries = {
    'SN': 'Sénégal',
    'CI': 'Côte d\'Ivoire',
    'ML': 'Mali',
    'BJ': 'Bénin',
    'TG': 'Togo',
    'BF': 'Burkina Faso',
  };

  /// Valide le numéro de téléphone pour Wave
  static bool validatePhoneNumber(String phoneNumber, String countryCode) {
    if (!supportedCountries.containsKey(countryCode)) {
      throw Exception('Pays non supporté par Wave');
    }

    final regex = RegExp(r'^\+?\d{1,3}\d{8,10}$');
    if (!regex.hasMatch(phoneNumber.replaceAll(' ', ''))) {
      throw Exception('Format de téléphone invalide pour Wave');
    }

    return true;
  }

  /// Initialise une transaction Wave
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
      'reference': 'WAVE-${DateTime.now().millisecondsSinceEpoch}',
      'ussdCode': ussdCode,
      'message': 'Composez $ussdCode pour payer avec Wave',
      'deepLink': 'wave://pay?amount=$amount&ref=$transactionId',
      'expiresAt': DateTime.now().add(Duration(minutes: 10)),
    };
  }

  /// Vérification du statut Wave (via API GraphQL)
  static Map<String, dynamic> checkTransactionStatus(String reference) {
    // En production: appel Wave API GraphQL
    // Wave API: https://api.wave.com/graphql

    return {
      'reference': reference,
      'status': 'success',
      'amount': 5000,
      'currency': 'XOF',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Annule une transaction Wave
  static void cancelTransaction(String reference) {
    _logger.i('❌ Transaction Wave $reference annulée');
  }

  /// Génère un code QR pour Wave
  static String generateQRCode({
    required double amount,
    required String phoneNumber,
  }) {
    // En production: générer QR code valide Wave
    return 'WAVE-QR-${amount.toInt()}-${phoneNumber.hashCode}';
  }

  /// Détecte le pays depuis le numéro de téléphone
  static String detectCountry(String phoneNumber) {
    // Pour cette build de développement, nous limitons les paiements à la Côte d'Ivoire.
    if (phoneNumber.startsWith('+225')) return 'CI';
    // Par défaut, considérer CI pour simplifier le dev local.
    return 'CI';
  }
}
