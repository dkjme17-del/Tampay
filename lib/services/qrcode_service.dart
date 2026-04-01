import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

class QRCodeService {
  static const uuid = Uuid();

  /// Génère un QR code pour un paiement
  static String generateQRCode(
    String paymentId,
    String taxId,
    double amount,
    String zone,
    DateTime paymentDate,
  ) {
    final data = {
      'payment_id': paymentId,
      'tax_id': taxId,
      'amount': amount,
      'zone': zone,
      'date': paymentDate.toIso8601String(),
      'verification_code': _generateVerificationCode(paymentId),
    };

    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  /// Vérifie un QR code
  static Map<String, dynamic>? decodeQRCode(String qrCodeData) {
    try {
      final decoded = utf8.decode(base64Decode(qrCodeData));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Génère un code de vérification unique
  static String _generateVerificationCode(String paymentId) {
    return md5
        .convert(utf8.encode(paymentId + DateTime.now().toString()))
        .toString()
        .substring(0, 8);
  }

  /// Génère un ID de paiement unique
  static String generatePaymentId() {
    return uuid.v4();
  }
}
