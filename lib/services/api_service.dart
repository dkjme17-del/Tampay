import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:uuid/uuid.dart';
import '../models/payment.dart';
import '../models/tax.dart';
import '../models/user.dart';

/// ApiService backed by Firestore (replaces previous HTTP backend).
class ApiService {
  static final _uuid = Uuid();

  // Simple client token (user id)
  static String? _authToken;
  static void setAuthToken(String token) => _authToken = token;
  static String? getAuthToken() => _authToken;
  static void clearAuthToken() => _authToken = null;

  // Ensure Firebase is initialized before accessing Firestore.
  static Future<FirebaseFirestore> _getFs() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }
    } catch (_) {}
    return FirebaseFirestore.instance;
  }

  // ==================== AUTH ====================
  static Future<Map<String, dynamic>> register({
    required String phone,
    required String name,
    String? password,
    String? activity,
    String? activityZone,
  }) async {
    final fs = await _getFs();
    final users = fs.collection('users');
    final q = await users.where('phone', isEqualTo: phone).limit(1).get();
    if (q.docs.isNotEmpty) {
      final existing = q.docs.first;
      setAuthToken(existing.id);
      return {'user': {...existing.data(), 'id': existing.id}, 'token': existing.id};
    }

    final docRef = users.doc();
    final now = DateTime.now();
    final payload = {
      'phone': phone,
      'name': name,
      'role': 'citizen',
      'zone': '',
      'activity': activity ?? '',
      'activityZone': activityZone ?? '',
      'created_at': now,
      'updated_at': now,
      'registrationDate': now.toIso8601String(),
      // Do not store raw passwords. Indicate whether the account has a password set.
      'hasPassword': password != null,
    };
    await docRef.set(payload);
    setAuthToken(docRef.id);
    return {'user': {...payload, 'id': docRef.id}, 'token': docRef.id};
  }

  static Future<Map<String, dynamic>> login({required String phone, String? password}) async {
    final fs = await _getFs();
    final users = fs.collection('users');
    final q = await users.where('phone', isEqualTo: phone).limit(1).get();
    if (q.docs.isEmpty) throw Exception('Utilisateur non trouvé');
    final doc = q.docs.first;
    setAuthToken(doc.id);
    return {'user': {...doc.data(), 'id': doc.id}, 'token': doc.id};
  }

  static Future<Map<String, dynamic>> verifyToken() async {
    if (_authToken == null) throw Exception('No token');
    final fs = await _getFs();
    final doc = await fs.collection('users').doc(_authToken).get();
    if (!doc.exists) throw Exception('Invalid token');
    return {'user': {...(doc.data() ?? {}), 'id': doc.id}, 'token': doc.id};
  }

  static Future<void> logout() async => clearAuthToken();

  // ==================== USERS ====================
  static Future<User> getCurrentUser() async {
    if (_authToken == null) throw Exception('Non authentifié');
    final fs = await _getFs();
    final doc = await fs.collection('users').doc(_authToken).get();
    if (!doc.exists) throw Exception('Utilisateur introuvable');
    return User.fromJson({...(doc.data() ?? {}), 'id': doc.id});
  }

  static Future<User> getUser(String userId) async {
    final fs = await _getFs();
    final doc = await fs.collection('users').doc(userId).get();
    if (!doc.exists) throw Exception('Utilisateur introuvable');
    return User.fromJson({...(doc.data() ?? {}), 'id': doc.id});
  }

  static Future<User> updateUser(String userId, Map<String, dynamic> data) async {
    final fs = await _getFs();
    await fs.collection('users').doc(userId).set(data, SetOptions(merge: true));
    final doc = await fs.collection('users').doc(userId).get();
    return User.fromJson({...(doc.data() ?? {}), 'id': doc.id});
  }

  static Future<List<User>> getUsersByZone(String zone) async {
    final fs = await _getFs();
    final q = await fs.collection('users').where('zone', isEqualTo: zone).get();
        return q.docs.map((d) {
          final m = <String, dynamic>{};
          final raw = d.data() as Map;
          raw.forEach((k, v) => m[k.toString()] = v);
          m['id'] = d.id;
          return User.fromJson(m);
      }).toList();
  }

  // ==================== TAXES ====================
  static Future<List<Tax>> getTaxes({String? category, String? zone}) async {
    final fs = await _getFs();
    Query q = fs.collection('taxes');
    if (category != null) q = q.where('category', isEqualTo: category);
    if (zone != null) q = q.where('zone', isEqualTo: zone);
    final snap = await q.get();
        return snap.docs.map((d) {
          final m = <String, dynamic>{};
          final raw = d.data() as Map;
          raw.forEach((k, v) => m[k.toString()] = v);
          m['id'] = d.id;
          return Tax.fromJson(m);
      }).toList();
  }

  static Future<Tax> getTax(String taxId) async {
    final fs = await _getFs();
    final doc = await fs.collection('taxes').doc(taxId).get();
    if (!doc.exists) throw Exception('Taxe non trouvée');
    return Tax.fromJson({...(doc.data() ?? {}), 'id': doc.id});
  }

  static Future<Tax> createTax(Map<String, dynamic> data) async {
    final fs = await _getFs();
    final ref = await fs.collection('taxes').add(data);
    final fresh = await ref.get();
    return Tax.fromJson({...(fresh.data() ?? {}), 'id': fresh.id});
  }

  static Future<Tax> updateTax(String taxId, Map<String, dynamic> data) async {
    final fs = await _getFs();
    await fs.collection('taxes').doc(taxId).set(data, SetOptions(merge: true));
    final doc = await fs.collection('taxes').doc(taxId).get();
    return Tax.fromJson({...?doc.data(), 'id': doc.id});
  }

  static Future<void> deleteTax(String taxId) async {
    final fs = await _getFs();
    await fs.collection('taxes').doc(taxId).delete();
  }

  // ==================== PAYMENTS ====================
  static Future<Map<String, dynamic>> createPayment({
    required String taxId,
    required double amount,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    final fs = await _getFs();
    final payments = fs.collection('payments');
    final id = _uuid.v4();
    final verificationCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 899999)).toString();
    final qrCode = 'QR:$id';
    final payload = {
      'taxId': taxId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'metadata': metadata ?? {},
      if (_authToken != null) 'user_id': _authToken,
      'status': 'pending',
      'verificationCode': verificationCode,
      'qrCode': qrCode,
      'created_at': DateTime.now(),
    };
    await payments.doc(id).set(payload);
    return {'paymentId': id, 'qrCode': qrCode, 'verificationCode': verificationCode};
  }

  static Future<Payment> getPayment(String paymentId) async {
    final fs = await _getFs();
    final doc = await fs.collection('payments').doc(paymentId).get();
    if (!doc.exists) throw Exception('Paiement non trouvé');
    return Payment.fromMap({...?doc.data(), 'id': doc.id});
  }

  static Future<List<Payment>> getUserPayments(String userId) async {
    final fs = await _getFs();
    final q = await fs.collection('payments').where('user_id', isEqualTo: userId).get();
        return q.docs.map((d) {
          final m = <String, dynamic>{};
          final raw = d.data() as Map;
          raw.forEach((k, v) => m[k.toString()] = v);
          m['id'] = d.id;
          return Payment.fromMap(m);
      }).toList();
  }

  static Future<List<Payment>> getPaymentsByStatus(String status) async {
    final fs = await _getFs();
    final q = await fs.collection('payments').where('status', isEqualTo: status).get();
        return q.docs.map((d) {
          final m = <String, dynamic>{};
          final raw = d.data() as Map;
          raw.forEach((k, v) => m[k.toString()] = v);
          m['id'] = d.id;
          return Payment.fromMap(m);
      }).toList();
  }

  static Future<Payment> verifyPayment(String paymentId, {String? verificationCode, String? verifiedBy}) async {
    final fs = await _getFs();
    final ref = fs.collection('payments').doc(paymentId);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Paiement non trouvé');
    final data = doc.data() ?? {};
    // Support both common field names
    final storedCode = (data['verificationCode'] ?? data['verification_code'])?.toString();
    // If a verificationCode was provided, validate it against stored code.
    // If no code provided (admin override), skip the check and accept verification.
    if (verificationCode != null && verificationCode.isNotEmpty) {
      if (storedCode == null || storedCode.isEmpty) {
        throw Exception('Aucun code de vérification enregistré pour ce paiement');
      }
      if (storedCode != verificationCode.toString()) {
        throw Exception('Code de vérification invalide');
      }
    }
    final now = DateTime.now();
    await ref.set({
      'status': 'verified',
      'verified_at': now,
      if (verifiedBy != null) 'verified_by': verifiedBy,
    }, SetOptions(merge: true));
    final updated = await ref.get();
    return Payment.fromMap({...(updated.data() ?? {}), 'id': updated.id});
  }

  static Future<Map<String, dynamic>> getPaymentStatistics() async {
    final fs = await _getFs();
    final snap = await fs.collection('payments').get();
    final payments = snap.docs.map((d) => d.data()).toList();
    final completed = payments.where((p) => p['status'] == 'completed' || p['status'] == 'verified').toList();
    final verified = payments.where((p) => p['verified_at'] != null).toList();
    final totalRevenue = completed.fold<double>(0, (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0.0));
    return {
      'totalRevenue': totalRevenue,
      'totalPayments': payments.length,
      'completedPayments': completed.length,
      'verifiedPayments': verified.length,
    };
  }

  static Future<Map<String, dynamic>> getPaymentsPage({int page = 1, int limit = 20, String? status, String? zone}) async {
    final fs = await _getFs();
    Query q = fs.collection('payments');
    if (status != null) q = q.where('status', isEqualTo: status);
    if (zone != null) q = q.where('zone', isEqualTo: zone);
    final snap = await q.orderBy('created_at', descending: true).limit(limit).get();
        final payments = snap.docs.map((d) {
          final raw = d.data();
          final m = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          m['id'] = d.id;
          return m;
      }).toList();
    return {'payments': payments, 'page': page, 'limit': limit};
  }

  // Gateway integrations are not handled here — they should be done with provider SDKs.
  static Future<String> initializeFlutterwave({required String paymentId, required double amount, required String customerName, required String customerPhone}) async {
    throw UnimplementedError('Gateway integrations are not supported in Firestore mode');
  }

  static Future<Map<String, dynamic>> verifyFlutterwave(String transactionId) async {
    throw UnimplementedError('Gateway integrations are not supported in Firestore mode');
  }

  static Future<String> initializeStripe({required String paymentId, required double amount, required String customerEmail}) async {
    throw UnimplementedError('Gateway integrations are not supported in Firestore mode');
  }
}

/// Lightweight API exception used by HTTP implementation; kept for compatibility.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
 
