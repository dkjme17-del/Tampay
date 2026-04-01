import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import 'firebase_options.dart';

// App
import 'constants/app_theme.dart';

// Providers
import 'providers/user_provider.dart';
import 'providers/tax_provider.dart';
import 'providers/payment_provider.dart';

// Models
import 'models/tax.dart';
import 'models/user.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Services
import 'services/auth_service.dart';
import 'services/database_service.dart' as db_service;
import 'services/payment_operators/payment_operators_manager.dart';

/// Logger global
final Logger logger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 50,
    colors: true,
    printEmojis: true,
  ),
);

// Track whether .env was successfully loaded to avoid NotInitializedError
bool _envLoaded = false;

String? _env(String key) => _envLoaded ? dotenv.env[key] : null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(const MyApp());
  } catch (e, st) {
    logger.e('Échec critique au démarrage', error: e, stackTrace: st);

    runApp(
      const ErrorApp(
        errorMessage:
            'Impossible de démarrer l’application.\nVérifiez la configuration Firebase.',
      ),
    );
  }
}

/// ===============================
/// INITIALISATION GLOBALE
/// ===============================
Future<void> _initializeApp() async {
  logger.i('🚀 Démarrage application');

  await _loadEnvironmentVariables();
  await _initializeFirebase(); // 🔥 OBLIGATOIRE
  await _initializeDatabase();
  await _initializeAuthService();
  await _initializeTestData();

  logger.i('✅ Application prête');
}

/// ===============================
/// ENV (.env)
/// ===============================
Future<void> _loadEnvironmentVariables() async {
  try {
    final envFile = File('.env');
    if (envFile.existsSync()) {
      await dotenv.load(fileName: '.env');
      _envLoaded = true;
      logger.i('Variables .env chargées');
    } else {
      logger.w('.env introuvable');
    }

    try {
      final simulateCI = _env('SIMULATE_CI');
      if (simulateCI == 'true') {
        PaymentOperatorsManager.simulateCI = true;
        logger.i('Simulation paiement CI activée');
      }
    } catch (_) {
      // ignore if env not loaded
    }
  } catch (e, st) {
    logger.w('Erreur chargement .env', error: e, stackTrace: st);
  }
}

/// ===============================
/// FIREBASE (CRITIQUE)
/// ===============================
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // If developer enabled emulator mode via .env, route services to emulator
    try {
      final useEmulator = _env('USE_FIREBASE_EMULATOR') == 'true';
      if (useEmulator) {
        final host = _env('FIRESTORE_EMULATOR_HOST') ?? 'localhost';
        final port = int.tryParse(_env('FIRESTORE_EMULATOR_PORT') ?? '8080') ?? 8080;
        FirebaseFirestore.instance.useFirestoreEmulator(host, port);

        final authPort = int.tryParse(_env('FIREBASE_AUTH_EMULATOR_PORT') ?? '9099') ?? 9099;
        try {
          fb_auth.FirebaseAuth.instance.useAuthEmulator(host, authPort);
        } catch (_) {
          // Some platforms / plugin versions may not expose useAuthEmulator; ignore if absent
        }

        logger.i('Using Firebase emulators at $host (firestore:$port auth:$authPort)');
      }
    } catch (e, st) {
      logger.w('Failed configuring Firebase emulator', error: e, stackTrace: st);
    }
    // Basic verification to ensure Firebase services are reachable
    try {
      await _verifyFirebase();
      logger.i('🔥 Firebase initialisé');
    } catch (e, st) {
      // Don't crash the whole app on Firestore permission issues or other
      // environment problems; log and continue so UI can run.
      logger.w('Firebase verification failed (non-fatal)', error: e, stackTrace: st);
    }
  } catch (e, st) {
    logger.e(
      '❌ Firebase.initializeApp a échoué',
      error: e,
      stackTrace: st,
    );
    // Do not rethrow — allow app to show error UI but continue where possible
    return;
  }
}

