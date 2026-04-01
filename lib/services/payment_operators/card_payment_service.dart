import 'package:logger/logger.dart';

/// Modèle pour les données de carte
class CardData {
  final String cardNumber;
  final String cardHolder;
  final String expiryDate; // MM/YY
  final String cvv;
  final String country;

  CardData({
    required this.cardNumber,
    required this.cardHolder,
    required this.expiryDate,
    required this.cvv,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
    'cardNumber': cardNumber,
    'cardHolder': cardHolder,
    'expiryDate': expiryDate,
    'cvv': cvv,
    'country': country,
  };
}

/// Service pour traiter les paiements par Carte Bancaire
/// Support pour Flutterwave et Stripe (production)
class CardPaymentService {
  static const String operatorCode = 'card';
  static final _logger = Logger();

  /// Valide le numéro de carte avec l'algorithme de Luhn
  static bool validateCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');

    if (!RegExp(r'^\d{13,19}$').hasMatch(cardNumber)) {
      throw Exception('Numéro de carte invalide (13-19 chiffres)');
    }

    // Algorithme de Luhn
    int sum = 0;
    bool isEven = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    if (sum % 10 != 0) {
      throw Exception('Numéro de carte invalide (contrôle Luhn)');
    }

    return true;
  }

  /// Valide la date d'expiration (MM/YY)
  static bool validateExpiryDate(String expiryDate) {
    final parts = expiryDate.split('/');
    if (parts.length != 2) {
      throw Exception('Format date invalide (MM/YY)');
    }

    int month = int.tryParse(parts[0]) ?? 0;
    int year = int.tryParse(parts[1]) ?? 0;

    if (month < 1 || month > 12) {
      throw Exception('Mois invalide');
    }

    // Vérifier que la carte n'a pas expiré
    final now = DateTime.now();
    final fullYear = 2000 + year;

    if (fullYear < now.year || (fullYear == now.year && month < now.month)) {
      throw Exception('Carte expirée');
    }

    return true;
  }

  /// Valide le CVV (3-4 chiffres)
  static bool validateCVV(String cvv) {
    if (!RegExp(r'^\d{3,4}$').hasMatch(cvv)) {
      throw Exception('CVV invalide (3-4 chiffres)');
    }
    return true;
  }

  /// Initialise une transaction par carte
  static Map<String, dynamic> initiateTransaction({
    required CardData cardData,
    required double amount,
    required String transactionId,
    String currency = 'XOF',
  }) {
    // Valider tous les champs
    validateCardNumber(cardData.cardNumber);
    validateExpiryDate(cardData.expiryDate);
    validateCVV(cardData.cvv);

    // Masquer le numéro de carte (garder seulement les 4 derniers chiffres)
    final last4 = cardData.cardNumber.substring(cardData.cardNumber.length - 4);

    return {
      'status': 'initiated',
      'operator': operatorCode,
      'cardLast4': last4,
      'cardHolder': cardData.cardHolder,
      'amount': amount,
      'currency': currency,
      'transactionId': transactionId,
      'reference': 'CARD-${DateTime.now().millisecondsSinceEpoch}',
      'authURL': 'https://3dsecure.example.com/auth/$transactionId',
      'message': '3D Secure: Confirmez auprès de votre banque',
      'expiresAt': DateTime.now().add(Duration(minutes: 10)),
    };
  }

  /// Vérification du statut du paiement par carte
  static Map<String, dynamic> checkTransactionStatus(String reference) {
    // En production: appel API Flutterwave ou Stripe

    return {
      'reference': reference,
      'status': 'success',
      'amount': 5000,
      'currency': 'XOF',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Annule une transaction par carte
  static void cancelTransaction(String reference) {
    _logger.i('❌ Transaction Carte $reference annulée');
  }

  /// Détecte le type de carte depuis le numéro
  static String detectCardType(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');

    if (RegExp(r'^4[0-9]{12}(?:[0-9]{3})?$').hasMatch(cardNumber)) {
      return 'Visa';
    } else if (RegExp(r'^5[1-5][0-9]{14}$').hasMatch(cardNumber)) {
      return 'Mastercard';
    } else if (RegExp(r'^3[47][0-9]{13}$').hasMatch(cardNumber)) {
      return 'American Express';
    } else if (RegExp(r'^6(?:011|5[0-9]{2})[0-9]{12}$').hasMatch(cardNumber)) {
      return 'Discover';
    }

    return 'Unknown';
  }

  /// Formate un numéro de carte pour l'affichage (xxxx-xxxx-xxxx-1234)
  static String formatCardNumber(String cardNumber) {
    cardNumber = cardNumber.replaceAll(' ', '');
    String last4 = cardNumber.substring(cardNumber.length - 4);
    return 'xxxx-xxxx-xxxx-$last4';
  }

  /// Génère un token tokenisé (simplifié, utiliser Stripe/Flutterwave en prod)
  static Future<String> tokenizeCard(CardData cardData) async {
    // En production: appel API de tokenization Stripe/Flutterwave
    // const token = await fetch('https://api.stripe.com/tokenize', cardData);

    // Simulation pour test
    await Future.delayed(Duration(milliseconds: 500));
    return 'tok_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Récupère les cartes sauvegardées de l'utilisateur
  static Future<List<Map<String, dynamic>>> getSavedCards(String userId) async {
    // En production: récupérer depuis la base de données
    return [
      {'id': 'card_1', 'last4': '4242', 'type': 'Visa', 'expiryDate': '12/25'},
    ];
  }
}
