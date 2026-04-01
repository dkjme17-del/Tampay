import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/payment.dart';
import 'qrcode_service.dart';
import '../models/tax.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'payment_simulator.dart';
import 'payment_operators/payment_operators_manager.dart';

/// Service de synchronisation entre Hive (local) et API (remote)
///
/// Stratégie:
/// - Si connecté → récupérer depuis API et mettre en cache dans Hive
/// - Si déconnecté → utiliser Hive comme cache
/// - Sync automatique quand la connexion revient
class SyncService {
  static final SyncService _instance = SyncService._internal();
  late Connectivity _connectivity;
  bool _isOnline = true;

  // File d'attente de synchronisation (pour mode offline)
  final List<_SyncQueueItem> _syncQueue = [];
  bool _isSyncing = false;

  factory SyncService() {
    return _instance;
  }

  SyncService._internal() {
    _connectivity = Connectivity();
    _initConnectivityListener();
  }

  /// Initialiser le listener de connectivité
  void _initConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      // Si reconnecté, synchroniser
      if (!wasOnline && _isOnline) {
        syncOfflineQueue();
      }
    });
  }

  /// Vérifier si on est connecté
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ==================== TAXES ====================

  /// Récupérer les taxes (avec sync automatique)
  Future<List<Tax>> getTaxes({String? category, String? zone}) async {
    try {
      if (_isOnline) {
        // Récupérer depuis API et mettre en cache
        final taxes = await ApiService.getTaxes(category: category, zone: zone);
        // Mettre à jour le cache local
        DatabaseService.clearTaxes();
        for (final tax in taxes) {
          DatabaseService.addTax(tax);
        }
        return taxes;
      } else {
        // Mode offline: utiliser le cache Hive
        var taxes = DatabaseService.getAllTaxes();
        if (category != null) {
          taxes = taxes.where((t) => t.category == category).toList();
        }
        if (zone != null) {
          taxes = taxes.where((t) => t.zone == zone).toList();
        }
        return taxes;
      }
    } catch (e) {
      // Fallback sur le cache Hive
      var taxes = DatabaseService.getAllTaxes();
      if (category != null) {
        taxes = taxes.where((t) => t.category == category).toList();
      }
      if (zone != null) {
        taxes = taxes.where((t) => t.zone == zone).toList();
      }
      return taxes;
    }
  }

  /// Récupérer une taxe spécifique
  Future<Tax?> getTax(String taxId) async {
    try {
      if (_isOnline) {
        final tax = await ApiService.getTax(taxId);
        DatabaseService.updateTax(tax);
        return tax;
      } else {
        return DatabaseService.getTaxById(taxId);
      }
    } catch (e) {
      return DatabaseService.getTaxById(taxId);
    }
  }

  // ==================== USERS ====================

  /// Enregistrer un nouvel utilisateur
  Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    String? password,
    String? activity,
    String? activityZone,
  }) async {
    try {
      if (_isOnline) {
        final response = await ApiService.register(phone: phone, name: name, password: password, activity: activity, activityZone: activityZone);

        // Sauvegarder l'utilisateur localement
        final user = User.fromJson(response['user']);
        DatabaseService.addUser(user);

        // Sauvegarder le token
        final token = response['token'];
        if (token != null) {
          ApiService.setAuthToken(token);
          DatabaseService.saveAuthToken(token);
        }

        return response;
      } else {
        // Mode offline: créer localement
        final user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          phone: phone,
          role: 'citizen',
              activity: activity,
              activityZone: activityZone,
              registrationDate: DateTime.now(),
              // local-only marker when password is set
        );
        DatabaseService.addUser(user);
        // Persist last user id so session can be restored offline
        try {
          await DatabaseService.saveLastUserId(user.id);
        } catch (_) {}
        return {'user': user.toJson(), 'token': null};
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Se connecter
  Future<Map<String, dynamic>> login({required String phone, String? password}) async {
    try {
      if (_isOnline) {
        if (password == null) {
          // The remote API requires a password for online login (no SMS flow supported).
          throw Exception('Connexion en ligne nécessite un mot de passe. Utilisez la méthode login avec mot de passe.');
        }
        final response = await ApiService.login(phone: phone, password: password);

        // Sauvegarder l'utilisateur localement
        final user = User.fromJson(response['user']);
        DatabaseService.addUser(user);

        // Sauvegarder le token
        final token = response['token'];
        if (token != null) {
          ApiService.setAuthToken(token);
          DatabaseService.saveAuthToken(token);
        }

        return response;
      } else {
        // Mode offline: chercher localement
        final user = DatabaseService.getUserByPhone(phone);
        if (user != null) {
          try {
            await DatabaseService.saveLastUserId(user.id);
          } catch (_) {}
          return {'user': user.toJson(), 'token': null};
        } else {
          throw Exception('Utilisateur non trouvé en mode offline');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer l'utilisateur courant
  Future<User?> getCurrentUser() async {
    try {
      if (_isOnline) {
        final user = await ApiService.getCurrentUser();
        DatabaseService.addUser(user);
        return user;
      } else {
        // Chercher l'utilisateur du token en cache (offline fallback)
        try {
          final token = DatabaseService.getAuthToken();
          if (token != null) {
            final locals = await DatabaseService.getAllUsers();
            try {
              return locals.firstWhere((u) => u.id == token);
            } catch (_) {
              return null;
            }
          }
        } catch (_) {}
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==================== PAYMENTS ====================

  /// Créer un paiement
  Future<Map<String, dynamic>> createPayment({
    required String taxId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? operatorData,
  }) async {
    try {
      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taxId: taxId,
        amount: amount,
        paymentMethod: paymentMethod,
        status: PaymentStatus.pending,
        createdAt: DateTime.now(),
      );

      // Determine zone: prefer tax.zone, then current user zone, else fallback to 'Unknown'
      String resolvedZone = '';
      try {
        final tax = await DatabaseService.getTaxById(taxId);
        if (tax != null && tax.zone.isNotEmpty) {
          resolvedZone = tax.zone;
        }
      } catch (_) {}
      if (resolvedZone.isEmpty) {
        try {
          final locals = await DatabaseService.getAllUsers();
          if (locals.isNotEmpty && locals.first.zone != null && locals.first.zone!.isNotEmpty) {
            resolvedZone = locals.first.zone!;
          }
        } catch (_) {}
      }
      if (resolvedZone.isEmpty) resolvedZone = 'Unknown';

      if (_isOnline) {
        // If operatorData is provided and phone is CI, simulate locally
        final phone = operatorData != null
            ? (operatorData['phoneNumber'] as String? ?? '')
            : '';
        final country = PaymentOperatorsManager.detectCountryFromPhone(phone);

        if (operatorData != null && country == 'CI') {
          final response = PaymentSimulator.simulatePayment(
            operator: paymentMethod,
            phoneNumber: phone,
            amount: amount,
            currency: operatorData['currency'] ?? 'XOF',
          );

          // Persist simulated payment locally
          final paymentId = response['paymentId'] ?? payment.id;
          final updatedPayment = Payment(
            id: paymentId,
            taxId: taxId,
            amount: amount,
            paymentMethod: paymentMethod,
            status: PaymentStatus.pending,
            qrCode: response['qrCode'],
            verificationCode: response['verificationCode'],
            createdAt: DateTime.now(),
            zone: resolvedZone,
            // Mobile Money payer info (used by admin/citizen history UI).
            payerName: (operatorData['payerName'] as String?) ??
                (operatorData['name'] as String?),
            payerPhone: phone.isNotEmpty ? phone : null,
          );

          DatabaseService.addPayment(updatedPayment);
          return response;
        }

        // Otherwise create via real API
        final metadata = (() {
          // Only send payer metadata for Mobile Money-like flows.
          final phoneNumber = operatorData?['phoneNumber'] as String? ??
              operatorData?['payerPhone'] as String?;
          if (phoneNumber == null || phoneNumber.isEmpty) return null;

          final payerName = operatorData?['payerName'] as String? ??
              operatorData?['name'] as String?;

          return <String, dynamic>{
            'phoneNumber': phoneNumber,
            'payerPhone': phoneNumber,
            if (payerName != null && payerName.isNotEmpty) 'payerName': payerName,
            if (payerName != null && payerName.isNotEmpty) 'name': payerName,
          };
        })();

        final response = await ApiService.createPayment(
          taxId: taxId,
          amount: amount,
          paymentMethod: paymentMethod,
          metadata: metadata,
        );

        // Mettre à jour localement avec la réponse
        final paymentId = response['paymentId'] ?? payment.id;
        final updatedPayment = Payment(
          id: paymentId,
          taxId: taxId,
          amount: amount,
          paymentMethod: paymentMethod,
          status: PaymentStatus.pending,
          qrCode: response['qrCode'],
          verificationCode: response['verificationCode'],
          createdAt: DateTime.now(),
          zone: resolvedZone,
          // Mobile Money payer info (used by admin/citizen history UI).
          payerName: (operatorData?['payerName'] as String?) ??
              (operatorData?['name'] as String?),
          payerPhone: (operatorData?['phoneNumber'] as String?) ??
              (operatorData?['payerPhone'] as String?),
        );

        // Tenter d'obtenir l'utilisateur courant pour associer le paiement
        String? userId;
        try {
          final user = await ApiService.getCurrentUser();
          userId = user.id;
        } catch (_) {}

        // Fallback: prefer last saved user id (session), otherwise try local users
        if (userId == null) {
          try {
            final last = DatabaseService.getLastUserId();
            if (last != null) {
              userId = last;
            } else {
              final locals = await DatabaseService.getAllUsers();
              if (locals.isNotEmpty) userId = locals.first.id;
            }
          } catch (_) {}
        }

        if (userId != null) {
          await DatabaseService.addPaymentForUser(userId, updatedPayment);
        } else {
          await DatabaseService.addPayment(updatedPayment);
        }
        return response;
      } else {
        // Mode offline: générer un QR code local et créer localement
        final qr = QRCodeService.generateQRCode(
          payment.id,
          payment.taxId,
          payment.amount,
          payment.zone,
          payment.createdAt,
        );

        final updatedPayment = Payment(
          id: payment.id,
          taxId: payment.taxId,
          amount: payment.amount,
          paymentMethod: payment.paymentMethod,
          status: payment.status,
          qrCode: qr,
          verificationCode: 'offline',
          zone: resolvedZone,
          createdAt: payment.createdAt,
          verifiedAt: payment.verifiedAt,
          // Mobile Money payer info (used by admin/citizen history UI).
          payerName: (operatorData?['payerName'] as String?) ??
              (operatorData?['name'] as String?),
          payerPhone: (operatorData?['phoneNumber'] as String?) ??
              (operatorData?['payerPhone'] as String?),
        );

        // Associer le paiement offline à l'utilisateur local (si connu)
        String? userId;
        try {
          userId = DatabaseService.getLastUserId();
        } catch (_) {}
        if (userId == null) {
          final locals = await DatabaseService.getAllUsers();
          if (locals.isNotEmpty) userId = locals.first.id;
        }
        if (userId != null) {
          await DatabaseService.addPaymentForUser(userId, updatedPayment);
        } else {
          await DatabaseService.addPayment(updatedPayment);
        }
        _addToSyncQueue(
          _SyncQueueItem(
            type: 'payment',
            action: 'create',
            data: updatedPayment.toJson(),
          ),
        );

        return {
          'paymentId': updatedPayment.id,
          'qrCode': updatedPayment.qrCode,
          'verificationCode': updatedPayment.verificationCode,
        };
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer l'historique des paiements
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      if (_isOnline) {
        final payments = await ApiService.getUserPayments(userId);

        // If Firestore docs exist but the `user_id` field is missing/mismatched,
        // the query can return an empty list. Fall back to the local cache so
        // the history screen can still display payments.
        if (payments.isEmpty) {
          final local = DatabaseService.getPaymentsForUser(userId);
          // Keep cache in sync with local state.
          return local;
        }

        // Mettre à jour le cache
        for (final payment in payments) {
          DatabaseService.addPayment(payment);
        }
        return payments;
      } else {
        return DatabaseService.getPaymentsForUser(userId);
      }
    } catch (e) {
      return DatabaseService.getPaymentsForUser(userId);
    }
  }

  /// Vérifier un paiement (admin)
  Future<Payment> verifyPayment(
    String paymentId, {
    String? verificationCode,
  }) async {
    try {
      if (_isOnline) {
        final payment = await ApiService.verifyPayment(
          paymentId,
          verificationCode: verificationCode,
        );
        DatabaseService.updatePayment(payment);
        return payment;
      } else {
        // Mode offline: marquer localement
        var payment = DatabaseService.getPaymentById(paymentId);
        if (payment != null) {
          payment = Payment(
            id: payment.id,
            taxId: payment.taxId,
            amount: payment.amount,
            paymentMethod: payment.paymentMethod,
            status: PaymentStatus.completed,
            qrCode: payment.qrCode,
            verificationCode: payment.verificationCode,
            createdAt: payment.createdAt,
            verifiedAt: DateTime.now(),
          );
          DatabaseService.updatePayment(payment);
          _addToSyncQueue(
            _SyncQueueItem(
              type: 'payment',
              action: 'verify',
              data: {
                'paymentId': paymentId,
                'verificationCode': verificationCode,
              },
            ),
          );
          return payment;
        }
        throw Exception('Paiement non trouvé');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les stats (admin)
  Future<Map<String, dynamic>> getPaymentStatistics() async {
    try {
      if (_isOnline) {
        return await ApiService.getPaymentStatistics();
      } else {
        // Calculer localement
        final payments = DatabaseService.getAllPayments();
        final completed = payments
          .where((p) => p.status == PaymentStatus.completed)
          .toList();
        final verified = payments.where((p) => p.verifiedAt != null).toList();

        return {
          'totalRevenue': completed.fold<double>(0, (sum, p) => sum + p.amount),
          'totalPayments': payments.length,
          'completedPayments': completed.length,
          'verifiedPayments': verified.length,
        };
      }
    } catch (e) {
      return {
        'totalRevenue': 0,
        'totalPayments': 0,
        'completedPayments': 0,
        'verifiedPayments': 0,
      };
    }
  }

  // ==================== SYNCHRONISATION OFFLINE ====================

  /// Ajouter un élément à la file d'attente de sync
  void _addToSyncQueue(_SyncQueueItem item) {
    _syncQueue.add(item);
  }

  /// Synchroniser la file d'attente quand la connexion revient
  Future<void> syncOfflineQueue() async {
    if (_isSyncing || _syncQueue.isEmpty || !_isOnline) {
      return;
    }

    _isSyncing = true;

    final itemsToRemove = <_SyncQueueItem>[];

    for (final item in _syncQueue) {
      try {
        if (item.type == 'payment' && item.action == 'create') {
          // Renvoyez le paiement à l'API
          await ApiService.createPayment(
            taxId: item.data['taxId'],
            amount: item.data['amount'],
            paymentMethod: item.data['paymentMethod'],
          );
          itemsToRemove.add(item);
        } else if (item.type == 'payment' && item.action == 'verify') {
          // Vérifiez le paiement via l'API
          await ApiService.verifyPayment(
            item.data['paymentId'],
            verificationCode: item.data['verificationCode'],
          );
          itemsToRemove.add(item);
        }
      } catch (e) {
        // Erreur sync - continuer avec les autres éléments
      }
    }

    // Supprimer les éléments synchronisés
    for (final item in itemsToRemove) {
      _syncQueue.remove(item);
    }

    _isSyncing = false;
  }

  /// Obtenir la file de sync (pour le debug)
  /// Retourne une représentation simple des éléments pour éviter d'exposer
  /// le type privé `_SyncQueueItem` dans l'API publique.
  List<Map<String, dynamic>> getSyncQueue() => _syncQueue
      .map((i) => {
            'type': i.type,
            'action': i.action,
            'data': i.data,
            'timestamp': i.timestamp.toIso8601String(),
          })
      .toList();

  /// Vider la file de sync
  void clearSyncQueue() => _syncQueue.clear();
}

/// Classe interne pour représenter un élément en file d'attente
class _SyncQueueItem {
  final String type; // 'payment', 'tax', etc.
  final String action; // 'create', 'update', 'delete', 'verify'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _SyncQueueItem({
    required this.type,
    required this.action,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '$type:$action at ${timestamp.toIso8601String()}';
}