/// ===============================
/// TEST DE FONCTIONNEMENT FIREBASE
/// ===============================
Future<void> _verifyFirebase() async {
  try {
    // Vérifie que l'application Firebase est bien initialisée
    final apps = Firebase.apps;
    logger.i('Firebase apps disponibles : ${apps.map((a) => a.name).toList()}');

    // Test Auth
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    logger.i('Utilisateur connecté actuel : $user');

    // If no user and developer enabled auto anonymous sign-in, try it (useful for local emulators)
    if (user == null && _env('AUTO_ANON_SIGNIN') == 'true') {
      try {
        await fb_auth.FirebaseAuth.instance.signInAnonymously();
        logger.i('Signed in anonymously for local testing');
      } catch (e, st) {
        logger.w('Anonymous sign-in failed', error: e, stackTrace: st);
      }
    }

    // Test Firestore (permission errors are common if rules require auth)
    try {
      final testDoc = await FirebaseFirestore.instance
          .collection('test')
          .doc('ping')
          .get();

      if (testDoc.exists) {
        logger.i('Document test trouvé : ${testDoc.data()}');
      } else {
        logger.w('Document test introuvable dans Firestore');
      }

      logger.i('✅ Vérification Firebase terminée avec succès');
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied' || fe.message?.contains('permission') == true) {
        logger.w('Firestore permission denied — continuing without failing startup', error: fe);
        return;
      }
      rethrow;
    }
  } catch (e, st) {
    logger.e('❌ Vérification Firebase échouée', error: e, stackTrace: st);
    // Don't rethrow — allow app to continue where possible
    return;
  }
}

/// ===============================
/// DATABASE (HIVE)
/// ===============================
Future<void> _initializeDatabase() async {
  try {
    await db_service.DatabaseService.initDatabase();
    logger.i('📦 Base de données prête');
  } catch (e, st) {
    logger.e(
      '❌ Base de données impossible',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
}

/// ===============================
/// AUTH SERVICE
/// ===============================
Future<void> _initializeAuthService() async {
  try {
    Firebase.app(); // 🔒 Sécurité
    await authService.initialize();
    logger.i('🔐 AuthService prêt');
  } catch (e, st) {
    logger.e(
      '❌ AuthService impossible',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
}

/// ===============================
/// DONNÉES DE TEST
/// ===============================
Future<void> _initializeTestData() async {
  try {
    final taxes = db_service.DatabaseService.getAllTaxes();
    if (taxes.isEmpty) {
      final seedTaxes = [
        Tax(id: 'tax-001', name: 'Taxe commerciale', amount: 50000, zone: 'Centre-Ville'),
        Tax(id: 'tax-002', name: 'Taxe artisanale', amount: 25000, zone: 'Centre-Ville'),
        Tax(id: 'tax-003', name: 'Taxe de circulation', amount: 15000, zone: 'Centre-Ville'),
      ];
      for (final t in seedTaxes) {
        await db_service.DatabaseService.addTax(t);
      }
      logger.i('Taxes de test ajoutées');
    }

    final users = await db_service.DatabaseService.getAllUsers();
    if (users.isEmpty) {
      await db_service.DatabaseService.addUser(
        User(
          id: 'admin-001',
          name: 'Admin',
          phone: '+2250700000000',
          email: 'admin@municipay.ci',
          role: 'admin',
          zone: 'Centre-Ville',
          registrationDate: DateTime.now(),
        ),
      );
      logger.i('Utilisateur admin créé');
    }
  } catch (e, st) {
    logger.w('Erreur données test', error: e, stackTrace: st);
  }
}

/// ===============================
/// APPLICATION
/// ===============================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaxProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
      ],
      child: MaterialApp(
        title: 'MuniciPay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: Consumer<AuthService>(
          builder: (_, auth, __) =>
              auth.isAuthenticated ? const HomeScreen() : const LoginScreen(),
        ),
      ),
    );
  }
}

/// ===============================
/// APP ERREUR
/// ===============================
class ErrorApp extends StatelessWidget {
  final String errorMessage;

  const ErrorApp({
    super.key,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'Erreur',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
