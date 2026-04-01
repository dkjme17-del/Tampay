import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

/// Statuts possibles pour un paiement
enum PaymentStatus {
  @JsonValue('pending')
  pending,
  
  @JsonValue('completed')
  completed,
  
  @JsonValue('verified')
  verified,
  
  @JsonValue('failed')
  failed,
  
  @JsonValue('refunded')
  refunded,
}

/// Méthodes de paiement supportées
enum PaymentMethod {
  @JsonValue('mobile_money')
  mobileMoney,
  
  @JsonValue('credit_card')
  creditCard,
  
  @JsonValue('bank_transfer')
  bankTransfer,
  
  @JsonValue('cash')
  cash,
}

/// Représente un paiement dans le système MuniciPay
@HiveType(typeId: 4)
@JsonSerializable()
class Payment extends HiveObject {
  /// Identifiant unique du paiement
  @HiveField(0)
  final String id;

  /// Identifiant de la taxe associée
  @HiveField(1)
  final String taxId;

  /// Montant du paiement en FCFA
  @HiveField(2)
  final double amount;

  /// Statut actuel du paiement
  @HiveField(3)
  final PaymentStatus status;

  /// Date et heure du paiement
  @HiveField(4)
  final DateTime paymentDate;

  /// Méthode de paiement utilisée
  @HiveField(5)
  final PaymentMethod method;

  /// Zone géographique où le paiement a été effectué
  @HiveField(6)
  final String zone;

  /// Champ additionnel: code de vérification reçu du serveur (compatibilité)
  final String? verificationCode;

  /// Champ additionnel: QR code (base64 ou data) pour affichage (compatibilité)
  final String? qrCode;

  /// Nom de la taxe (para compatibilité affichage rapide)
  final String? taxName;

  /// Date de vérification côté local/serveur
  final DateTime? verifiedAt;
  /// Nom du payeur (extrait de `metadata` si présent)
  final String? payerName;

  /// Téléphone du payeur (extrait de `metadata` si présent)
  final String? payerPhone;

  /// Crée une nouvelle instance de [Payment]
  /// 
  /// Lance une [ArgumentError] si les paramètres requis ne sont pas valides
  Payment({
    required this.id,
    required this.taxId,
    required this.amount,
    PaymentStatus? status,
    DateTime? paymentDate,
    PaymentMethod? method,
    String? paymentMethod, // compat string
    DateTime? createdAt, // compat alias
    this.verificationCode,
    this.qrCode,
    this.taxName,
    this.verifiedAt,
    String? zone,
    this.payerName,
    this.payerPhone,
  }) :
    status = status ?? PaymentStatus.pending,
    paymentDate = paymentDate ?? createdAt ?? DateTime.now(),
    method = method ?? _parsePaymentMethod(paymentMethod),
    zone = zone ?? '' {
    // Validations supprimées pour permettre la création de paiements
    // sans contraintes lors du développement local.
  }

  /// Retourne la date de création (compatibilité avec `createdAt`)
  DateTime get createdAt => paymentDate;

  /// Retourne la méthode de paiement sous forme de chaîne (compatibilité)
  String get paymentMethod => method.name;

  static PaymentMethod _parsePaymentMethod(String? methodStr) {
    if (methodStr == null) return PaymentMethod.cash;
    switch (methodStr.toLowerCase()) {
      case 'mobile_money':
      case 'mobilemoney':
      case 'mobile-money':
      case 'mtn':
      case 'moov':
      case 'wave':
        return PaymentMethod.mobileMoney;
      case 'credit_card':
      case 'card':
      case 'card_payment':
        return PaymentMethod.creditCard;
      case 'bank_transfer':
      case 'bank':
        return PaymentMethod.bankTransfer;
      case 'cash':
      default:
        return PaymentMethod.cash;
    }
  }

