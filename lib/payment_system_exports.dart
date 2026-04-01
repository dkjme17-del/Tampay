/// Export centralisé pour le système de paiement multicanal
///
/// Usage:
/// ```dart
/// import 'package:applicationweb/payment_system_exports.dart';
/// ```

// Managers et services
export 'services/payment_operators/orange_money_service.dart';
export 'services/payment_operators/wave_service.dart';
export 'services/payment_operators/moov_money_service.dart';
export 'services/payment_operators/mtn_money_service.dart';
export 'services/payment_operators/card_payment_service.dart';
export 'services/payment_operators/payment_operators_manager.dart';

// Providers
export 'providers/payment_provider.dart';

// Écrans
export 'screens/multi_channel_payment_screen.dart';
export 'screens/payment_confirmation_screen.dart';
export 'screens/payment_integration_example.dart';

// Models
export 'models/payment.dart';
