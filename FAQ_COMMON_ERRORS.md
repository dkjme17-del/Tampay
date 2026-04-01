# 🐛 FAQ - Erreurs Courantes et Solutions

## 🔴 Erreurs et Solutions

---

## 1. Erreur: "Cannot find module"

### ❌ Erreur
```
Error: Cannot find module 'payment_system_exports'
```

### ✅ Solution
```dart
// ❌ Faux
import 'payment_system_exports.dart';

// ✅ Correct
import 'package:applicationweb/payment_system_exports.dart';

// Ou importer directement
import 'package:applicationweb/services/payment_operators/payment_operators_manager.dart';
import 'package:applicationweb/screens/multi_channel_payment_screen.dart';
```

---

## 2. Erreur: "Opérateur non supporté"

### ❌ Erreur
```
Exception: Opérateur non supporté: carte_bancaire
```

### ✅ Solution
```dart
// ❌ Faux
String operator = 'carte_bancaire';

// ✅ Correct - utilisez les constantes
String operator = 'card';

// Opérateurs valides:
const validOperators = [
  'orange_money',  // Orange Money
  'wave',          // Wave
  'moov_money',    // Moov Money
  'mtn_money',     // MTN Money
  'card',          // Carte Bancaire
];
```

---

## 3. Erreur: "Montant invalide"

### ❌ Erreur
```
Exception: Montant doit être entre 100 et 500000 XOF
```

### ✅ Solution
```dart
// Vérifier avant de créer le paiement
bool isValid = PaymentOperatorsManager.validateAmount(
  'orange_money',
  amount,
);

if (!isValid) {
  // Afficher erreur à l'utilisateur
  final info = PaymentOperatorsManager.getOperatorInfo('orange_money');
  print('Montant doit être entre ${info?['minAmount']} et ${info?['maxAmount']}');
}

// Montants par opérateur:
// - Orange Money: 100 - 500,000 XOF
// - Wave: 500 - 1,000,000 XOF
// - Moov Money: 100 - 500,000 XOF
// - MTN Money: 100 - 500,000 XOF
// - Carte: 1,000 - 10,000,000 XOF
```

---

## 4. Erreur: "Numéro de téléphone invalide"

### ❌ Erreur
```
Exception: Format de téléphone invalide
```

### ✅ Solution
```dart
// ❌ Faux - sans le code pays
String phone = '701234567';

// ✅ Correct - avec le code pays international
String phone = '+221701234567';

// Codes pays:
// - Sénégal: +221
// - Mali: +223
// - Côte d'Ivoire: +225
// - Cameroun: +237
// - Togo: +228
// - Bénin: +229
// - Burkina Faso: +226

// Auto-detection
String country = PaymentOperatorsManager.detectCountryFromPhone('+221701234567');
print(country); // 'SN'
```

---

## 5. Erreur: "Carte invalide"

### ❌ Erreur
```
Exception: Numéro de carte invalide (13-19 chiffres)
Exception: Carte expirée
Exception: CVV invalide (3-4 chiffres)
```

### ✅ Solution

#### Numéro de carte
```dart
// Utiliser l'algorithme de Luhn pour valider
bool isValid = CardPaymentService.validateCardNumber('4242424242424242');

// Nombres de test valides:
// - Visa: 4242424242424242
// - Mastercard: 5555555555554444
// - American Express: 371449635398431

// Format: 13-19 chiffres
// Espaces autorisés: 4242 4242 4242 4242
```

#### Date d'expiration
```dart
// Format: MM/YY
// ❌ Faux: 12/2025
// ✅ Correct: 12/25

bool isValid = CardPaymentService.validateExpiryDate('12/25');

// La date ne doit pas être passée
// Si on est en décembre 2024:
// - 12/24: ❌ Expirée
// - 01/25: ✅ Valide
// - 12/25: ✅ Valide
```

#### CVV
```dart
// Format: 3 ou 4 chiffres
// ❌ Faux: AB, 1, 12345
// ✅ Correct: 123, 1234

bool isValid = CardPaymentService.validateCVV('123');
```

---

## 6. Erreur: "Aucun opérateur sélectionné"

### ❌ Erreur
```
Exception: Aucun opérateur sélectionné
```

