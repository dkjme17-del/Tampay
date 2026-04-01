import 'dart:math';

/// Petit simulateur de paiements réservé à la Côte d'Ivoire (pré-prod/test)
class PaymentSimulator {
  /// Simule un paiement et retourne les données attendues par l'app
  /// Lance une exception si le téléphone n'est pas Ivoirien (+225)
  static Map<String, dynamic> simulatePayment({
    required String operator,
    required String phoneNumber,
    required double amount,
    String currency = 'XOF',
  }) {
    // Vérifier préfixe +225
    final normalized = phoneNumber.replaceAll(' ', '');
    if (!normalized.startsWith('+225')) {
      throw Exception("Simulation disponible uniquement pour la Côte d'Ivoire (+225)");
    }

    final rnd = Random();
    final paymentId = 'sim-${DateTime.now().millisecondsSinceEpoch}-${rnd.nextInt(9999)}';
    final verificationCode = (100000 + rnd.nextInt(899999)).toString();
    final qrCode = 'SIMQR:${paymentId}:${verificationCode}';

    return {
      'paymentId': paymentId,
      'qrCode': qrCode,
      'verificationCode': verificationCode,
      'operator': operator,
      'paymentMethod': operator,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'currency': currency,
      'status': 'pending',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
