import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/sync_service.dart';
import '../services/database_service.dart';
import '../services/payment_operators/payment_operators_manager.dart';

class PaymentProvider extends ChangeNotifier {
  List<Payment> _payments = [];
  Payment? _selectedPayment;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _statistics = {};
  String? _selectedOperator;
  Map<String, dynamic>? _currentTransaction;
  final SyncService _syncService = SyncService();

  List<Payment> get payments => _payments;
  Payment? get selectedPayment => _selectedPayment;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get statistics => _statistics;
  String? get selectedOperator => _selectedOperator;
  Map<String, dynamic>? get currentTransaction => _currentTransaction;

  double get totalRevenue => _statistics['totalRevenue'] ?? 0.0;
  int get totalPayments => _statistics['totalPayments'] ?? 0;
  int get completedPayments => _statistics['completedPayments'] ?? 0;
  int get verifiedPayments => _statistics['verifiedPayments'] ?? 0;

  PaymentProvider() {
    _init();
  }

  Future<void> _init() async {
    // Essayer de charger l'utilisateur actuel
    String? userId;
    bool loadAllPayments = false;

    // 1. Essayer de récupérer l'utilisateur connecté
    try {
      final user = await _syncService.getCurrentUser();
      if (user != null) {
        if (user.role.toLowerCase() == 'admin') {
          loadAllPayments = true;
          debugPrint('Utilisateur admin trouvé: ${user.id} (chargement global des paiements)');
        } else {
          userId = user.id;
          debugPrint('Utilisateur connecté trouvé: ${user.id}');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'utilisateur: $e');
    }

    // 2. Si aucun utilisateur connecté, essayer de charger un utilisateur local
    if (userId == null) {
      try {
        final locals = await DatabaseService.getAllUsers();
        if (locals.isNotEmpty) {
          if (locals.first.role.toLowerCase() == 'admin') {
            loadAllPayments = true;
            debugPrint('Utilisateur local admin chargé: (chargement global des paiements)');
          } else {
            userId = locals.first.id;
            debugPrint('Utilisateur local chargé: $userId');
          }
        } else {
          debugPrint('Aucun utilisateur local trouvé');
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement des utilisateurs locaux: $e');
      }
    }

    // Charger les paiements et les statistiques
    try {
      await loadPayments(userId: loadAllPayments ? null : userId);
      await loadStatistics();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      _error = 'Impossible de charger les données. Veuillez réessayer.';
      notifyListeners();
    }
  }

  /// Charge les paiements pour un utilisateur spécifique ou tous les paiements locaux
  Future<void> loadPayments({String? userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (userId != null && userId.isNotEmpty) {
        // Essayer de charger depuis le service de synchronisation
        try {
          _payments = await _syncService.getUserPayments(userId);
          debugPrint(
            '${_payments.length} paiements chargés pour l\'utilisateur $userId',
          );
        } catch (e) {
          debugPrint('Erreur lors du chargement des paiements distants: $e');
          // En cas d'échec, essayer de charger les paiements locaux
          _payments = DatabaseService.getPaymentsForUser(userId);
          debugPrint(
            '${_payments.length} paiements locaux chargés pour l\'utilisateur $userId',
          );
        }
      } else {
        // Si pas d'ID utilisateur, charger tous les paiements locaux
        _payments = DatabaseService.getAllPayments();
        debugPrint('${_payments.length} paiements locaux chargés');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Impossible de charger les paiements: ${e.toString()}';
      _isLoading = false;
      debugPrint(_error!);
      notifyListeners();
    }
  }

  /// Créer un nouveau paiement avec opérateur
  Future<bool> createPaymentWithOperator({
    required String taxId,
    required double amount,
    required String operator,
    required Map<String, dynamic> operatorData,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Valider l'opérateur
      if (!PaymentOperatorsManager.supportedOperators.contains(operator)) {
        throw Exception('Opérateur non supporté');
      }

      // Valider le montant
      if (!PaymentOperatorsManager.validateAmount(operator, amount)) {
        final info = PaymentOperatorsManager.getOperatorInfo(operator);
        throw Exception(
          'Montant doit être entre ${info?['minAmount']} et ${info?['maxAmount']} XOF',
        );
      }

      // Normalize operator selection and compute canonical payment method
      _selectedOperator = operator;
      final methodKey = _mapOperatorToMethod(operator);

      // Créer la transaction localement
      final transaction = PaymentOperatorsManager.initiateTransaction(
        operator: operator,
        data: {
          ...operatorData,
          'amount': amount,
          'transactionId': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      _currentTransaction = transaction;

      // Créer le paiement via l'API (ou simulateur pour CI)
      final response = await _syncService.createPayment(
        taxId: taxId,
        amount: amount,
        paymentMethod: methodKey,
        operatorData: {...operatorData, 'amount': amount},
      );

      // Récupérer les informations de la taxe de manière asynchrone
      final tax = await DatabaseService.getTaxById(taxId);

      // Créer le paiement initial
      final payment = Payment(
        id: response['paymentId']?.toString() ?? '',
        taxId: taxId,
        amount: amount,
        paymentMethod: methodKey,
        status: PaymentStatus.pending,
        verificationCode: response['verificationCode']?.toString(),
        qrCode: response['qrCode']?.toString(),
        taxName: tax?.name,
        zone: tax?.zone ?? (operatorData['zone'] as String?) ?? '',
        payerName: (operatorData['payerName'] as String?) ?? (operatorData['name'] as String?),
        payerPhone: (operatorData['phoneNumber'] as String?) ?? (operatorData['payerPhone'] as String?),
        createdAt: DateTime.now(),
      );
      _selectedPayment = payment;

      // Si c'est une réponse du simulateur local, marquer comme complété
      final pid = (response['paymentId'] ?? '').toString();
      final qr = (response['qrCode'] ?? '').toString();
      final isSimulator = pid.startsWith('sim-') || qr.startsWith('SIMQR:');

      if (isSimulator) {
        final completed = Payment(
          id: payment.id,
          taxId: payment.taxId,
          amount: payment.amount,
          paymentMethod: payment.paymentMethod,
          status: PaymentStatus.completed,
          verificationCode: payment.verificationCode,
          qrCode: payment.qrCode,
          taxName: payment.taxName,
          zone: payment.zone,
          payerName: (operatorData['payerName'] as String?) ?? (operatorData['name'] as String?),
          payerPhone: (operatorData['phoneNumber'] as String?) ?? (operatorData['payerPhone'] as String?),
          createdAt: payment.createdAt,
          verifiedAt: DateTime.now(),
        );
        _selectedPayment = completed;

        // Persister localement
        try {
          await DatabaseService.addPayment(completed);
          debugPrint('Paiement simulé enregistré avec succès: ${completed.id}');
        } catch (_) {}
      }

      // Pour tous les paiements (simulateur ou distant), essayer de les persister
      try {
        final currentUser = await _syncService.getCurrentUser();
        if (currentUser != null) {
          await DatabaseService.addPaymentForUser(currentUser.id, _selectedPayment!);
        } else {
          await DatabaseService.addPayment(_selectedPayment!);
        }
      } catch (e) {
        debugPrint('Impossible d\'enregistrer localement le paiement: $e');
      }

      // Recharger l'historique et les statistiques pour refléter le nouveau paiement
      try {
        await Future.wait([loadPayments(), loadStatistics()]);
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Map operator or display label to canonical payment method key
  String _mapOperatorToMethod(String op) {
    final l = op.toLowerCase();
    if (l.contains('mobile') || l.contains('mtn') || l.contains('moov') || l.contains('wave')) return 'mobile_money';
    if (l.contains('virement') || l.contains('bank') || l.contains('transfer')) return 'bank_transfer';
    if (l.contains('carte') || l.contains('card') || l.contains('credit')) return 'credit_card';
    if (l.contains('cash')) return 'cash';
    // Fallback: normalize separators
    return l.replaceAll(' ', '_');
  }

  /// Sélectionner un opérateur
  void selectOperator(String operator) {
    _selectedOperator = operator;
    notifyListeners();
  }

  /// Obtenir les opérateurs disponibles pour un pays
  List<String> getAvailableOperators(String countryCode) {
    return PaymentOperatorsManager.getAvailableOperators(countryCode);
  }

  /// Calculer les frais de transaction
  double calculateFees(double amount) {
    if (_selectedOperator == null) return 0;
    return PaymentOperatorsManager.calculateFees(_selectedOperator!, amount);
  }

  /// Calculer le montant total
  double calculateTotal(double amount) {
    if (_selectedOperator == null) return amount;
    return PaymentOperatorsManager.calculateTotal(_selectedOperator!, amount);
  }

  /// Obtenir les informations de l'opérateur
  Map<String, dynamic>? getOperatorInfo(String operator) {
    return PaymentOperatorsManager.getOperatorInfo(operator);
  }

  /// Vérifier le statut d'une transaction
  Future<Map<String, dynamic>> checkTransactionStatus(String reference) async {
    if (_selectedOperator == null) {
      throw Exception('Aucun opérateur sélectionné');
    }

    try {
      return PaymentOperatorsManager.checkTransactionStatus(
        _selectedOperator!,
        reference,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Créer un nouveau paiement
  Future<bool> createPayment({
    required String taxId,
    required double amount,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Essayer de créer le paiement à distance avec délai d'attente
      Map<String, dynamic> response;
      try {
        response = await _syncService
            .createPayment(
              taxId: taxId,
              amount: amount,
              paymentMethod: paymentMethod,
            )
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Erreur lors de la création du paiement distant: $e');
        // Créer un paiement simulé localement en cas d'échec
        final localId = 'sim-${DateTime.now().millisecondsSinceEpoch}';
        final verificationCode = (100000 + (localId.hashCode % 899999))
            .toString();
        response = {
          'paymentId': localId,
          'verificationCode': verificationCode,
          'qrCode': 'SIMQR:$localId',
          'isSimulated': true,
        };
      }

      // Récupérer les informations de la taxe de manière asynchrone
      final tax = await DatabaseService.getTaxById(taxId);

      // Créer le paiement initial
      final payment = Payment(
        id: response['paymentId']?.toString() ?? '',
        taxId: taxId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: PaymentStatus.pending,
        verificationCode: response['verificationCode']?.toString(),
        qrCode: response['qrCode']?.toString(),
        taxName: tax?.name,
        zone: tax?.zone ?? (response['zone'] as String?) ?? '',
        createdAt: DateTime.now(),
      );
      _selectedPayment = payment;

      // Vérifier si c'est une réponse simulée
      final isSimulated =
          response['isSimulated'] == true ||
          (response['paymentId']?.toString() ?? '').startsWith('sim-') ||
          (response['qrCode']?.toString() ?? '').startsWith('SIMQR:');

      if (isSimulated) {
        final completed = Payment(
          id: payment.id,
          taxId: payment.taxId,
          amount: payment.amount,
          paymentMethod: payment.paymentMethod,
          status: PaymentStatus.completed,
          verificationCode: payment.verificationCode,
          qrCode: payment.qrCode,
          taxName: payment.taxName,
          zone: payment.zone,
          createdAt: payment.createdAt,
          verifiedAt: DateTime.now(),
        );
        _selectedPayment = completed;

        try {
          await DatabaseService.addPayment(completed);
          debugPrint('Paiement simulé enregistré avec succès: ${completed.id}');
        } catch (e) {
          debugPrint('Erreur lors de l\'enregistrement du paiement simulé: $e');
          // Ne pas échouer complètement en cas d'erreur d'enregistrement local
        }
      }

      // Mettre à jour l'état et recharger les données
      _isLoading = false;
      await Future.wait([loadPayments(), loadStatistics()]);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Vérifier un paiement (admin)
  Future<bool> verifyPayment(
    String paymentId, {
    String? verificationCode,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final payment = await _syncService.verifyPayment(
        paymentId,
        verificationCode: verificationCode,
      );

      // Mettre à jour le paiement dans la liste
      final index = _payments.indexWhere((p) => p.id == paymentId);
      if (index >= 0) {
        _payments[index] = payment;
      }

      _isLoading = false;
      await loadStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Supprimer un paiement pour l'utilisateur courant
  Future<bool> deletePayment(String paymentId, {bool permanent = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Try to determine current user
      String? userId;
      try {
        final user = await _syncService.getCurrentUser();
        userId = user?.id;
      } catch (_) {}

      if (permanent) {
        // Force global deletion
        await DatabaseService.deletePayment(paymentId);
      } else {
        if (userId != null) {
          await DatabaseService.deletePaymentForUser(userId, paymentId);
        } else {
          // If no user context, delete globally
          await DatabaseService.deletePayment(paymentId);
        }
      }

      // Update local list
      _payments.removeWhere((p) => p.id == paymentId);
      _isLoading = false;
      await loadStatistics();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Charger les statistiques
  Future<void> loadStatistics() async {
    try {
      _statistics = await _syncService.getPaymentStatistics();
      notifyListeners();
    } catch (e) {
      // Erreur chargement stats - utiliser les valeurs locales
    }
  }

  /// Définir le paiement sélectionné
  void setSelectedPayment(Payment payment) {
    _selectedPayment = payment;
    notifyListeners();
  }

  /// Récupérer les paiements par statut
  /// Accepts either a `PaymentStatus` enum or a `String` (e.g. 'completed').
  List<Payment> getPaymentsByStatus(dynamic status) {
    if (status is PaymentStatus) {
      return _payments.where((p) => p.status == status).toList();
    }
    if (status is String) {
      return _payments.where((p) => p.status.name == status).toList();
    }
    throw ArgumentError('status must be PaymentStatus or String');
  }

  /// Récupérer les paiements par zone
  List<Payment> getPaymentsByZone(String zone) {
    return _payments.where((p) => p.zone == zone).toList();
  }

  /// Récupérer les paiements d'une date
  List<Payment> getPaymentsForDate(DateTime date) {
    return _payments.where((p) {
      return p.createdAt.year == date.year &&
          p.createdAt.month == date.month &&
          p.createdAt.day == date.day;
    }).toList();
  }

  /// Effacer le message d'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