### ✅ Solution
```dart
// Dans le provider
PaymentProvider provider = context.read<PaymentProvider>();

// Vérifier si un opérateur est sélectionné
if (provider.selectedOperator == null) {
  print('Veuillez sélectionner un opérateur');
  return;
}

// Sélectionner un opérateur
provider.selectOperator('wave');

// Vérifier encore
if (provider.selectedOperator != null) {
  print('Opérateur sélectionné: ${provider.selectedOperator}');
}
```

---

## 7. Erreur: "Paiement en attente"

### ❌ Erreur
```
Exception: Le paiement est toujours en attente
```

### ✅ Solution
```dart
// Le paiement prend du temps (5-30 secondes)
// L'écran de confirmation vérifie automatiquement le statut

// Pour vérifier manuellement:
Map<String, dynamic> status = 
  await PaymentOperatorsManager.checkTransactionStatus(
    'wave',
    'WAVE-1234567890',
  );

print(status['status']); // 'pending', 'success', ou 'failed'

// Vérifier le statut en base:
// SELECT status FROM payments WHERE id = 'PAY123456';
```

---

## 8. Erreur: "Code de vérification incorrect"

### ❌ Erreur
```
Exception: Code incorrect
```

### ✅ Solution
```dart
// Le code doit être exactement celui reçu par SMS/USSD
// ❌ Typo ou caractères de plus
// ✅ Saisir exactement le code

// Format:
// - 6 chiffres pour Orange Money: 123456
// - 6 chiffres pour Wave: 654321
// - 4 chiffres pour Moov Money: 4321

// Vérifier que le téléphone a bien reçu le SMS
// Vérifier que le code n'a pas expiré (5 minutes généralement)

// Réessayer:
// 1. Demander un nouveau code
// 2. Saisir le nouveau code
// 3. Confirmer
```

---

## 9. Erreur: "Montant > limite maximale"

### ❌ Erreur
```
Exception: Montant doit être entre 100 et 500000 XOF
```

### ✅ Solution
```dart
// Chaque opérateur a une limite maximale par transaction

// Montants maximums:
// - Orange Money: 500,000 XOF
// - Wave: 1,000,000 XOF
// - Moov Money: 500,000 XOF
// - MTN Money: 500,000 XOF
// - Carte: 10,000,000 XOF

// Vérifier avant:
bool isValid = PaymentOperatorsManager.validateAmount(operator, amount);

// Ou obtenir la limite:
final info = PaymentOperatorsManager.getOperatorInfo(operator);
print('Max: ${info?['maxAmount']}');

// Solution: Diviser en plusieurs paiements
// Exemple: 600,000 XOF avec Orange Money
// → 1er paiement: 500,000 XOF
// → 2e paiement: 100,000 XOF
```

---

## 10. Erreur: "Pays non supporté"

### ❌ Erreur
```
Exception: Pays non supporté par Orange Money
```

### ✅ Solution
```dart
// Pays supportés par Orange Money: SN, ML, CI, CM
// Pays supportés par Wave: SN, CI, ML, BJ, TG, BF

// Vérifier les opérateurs disponibles:
List<String> ops = PaymentOperatorsManager.getAvailableOperators('SN');
// ops = ['orange_money', 'wave', 'card', ...]

// Ou utiliser la détection automatique:
String country = PaymentOperatorsManager.detectCountryFromPhone('+221701234567');
List<String> ops = PaymentOperatorsManager.getAvailableOperators(country);

// Codes pays:
// - SN = Sénégal
// - ML = Mali
// - CI = Côte d'Ivoire
// - CM = Cameroun
// - TG = Togo
// - BJ = Bénin
// - BF = Burkina Faso
```

---

## 11. Erreur: "Connexion perdue"

### ❌ Erreur
```
SocketException: Failed host lookup
```

### ✅ Solution
```dart
// Vérifier la connexion Internet:
// 1. Vérifier le WiFi/données mobiles
// 2. Redémarrer la connexion
// 3. Vérifier le serveur backend

// L'app utilise la synchronisation offline-first
// Les paiements sont en attente localement

// Vérifier l'état offline:
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityResult = await Connectivity().checkConnectivity();
if (connectivityResult == ConnectivityResult.none) {
  print('Pas de connexion');
} else {
  print('Connecté');
}

// Attendre que la connexion revienne:
// Le SyncService va resynchroniser automatiquement
```

