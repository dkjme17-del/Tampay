/// Fichier d'exports centralisé pour le système de paiement
///
/// Exporte tous les opérateurs de paiement, gestionnaires et modèles
/// pour simplifier les imports dans l'application

// Opérateurs de paiement
export 'orange_money_service.dart';
export 'wave_service.dart';
export 'moov_money_service.dart';
export 'mtn_money_service.dart';
export 'card_payment_service.dart'; // Exporte aussi CardData

// Gestionnaire centralisé
export 'payment_operators_manager.dart';

/// Utilisation:
/// import 'package:applicationweb/services/payment_operators/payment_system_exports.dart';
///
/// Ensuite vous avez accès à:
/// - PaymentOperatorsManager
/// - CardData
/// - CardPaymentService
/// - WaveService
/// - OrangeMoneyService
/// - etc.
