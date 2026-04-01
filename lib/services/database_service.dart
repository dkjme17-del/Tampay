import 'dart:async';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import '../models/tax.dart';
import '../models/payment.dart';

class DatabaseService {
  static final Logger _logger = Logger();
  static bool _isInitialized = false;

  /// Initialise la base de données Hive et ouvre toutes les boxes nécessaires.
  /// Lance une exception si l'initialisation échoue.
  static Future<void> initDatabase() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive for local persistence
      try {
        await Hive.initFlutter();
        await Hive.openBox('users');
        await Hive.openBox('payments');
        await Hive.openBox('settings');
        _logger.i('Hive initialisé et boxes ouvertes');
        // Load caches from Hive first (local persistence)
        _loadCachesFromHive();
      } catch (h) {
        _logger.w('Hive non disponible: $h');
      }

      // Initialize Firebase if not already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _logger.i('Firebase initialisé');

      // Load remote collections into in-memory cache so synchronous getters keep working
      await _loadCachesFromFirestore();
      // Restore auth token from settings cache if present
      try {
        final t = _settingsCache['last_token'];
        if (t is String && t.isNotEmpty) {
          _authToken = t;
        }
      } catch (_) {}

      _isInitialized = true;
      _logger.i('DatabaseService initialisé (Firestore-only)');
    } catch (e, stackTrace) {
      _logger.e(
        'Erreur lors de l\'initialisation de la base de données',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // In-memory caches (remplacent les boxes Hive)
  static final Map<String, User> _usersCache = {};
  static final Map<String, Tax> _taxesCache = {};
  static final Map<String, Payment> _paymentsCache = {};
  static final Map<String, dynamic> _settingsCache = {};
  static String? _authToken;

  static Future<void> _loadCachesFromFirestore() async {
    try {
      final fs = FirebaseFirestore.instance;

      final taxesSnap = await fs.collection('taxes').get();
      for (final d in taxesSnap.docs) {
        final m = {...d.data(), 'id': d.id};
        final tax = Tax.fromJson(m);
        _taxesCache[tax.id] = tax;
      }

      final usersSnap = await fs.collection('users').get();
      for (final d in usersSnap.docs) {
        final m = {...d.data(), 'id': d.id};
        final u = User.fromJson(m);
        _usersCache[u.id] = u;
      }

      final paymentsSnap = await fs.collection('payments').get();
      // Build payments cache and payments_by_user mapping when possible
      final Map<String, List<String>> paymentsByUser = Map<String, List<String>>.from(_settingsCache['payments_by_user'] ?? {});
      for (final d in paymentsSnap.docs) {
        final raw = d.data() as Map<String, dynamic>;
        final m = {...raw, 'id': d.id};
        final p = Payment.fromMap(m);
        _paymentsCache[p.id] = p;
        try {
          final uid = (raw['user_id'] ?? raw['userId']) as String?;
          if (uid != null && uid.isNotEmpty) {
            final list = paymentsByUser[uid] ?? <String>[];
            if (!list.contains(p.id)) list.add(p.id);
            paymentsByUser[uid] = list;
          }
        } catch (_) {}
      }
      if (paymentsByUser.isNotEmpty) {
        _settingsCache['payments_by_user'] = paymentsByUser;
      }

      final settingsDoc = await fs.collection('settings').doc('app').get();
      if (settingsDoc.exists) {
        _settingsCache.addAll(settingsDoc.data() ?? {});
      }
    } catch (e, st) {
      _logger.w('Erreur lors du chargement initial depuis Firestore: $e', error: e, stackTrace: st);
    }
  }
  
  static Future<void> _saveUserToHive(User user) async {
    try {
      final box = Hive.box('users');
      await box.put(user.id, user.toJson());
    } catch (_) {}
  }

  static Future<void> _savePaymentToHive(Payment p) async {
    try {
      final box = Hive.box('payments');
      final map = p.toJson();
      // Attach last_user_id if present so we can filter per-user later
      try {
        final last = _settingsCache['last_user_id'] as String? ?? null;
        if (last != null && last.isNotEmpty) map['userId'] = last;
      } catch (_) {}
      await box.put(p.id, map);
    } catch (_) {}
  }

  static Future<void> _saveSettingsToHive() async {
    try {
      final box = Hive.box('settings');
      for (final e in _settingsCache.entries) {
        await box.put(e.key, e.value);
      }
    } catch (_) {}
  }

  // Remove any keys with null values from a map before sending to Firestore
  static Map<String, dynamic> _filterNulls(Map<String, dynamic> src) {
    final out = <String, dynamic>{};
    for (final e in src.entries) {
      if (e.value != null) out[e.key] = e.value;
    }
    return out;
  }

  static Future<void> saveLastUserId(String id) async {
    try {
      _settingsCache['last_user_id'] = id;
      await _saveSettingsToHive();
      if (_firestoreAvailable) {
        try {
          await _fs.collection('settings').doc('app').set({'last_user_id': id}, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (_) {}
  }

  static String? getLastUserId() {
    _checkInitialized();
    try {
      final v = _settingsCache['last_user_id'];
      if (v is String) return v;
    } catch (_) {}
    return null;
  }

  static void _loadCachesFromHive() {
    try {
      final usersBox = Hive.box('users');
      final paymentsBox = Hive.box('payments');
      final settingsBox = Hive.box('settings');

      // Users
      for (final key in usersBox.keys) {
        final raw = usersBox.get(key);
        if (raw is Map<String, dynamic>) {
          final u = User.fromJson(Map<String, dynamic>.from(raw));
          _usersCache[u.id] = u;
        }
      }

      // Payments
      for (final key in paymentsBox.keys) {
        final raw = paymentsBox.get(key);
        if (raw is Map<String, dynamic>) {
          final p = Payment.fromMap(Map<String, dynamic>.from(raw));
          _paymentsCache[p.id] = p;
        }
      }

      // Settings
      final rawSettings = settingsBox.toMap();
      _settingsCache.clear();
      rawSettings.forEach((k, v) {
        _settingsCache[k.toString()] = v;
      });
      _logger.i('Caches chargés depuis Hive');
    } catch (e, st) {
      _logger.w('Erreur chargement caches Hive: $e', error: e, stackTrace: st);
    }
  }
      static bool get _firestoreAvailable => Firebase.apps.isNotEmpty;

      static FirebaseFirestore get _fs => FirebaseFirestore.instance;

      /// Fermeture et nettoyage des caches
      static Future<void> close() async {
        _usersCache.clear();
        _taxesCache.clear();
        _paymentsCache.clear();
        _settingsCache.clear();
        _authToken = null;
        _isInitialized = false;
        _logger.i('DatabaseService fermé (cache nettoyé)');
      }

      // Accesseurs de cache (garde compatibilité avec usages synchrones)
      static Map<String, User> get usersCache {
        _checkInitialized();
        return _usersCache;
      }

      static Map<String, Tax> get taxesCache {
        _checkInitialized();
        return _taxesCache;
      }

      static Map<String, Payment> get paymentsCache {
        _checkInitialized();
        return _paymentsCache;
      }

      static Map<String, dynamic> get settingsCache {
        _checkInitialized();
        return _settingsCache;
      }

      // -------------------- Taxes --------------------
      static Future<void> clearTaxes() async {
        _checkInitialized();
        _taxesCache.clear();
        if (_firestoreAvailable) {
          try {
            final snap = await _fs.collection('taxes').get();
            for (final d in snap.docs) {
              await _fs.collection('taxes').doc(d.id).delete();
            }
          } catch (_) {}
        }
      }

      static Future<void> addTax(Tax tax) async {
        _checkInitialized();
        _taxesCache[tax.id] = tax;
        if (_firestoreAvailable) {
          try {
            await _fs.collection('taxes').doc(tax.id).set(tax.toJson());
          } catch (_) {}
        }
      }

      static List<Tax> getAllTaxes() {
        _checkInitialized();
        if (_firestoreAvailable) {
          _syncTaxesFromFirestore();
        }
        return _taxesCache.values.toList();
      }

      static Future<void> _syncTaxesFromFirestore() async {
        try {
          final snap = await _fs.collection('taxes').get();
          _taxesCache.clear();
          for (final d in snap.docs) {
            final m = {...d.data(), 'id': d.id};
            final tax = Tax.fromJson(m);
            _taxesCache[tax.id] = tax;
          }
        } catch (_) {}
      }

      static Future<void> updateTax(Tax tax) async {
        _checkInitialized();
        _taxesCache[tax.id] = tax;
        if (_firestoreAvailable) {
          try {
            await _fs.collection('taxes').doc(tax.id).set(tax.toJson(), SetOptions(merge: true));
          } catch (_) {}
        }
      }

      static Future<Tax?> getTaxById(String id) async {
        _checkInitialized();
        final local = _taxesCache[id];
        if (_firestoreAvailable) {
          try {
            final doc = await _fs.collection('taxes').doc(id).get();
            if (doc.exists) {
              final m = {...(doc.data() as Map<String, dynamic>), 'id': doc.id};
              final t = Tax.fromJson(m);
              _taxesCache[t.id] = t;
            }
          } catch (_) {}
        }
        return local;
      }

      // -------------------- Users --------------------
      static Future<void> addUser(User user) async {
        _checkInitialized();
        _usersCache[user.id] = user;
        if (_firestoreAvailable) {
          try {
            await _fs.collection('users').doc(user.id).set(user.toJson());
          } catch (_) {}
        }
        // Persist to Hive
        try {
          await _saveUserToHive(user);
        } catch (_) {}
      }

      static Future<List<User>> getAllUsers() async {
        _checkInitialized();
        if (_firestoreAvailable) {
          try {
            await _syncUsersFromFirestore();
          } catch (_) {}
        }
        return _usersCache.values.toList();
      }

      static Future<void> _syncUsersFromFirestore() async {
        try {
          final snap = await _fs.collection('users').get();
          _usersCache.clear();
          for (final d in snap.docs) {
            final m = {...d.data(), 'id': d.id};
            final u = User.fromJson(m);
            _usersCache[u.id] = u;
          }
        } catch (_) {}
      }

      static User? getUserByPhone(String phone) {
        _checkInitialized();
        try {
          return _usersCache.values.firstWhere((u) => u.phone == phone);
        } catch (_) {
          return null;
        }
      }

      static Future<void> updateUser(User user) async {
        _checkInitialized();
        _usersCache[user.id] = user;
        if (_firestoreAvailable) {
          try {
            await _fs.collection('users').doc(user.id).set(user.toJson(), SetOptions(merge: true));
          } catch (_) {}
        }
        try {
          await _saveUserToHive(user);
        } catch (_) {}
      }

      // -------------------- Auth tokens --------------------
      static Future<void> saveAuthToken(String token) async {
        _checkInitialized();
        _authToken = token;
        if (_firestoreAvailable) {
          try {
            await _fs.collection('settings').doc('auth').set({'last_token': token});
          } catch (_) {}
        }
        // persist locally
        try {
          _settingsCache['last_token'] = token;
          await _saveSettingsToHive();
        } catch (_) {}
      }

      static String? getAuthToken() {
        _checkInitialized();
        return _authToken;
      }

      static Future<void> clearAuthToken() async {
        _checkInitialized();
        _authToken = null;
        _settingsCache.remove('last_token');
        _settingsCache.remove('last_user_id');
        try {
          final box = Hive.box('settings');
          await box.delete('last_token');
          await box.delete('last_user_id');
        } catch (_) {}
      }
      
      static Future<void> _clearAuthTokenFromHive() async {
        try {
          final box = Hive.box('settings');
          await box.delete('last_token');
        } catch (_) {}
      }

      // -------------------- Payments --------------------
      static Future<void> addPayment(Payment payment) async {
        _checkInitialized();
        _paymentsCache[payment.id] = payment;
        if (_firestoreAvailable) {
          try {
                // Prepare payload and attach user id if available. Remove nulls to
                // avoid overwriting non-null values already present in Firestore.
                final raw = payment.toJson();
                try {
                  final last = _settingsCache['last_user_id'] as String? ?? null;
                  if (last != null && last.isNotEmpty) raw['user_id'] = last;
                } catch (_) {}
                final payload = _filterNulls(Map<String, dynamic>.from(raw));
                // Merge to avoid overwriting existing fields
                await _fs.collection('payments').doc(payment.id).set(payload, SetOptions(merge: true));
          } catch (_) {}
        }
        // Persist to Hive
        try {
          await _savePaymentToHive(payment);
        } catch (_) {}
      }

      /// Ajoute un paiement et l'associe à un utilisateur (mapping dans settings)
      static Future<void> addPaymentForUser(String userId, Payment payment) async {
        _checkInitialized();
        _paymentsCache[payment.id] = payment;
        // Mettre à jour le mapping user -> [paymentIds] dans le cache
        final map = Map<String, List<String>>.from(settingsCache['payments_by_user'] ?? {});
        final list = List<String>.from(map[userId] ?? []);
        if (!list.contains(payment.id)) {
          list.add(payment.id);
          map[userId] = list;
          settingsCache['payments_by_user'] = map;
        }
        if (_firestoreAvailable) {
          try {
            final raw = payment.toJson();
            raw['user_id'] = userId;
            final payload = _filterNulls(Map<String, dynamic>.from(raw));
            await _fs.collection('payments').doc(payment.id).set(payload, SetOptions(merge: true));
            await _fs.collection('users').doc(userId).set({'payments': map[userId]}, SetOptions(merge: true));
            await _fs.collection('settings').doc('app').set({'payments_by_user': map}, SetOptions(merge: true));
          } catch (_) {}
        }
        // persist settings mapping locally
        _settingsCache['payments_by_user'] = map;
        try {
          await _saveSettingsToHive();
        } catch (_) {}
        // Also persist the payment itself to Hive so it survives restarts
        try {
          await _savePaymentToHive(payment);
        } catch (_) {}
      }

      static List<Payment> getAllPayments() {
        _checkInitialized();
        if (_firestoreAvailable) {
          _syncPaymentsFromFirestore();
        }
        return _paymentsCache.values.toList();
      }

      static Future<void> _syncPaymentsFromFirestore() async {
        try {
          final snap = await _fs.collection('payments').get();
          _paymentsCache.clear();
          for (final d in snap.docs) {
            final m = {...d.data(), 'id': d.id};
            final p = Payment.fromMap(m);
            _paymentsCache[p.id] = p;
          }
        } catch (_) {}
      }

      /// Récupère les paiements associés à un utilisateur
      static List<Payment> getPaymentsForUser(String userId) {
        _checkInitialized();
        final map = Map<String, dynamic>.from(settingsCache['payments_by_user'] ?? {});
        final ids = (map[userId] as List?)?.cast<String>();
        // If there is an explicit mapping, return those payments and trigger
        // a background refresh from Firestore if available.
        if (ids != null && ids.isNotEmpty) {
          final payments = <Payment>[];
          for (final id in ids) {
            final p = _paymentsCache[id];
            if (p != null) payments.add(p);
          }
          if (_firestoreAvailable) {
            _fs.collection('payments').where('user_id', isEqualTo: userId).get().then((snap) {
              for (final d in snap.docs) {
                final m = {...d.data(), 'id': d.id};
                try {
                  final p = Payment.fromMap(Map<String, dynamic>.from(m));
                  _paymentsCache[p.id] = p;
                } catch (_) {}
              }
            }).catchError((_) {});
          }
          return payments;
        }

        // No explicit mapping: try to find payments in the local Hive box by user id
        try {
          final box = Hive.box('payments');
          final raw = box.toMap();
          final payments = <Payment>[];
          raw.forEach((k, v) {
            if (v is Map) {
              final mapV = Map<String, dynamic>.from(v as Map);
              final uid = (mapV['userId'] ?? mapV['user_id']) as String?;
              if (uid != null && uid == userId) {
                try {
                  final p = Payment.fromMap(mapV);
                  payments.add(p);
                } catch (_) {}
              }
            }
          });
          if (payments.isNotEmpty) return payments;
        } catch (_) {}

        // If Firestore is available, refresh remote payments in background and
        // return the current cache as a best-effort fallback.
        if (_firestoreAvailable) {
          _fs.collection('payments').where('user_id', isEqualTo: userId).get().then((snap) {
            for (final d in snap.docs) {
              final m = {...d.data(), 'id': d.id};
              try {
                final p = Payment.fromMap(Map<String, dynamic>.from(m));
                _paymentsCache[p.id] = p;
              } catch (_) {}
            }
          }).catchError((_) {});
        }

        // Final fallback: return all cached payments so the UI shows something.
        return _paymentsCache.values.toList();
      }

  static Payment? getPaymentById(String id) {
    _checkInitialized();
    final local = _paymentsCache[id];
    if (_firestoreAvailable) {
      _fs.collection('payments').doc(id).get().then((doc) {
        if (doc.exists) {
          final data = doc.data() ?? {};
          final m = {...data, 'id': doc.id};
            final p = Payment.fromMap(m);
          _paymentsCache[p.id] = p;
        }
      }).catchError((_) {});
    }
    return local;
  }

  static Future<void> updatePayment(Payment payment) async {
    _checkInitialized();
    _paymentsCache[payment.id] = payment;
    if (_firestoreAvailable) {
      try {
        final payload = _filterNulls(Map<String, dynamic>.from(payment.toJson()));
        await _fs.collection('payments').doc(payment.id).set(payload, SetOptions(merge: true));
      } catch (_) {}
    }
        try {
          await _savePaymentToHive(payment);
        } catch (_) {}
  }

      /// Supprime un paiement globalement (cache, Hive, Firestore)
      static Future<void> deletePayment(String paymentId) async {
        _checkInitialized();
        _paymentsCache.remove(paymentId);
        // Remove from any payments_by_user mapping
        try {
          final map = Map<String, List<String>>.from(_settingsCache['payments_by_user'] ?? {});
          var changed = false;
          for (final entry in map.entries) {
            if (entry.value.contains(paymentId)) {
              entry.value.remove(paymentId);
              changed = true;
            }
          }
          if (changed) {
            _settingsCache['payments_by_user'] = map;
            await _saveSettingsToHive();
            if (_firestoreAvailable) {
              try {
                await _fs.collection('settings').doc('app').set({'payments_by_user': map}, SetOptions(merge: true));
              } catch (_) {}
            }
          }
        } catch (_) {}

        try {
          final box = Hive.box('payments');
          await box.delete(paymentId);
        } catch (_) {}

        if (_firestoreAvailable) {
          try {
            await _fs.collection('payments').doc(paymentId).delete();
          } catch (_) {}
        }
      }

      /// Supprime un paiement pour un utilisateur spécifique (ne supprime
      /// pas le paiement global si d'autres utilisateurs y réfèrent).
      static Future<void> deletePaymentForUser(String userId, String paymentId) async {
        _checkInitialized();
        try {
          final map = Map<String, List<String>>.from(_settingsCache['payments_by_user'] ?? {});
          final list = List<String>.from(map[userId] ?? []);
          if (list.contains(paymentId)) {
            list.remove(paymentId);
            map[userId] = list;
            _settingsCache['payments_by_user'] = map;
            await _saveSettingsToHive();
            if (_firestoreAvailable) {
              try {
                await _fs.collection('users').doc(userId).set({'payments': map[userId]}, SetOptions(merge: true));
                await _fs.collection('settings').doc('app').set({'payments_by_user': map}, SetOptions(merge: true));
              } catch (_) {}
            }
          }
        } catch (_) {}
        // Also remove local Hive entry if present but keep global payment if other users reference it
        try {
          final box = Hive.box('payments');
          await box.delete(paymentId);
        } catch (_) {}
      }

  /// Vérifie si la base de données est initialisée
  static void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('La base de données n\'a pas été initialisée. Appelez d\'abord initDatabase()');
    }
  }
}
