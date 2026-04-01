import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/database_service.dart';

final _logger = Logger();

class UserRepository {
  /// Récupérer tous les utilisateurs (depuis DatabaseService)
  static Future<List<User>> getAllUsers() async {
    return DatabaseService.getAllUsers();
  }

  /// Récupérer un utilisateur par téléphone
  static Future<User?> getUserByPhone(String phone) async {
    return DatabaseService.getUserByPhone(phone);
  }

  /// Créer un nouvel utilisateur
  static Future<User> createUser({
    required String phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    String role = 'citizen',
    String zone = 'Centre-Ville',
    String? activity,
    String? activityZone,
  }) async {
    final id = 'user-${DateTime.now().millisecondsSinceEpoch}';
    final name = ('${firstName ?? ''}${(lastName != null && lastName.isNotEmpty) ? ' $lastName' : ''}').trim();

    final newUser = User(
      id: id,
      name: name.isEmpty ? phoneNumber : name,
      phone: phoneNumber,
      email: email,
      role: role,
      zone: zone,
      activity: activity,
      activityZone: activityZone,
      registrationDate: DateTime.now(),
    );

    await DatabaseService.addUser(newUser);
    _logger.i('Utilisateur créé : ${newUser.toJson()}');
    return newUser;
  }

  /// Mettre à jour un utilisateur
  static Future<void> updateUser(String id, Map<String, dynamic> updatedData) async {
    final users = await DatabaseService.getAllUsers();
    User? existing;
    try {
      existing = users.firstWhere((u) => u.id == id);
    } catch (_) {
      existing = null;
    }
    if (existing != null) {
      final merged = {...existing.toJson(), ...updatedData};
      final updated = User.fromJson(merged);
      await DatabaseService.updateUser(updated);
      _logger.i('Utilisateur mis à jour : ${updated.toJson()}');
    }
  }

  /// Supprimer un utilisateur
  static Future<void> deleteUser(String id) async {
    // remove from cache
    final users = DatabaseService.usersCache;
    users.remove(id);
    try {
      await FirebaseFirestore.instance.collection('users').doc(id).delete();
    } catch (_) {}
    _logger.i('Utilisateur supprimé : $id');
  }
}
