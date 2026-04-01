import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  final SyncService _syncService = SyncService();

  User? get currentUser => _currentUser;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserProvider() {
    _loadUsers();
    _restoreSession();
  }

  /// Restaurer la session depuis le token sauvegardé
  Future<void> _restoreSession() async {
    try {
      final token = DatabaseService.getAuthToken();
      if (token != null) {
        ApiService.setAuthToken(token);
        final user = await _syncService.getCurrentUser();
        if (user != null) {
          _currentUser = user;
          notifyListeners();
        }
        return;
      }
      // Fallback: try last user id stored locally
      try {
        final lastId = DatabaseService.getLastUserId();
        if (lastId != null) {
          final users = await DatabaseService.getAllUsers();
          try {
            final u = users.firstWhere((x) => x.id == lastId);
            _currentUser = u;
            notifyListeners();
            return;
          } catch (_) {}
        }
      } catch (_) {}
    } catch (e) {
      // Erreur restauration session - peut être attendu au premier lancement
    }
  }

  Future<void> _loadUsers() async {
    _users = await DatabaseService.getAllUsers();
    notifyListeners();
  }

  /// S'inscrire (nouveau utilisateur)
  Future<bool> registerUser(String name, String phone, {String? password, String? activity, String? activityZone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _syncService.register(phone: phone, name: name, password: password, activity: activity, activityZone: activityZone);

      _currentUser = User.fromJson(response['user']);
      try {
        await DatabaseService.saveLastUserId(_currentUser!.id);
      } catch (_) {}
      await _loadUsers();
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

  /// Se connecter
  Future<bool> login(String phone, {String? password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _syncService.login(phone: phone, password: password);
      _currentUser = User.fromJson(response['user']);
      try {
        await DatabaseService.saveLastUserId(_currentUser!.id);
      } catch (_) {}
      await _loadUsers();
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

  /// Démarrer la procédure de connexion via SMS (envoi du code)
  Future<bool> requestLogin(String phone) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // En l'absence d'utilisateur local, on laisse quand même envoyer le code
      // SMS flow removed — use direct login instead
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

  /// Vérifier le code reçu par SMS et finaliser la connexion
  Future<bool> verifyLogin(String phone, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _syncService.login(phone: phone, password: code);
      _currentUser = User.fromJson(response['user']);
      await _loadUsers();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Échec vérification/login: ${e.toString()}. Si votre backend exige un mot de passe, utilisez la méthode de connexion classique.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Se déconnecter
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (e) {
      // Erreur logout - nettoyer quand même
    }
    _currentUser = null;
    DatabaseService.clearAuthToken();
    ApiService.clearAuthToken();
    notifyListeners();
  }

  /// Récupérer les utilisateurs par rôle
  List<User> getUsersByRole(String role) {
    return _users.where((u) => u.role == role).toList();
  }

  /// Récupérer les utilisateurs par zone
  List<User> getUsersByZone(String zone) {
    return _users.where((u) => u.zone == zone).toList();
  }

  /// Mettre à jour l'utilisateur courant
  Future<bool> updateCurrentUser(User user) async {
    try {
      _currentUser = user;
      await DatabaseService.updateUser(user);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Effacer le message d'erreur
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
