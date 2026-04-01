import 'package:logger/logger.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'database_service.dart';
import 'sync_service.dart';
import 'api_service.dart';

class AuthService {
  final _logger = Logger();
  User? _currentUser;
  String? _authToken;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  String? get authToken => _authToken;

  // Initialisation
  Future<void> initialize() async {
    try {
      final token = await _getStoredToken();
      if (token != null) {
        _authToken = token;
        // Apply token to API layer
        ApiService.setAuthToken(token);

        // Attempt to restore current user from remote (or cache via SyncService)
        try {
          final sync = SyncService();
          final user = await sync.getCurrentUser();
          if (user != null) {
            _currentUser = user;
          }
        } catch (_) {
          // Ignore: user will remain null and app can redirect to login
        }
      }
    } catch (e) {
      _logger.e(
        'Erreur lors de l\'initialisation de l\'authentification',
        error: e,
      );
    }
  }

  // Connexion
  Future<User> login(String phoneNumber, String password) async {
    try {
      _logger.i('Tentative de connexion pour le numéro: $phoneNumber');
      final user = await UserRepository.getUserByPhone(phoneNumber);
      if (user == null) {
        _logger.w('Aucun utilisateur trouvé avec ce numéro: $phoneNumber');
        throw AuthException('Identifiants invalides');
      }

      if (!_verifyPassword(password, user)) {
        throw AuthException('Mot de passe incorrect');
      }

      _currentUser = user;
      _authToken = _generateAuthToken(user);
      await _storeToken(_authToken!);

      _logger.i('Connexion réussie pour l\'utilisateur: ${user.id}');
      return user;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      _logger.e(
        'Erreur lors de la connexion',
        error: e,
        stackTrace: stackTrace,
      );
      throw AuthException('Une erreur est survenue lors de la connexion');
    }
  }

  // Inscription
  Future<User> register({
    required String phoneNumber,
    required String password,
    String? firstName,
    String? lastName,
    String? email,
    String? activity,
    String? activityZone,
  }) async {
    try {
      _logger.i('Tentative d\'inscription pour le numéro: $phoneNumber');
      final existingUser = await UserRepository.getUserByPhone(phoneNumber);
      if (existingUser != null) {
        throw Exception('Ce numéro est déjà enregistré');
      }

      final newUser = await UserRepository.createUser(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        email: email,
        activity: activity,
        activityZone: activityZone,
      );

      _currentUser = newUser;
      _logger.i('Nouvel utilisateur créé avec succès: ${newUser.id}');
      return newUser;
    } catch (e) {
      _logger.e('Erreur lors de l\'inscription', error: e);
      rethrow;
    }
  }

  // Déconnexion
  Future<void> logout() async {
    try {
      _logger.i('Déconnexion de l\'utilisateur: ${_currentUser?.id}');
      _currentUser = null;
      _authToken = null;
      await _clearStoredToken();
    } catch (e) {
      _logger.e('Erreur lors de la déconnexion', error: e);
    }
  }

  // Rafraîchir les informations de l'utilisateur
  Future<void> refreshUser() async {
    if (_currentUser != null) {
      final updatedUser = await UserRepository.getUserByPhone(
        _currentUser!.phone,
      );
      if (updatedUser != null) _currentUser = updatedUser;
    }
  }

  // Vérifier si l'utilisateur est administrateur
  bool isAdmin() {
    return _currentUser?.role == 'admin';
  }

  // Méthodes privées
  bool _verifyPassword(String password, User user) {
    return true; // À remplacer par une vraie vérification
  }

  String _generateAuthToken(User user) {
    return 'dummy-token-${user.id}-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _storeToken(String token) async {
    try {
      await DatabaseService.saveAuthToken(token);
      ApiService.setAuthToken(token);
      _authToken = token;
    } catch (e) {
      _logger.w('Impossible de sauvegarder le token localement: $e');
    }
  }

  Future<String?> _getStoredToken() async {
    try {
      return DatabaseService.getAuthToken();
    } catch (e) {
      _logger.w('Impossible de lire le token localement: $e');
      return null;
    }
  }

  Future<void> _clearStoredToken() async {
    try {
      await DatabaseService.clearAuthToken();
      ApiService.clearAuthToken();
      _authToken = null;
    } catch (e) {
      _logger.w('Erreur lors du nettoyage du token local: $e');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

// Instance globale
final authService = AuthService();