---

## 12. Erreur: "Transaction déjà vérifiée"

### ❌ Erreur
```
Exception: Le paiement est déjà vérifié
```

### ✅ Solution
```dart
// Chaque paiement ne peut être confirmé qu'une fois
// ❌ Ne pas confirmer deux fois

// Vérifier le statut avant de confirmer:
final payment = await getPaymentStatus(paymentId);
if (payment['status'] == 'verified') {
  print('Déjà confirmé');
} else if (payment['status'] == 'pending') {
  // Confirmer maintenant
  await confirmPayment(paymentId, code);
}

// Ou attendre le polling automatique
// L'écran PaymentConfirmationScreen le fait
```

---

## 13. Erreur: "Frais incorrects"

### ❌ Erreur
```
Le total ne correspond pas: 5000 XOF vs 5050 XOF
```

### ✅ Solution
```dart
// Les frais sont dynamiques selon l'opérateur:
// - Orange Money: 1%
// - Wave: 1%
// - Moov Money: 1.5%
// - MTN Money: 1%
// - Carte: 2.5%

// Calculer correctement:
double amount = 5000;
double fees = PaymentOperatorsManager.calculateFees('moov_money', amount);
// fees = 5000 * 1.5% = 75

double total = PaymentOperatorsManager.calculateTotal('moov_money', amount);
// total = 5000 + 75 = 5075

// Afficher au client:
print('Montant: 5000 XOF');
print('Frais (1.5%): 75 XOF');
print('Total: 5075 XOF');
```

---

## 14. Erreur: "État du provider incohérent"

### ❌ Erreur
```
RangeError (index): Invalid value: Valid value range is empty
```

### ✅ Solution
```dart
// Vérifier l'initialisation du provider:
// Dans main.dart ou build():

@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // Réinitialiser les providers
    context.read<PaymentProvider>().loadPayments();
  }
}

// Ou vérifier null:
final paymentProvider = context.read<PaymentProvider>();
if (paymentProvider.selectedOperator == null) {
  paymentProvider.selectOperator('wave');
}

// Toujours vérifier les getters:
if (paymentProvider.isLoading) {
  return CircularProgressIndicator();
}
```

---

## 15. Erreur: "Widget disparu"

### ❌ Erreur
```
This widget has been unmounted
```

### ✅ Solution
```dart
// Toujours vérifier `mounted` avant setState():
if (mounted) {
  setState(() {
    _paymentStatus = 'success';
  });
}

// Ou dans les callbacks async:
Future<void> _confirmPayment() async {
  try {
    final result = await confirmPayment(paymentId, code);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Succès')),
      );
    }
  } catch (e) {
    if (mounted) {
      print('Erreur: $e');
    }
  }
}
```

---

## 🆘 Besoin d'aide?

### 1. Consultez la documentation
- `PAYMENT_SYSTEM_README.md`
- `BACKEND_ENDPOINTS_SPEC.md`
- `QUICK_START_GUIDE.md`

### 2. Vérifiez les tests
```bash
flutter test test/payment_system_test.dart
```

### 3. Activez les logs
```dart
// Dans les services
print('🔍 Debug: $value');
print('✅ Success: $result');
print('❌ Error: $error');
```

### 4. Vérifiez le backend
```bash
# Vérifier que le serveur tourne
curl http://localhost:3000/health

# Vérifier les logs
tail -f backend.log
```

---

## 📊 Checklist de Débogage

- [ ] Vérifier l'import du module
- [ ] Vérifier l'opérateur sélectionné
- [ ] Vérifier le montant (min/max)
- [ ] Vérifier le numéro de téléphone
- [ ] Vérifier la connexion Internet
- [ ] Vérifier le backend
- [ ] Vérifier les logs
- [ ] Vérifier l'état du provider
- [ ] Vérifier le mounted widget

---

**Créé par:** GitHub Copilot  
**Date:** 2025-12-10  
**Version:** 1.0.0
