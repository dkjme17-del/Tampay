import 'package:logger/logger.dart';

class PostgresService {
  static final PostgresService _instance = PostgresService._internal();
  final _logger = Logger();

  // On ne crée plus de connexion PostgreSQL

  factory PostgresService() => _instance;

  PostgresService._internal();

  /// Initialise le service (désactivé)
  Future<void> initialize() async {
    // Désactivé volontairement pour Hive-only
    _logger.w('PostgresService est désactivé — utilisation de Hive uniquement');
  }

  /// Retourne faux, pas de connexion PostgreSQL
  bool get isConnected => false;

  /// Fermer la connexion (inutile ici)
  Future<void> close() async {
    _logger.w('PostgresService fermé (rien à fermer)');
  }

  /// Transaction simulée
  Future<T> transaction<T>(
    Future<T> Function(dynamic ctx) action,
  ) async {
    _logger.w('Transactions PostgreSQL ignorées — utilisez Hive');
    return await action(null);
  }
}

final postgresService = PostgresService();