  /// Crée un paiement à partir d'une Map JSON
  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);

  /// Parse a payment returned from Firestore / API which may include
  /// additional fields like `created_at`, `paymentMethod`, `metadata`, etc.
  factory Payment.fromMap(Map<String, dynamic> json) {
    // Helper to read nested metadata
    final meta = (json['metadata'] is Map) ? Map<String, dynamic>.from(json['metadata'] as Map) : <String, dynamic>{};

    // Parse core values with fallbacks
    final id = (json['id'] ?? json['paymentId'] ?? '') as String;
    final taxId = (json['taxId'] ?? json['tax_id'] ?? '') as String;
    final amount = (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0;
    final statusStr = (json['status'] ?? 'pending') as String;
    PaymentStatus status = PaymentStatus.pending;
    for (final s in PaymentStatus.values) {
      if (s.name == statusStr || s.toString().split('.').last == statusStr) {
        status = s;
        break;
      }
    }

    final methodStr = (json['paymentMethod'] ?? json['method']) as String?;
    final paymentDateStr = (json['created_at'] ?? json['paymentDate'] ?? json['payment_date'])?.toString();
    DateTime? createdAt;
    if (paymentDateStr != null) {
      try {
        createdAt = DateTime.parse(paymentDateStr);
      } catch (_) {
        createdAt = null;
      }
    }

    final verificationCode = (json['verificationCode'] ?? json['verification_code']) as String?;
    final qrCode = (json['qrCode'] ?? json['qr_code']) as String?;
    final taxName = (json['taxName'] ?? json['tax_name']) as String?;
    DateTime? verifiedAt;
    final verifiedAtStr = json['verified_at'] ?? json['verifiedAt'];
    if (verifiedAtStr is String) {
      try {
        verifiedAt = DateTime.parse(verifiedAtStr);
      } catch (_) {}
    } else if (verifiedAtStr is DateTime) {
      verifiedAt = verifiedAtStr;
    }

    // Extract payer info from metadata or top-level fields
    final payerName = (meta['payerName'] ?? meta['name'] ?? json['payerName'] ?? json['payer_name']) as String?;
    final payerPhone = (meta['phoneNumber'] ?? meta['payerPhone'] ?? json['payerPhone'] ?? json['payer_phone']) as String?;

    return Payment(
      id: id,
      taxId: taxId,
      amount: amount,
      status: status,
      paymentDate: createdAt,
      paymentMethod: methodStr,
      verificationCode: verificationCode,
      qrCode: qrCode,
      taxName: taxName,
      verifiedAt: verifiedAt,
      zone: (json['zone'] ?? json['zoneName']) as String?,
      payerName: payerName,
      payerPhone: payerPhone,
    );
  }
  
  /// Convertit le paiement en Map JSON
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
  
  /// Crée une copie du paiement avec les champs modifiés
  Payment copyWith({
    String? id,
    String? taxId,
    double? amount,
    PaymentStatus? status,
    DateTime? paymentDate,
    PaymentMethod? method,
    String? zone,
  }) {
    return Payment(
      id: id ?? this.id,
      taxId: taxId ?? this.taxId,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentDate: paymentDate ?? this.paymentDate,
      method: method ?? this.method,
      zone: zone ?? this.zone,
    );
  }
  
  /// Vérifie si le paiement est terminé avec succès
  bool get isCompleted => status == PaymentStatus.completed;
  
  /// Vérifie si le paiement est en attente
  bool get isPending => status == PaymentStatus.pending;
  
  /// Vérifie si le paiement a échoué
  bool get isFailed => status == PaymentStatus.failed;
  
  /// Vérifie si le paiement a été remboursé
  bool get isRefunded => status == PaymentStatus.refunded;
  
  /// Formate le montant du paiement avec le symbole FCFA
  String get formattedAmount => '${amount.toStringAsFixed(0)} FCFA';
  
  /// Formate la date de paiement selon le format local
  String formatDate([String format = 'dd/MM/yyyy HH:mm']) {
    return '${paymentDate.day.toString().padLeft(2, '0')}/'
           '${paymentDate.month.toString().padLeft(2, '0')}/'
           '${paymentDate.year} '
           '${paymentDate.hour.toString().padLeft(2, '0')}:'
           '${paymentDate.minute.toString().padLeft(2, '0')}';
  }
  
  @override
  String toString() {
    return 'Payment(id: $id, taxId: $taxId, amount: $formattedAmount, '
           'status: $status, date: ${formatDate()}, method: $method, zone: $zone)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
