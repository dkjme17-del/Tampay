# 🎯 Système de Paiement Multicanal - MuniciPay

Documentation complète du système de paiement supportant 5 opérateurs majeurs en Afrique de l'Ouest.

## 📋 Table des Matières

1. [Architecture](#architecture)
2. [Opérateurs Supportés](#opérateurs-supportés)
3. [Utilisation](#utilisation)
4. [Services](#services)
5. [Intégration](#intégration)

---

## 🏗️ Architecture

Le système est basé sur une architecture modulaire avec les couches suivantes:

```
┌─────────────────────────────────────────────┐
│         UI Layer (Flutter Screens)          │
│  - MultiChannelPaymentScreen                │
│  - PaymentConfirmationScreen                │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│      PaymentProvider (State Management)     │
│  - createPaymentWithOperator()              │
│  - selectOperator()                         │
│  - checkTransactionStatus()                 │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│  PaymentOperatorsManager (Orchestration)    │
│  - getAvailableOperators()                  │
│  - initiateTransaction()                    │
│  - calculateFees()                          │
│  - checkTransactionStatus()                 │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│      Operator-Specific Services             │
│  - OrangeMoneyService                       │
│  - WaveService                              │
│  - MoovMoneyService                         │
│  - MTNMoneyService                          │
│  - CardPaymentService                       │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│     Backend API (Node.js/Express)           │
│  - POST /api/payments/                      │
│  - POST /api/payments/[operator]/initiate   │
│  - POST /api/payments/:id/confirm           │
│  - GET  /api/payments/:id/status            │
└──────────────┬──────────────────────────────┘
               │
┌──────────────▼──────────────────────────────┐
│      Operator APIs (Production)             │
│  - Orange Money API                         │
│  - Wave API (GraphQL)                       │
│  - Moov Money API                           │
│  - MTN Money API                            │
│  - Stripe/Flutterwave API                   │
└─────────────────────────────────────────────┘
```

---

## 🌍 Opérateurs Supportés

### 1. 🟠 Orange Money

**Pays:** Sénégal, Mali, Côte d'Ivoire, Cameroun
**Code USSD:** `#150#`
**Montant:** 100 - 500,000 XOF
**Frais:** 1%

```dart
// Exemple d'utilisation
OrangeMoneyService.initiateTransaction(
  phoneNumber: '+221701234567',
  amount: 5000,
  transactionId: 'TAX123',
  currency: 'XOF',
);
```

### 2. 🌊 Wave

**Pays:** Sénégal, Côte d'Ivoire, Mali, Bénin, Togo, Burkina Faso
**Code USSD:** `*557#`
**Montant:** 500 - 1,000,000 XOF
**Frais:** 1%

```dart
// Exemple d'utilisation
WaveService.initiateTransaction(
  phoneNumber: '+221701234567',
  amount: 5000,
  transactionId: 'TAX123',
  currency: 'XOF',
);
```

### 3. 💚 Moov Money

**Pays:** Togo, Bénin, Mali, Côte d'Ivoire
**Code USSD:** `*556#`
**Montant:** 100 - 500,000 XOF
**Frais:** 1.5%

```dart
// Exemple d'utilisation
MoovMoneyService.initiateTransaction(
  phoneNumber: '+228XX123456',
  amount: 5000,
  transactionId: 'TAX123',
  currency: 'XOF',
);
```

### 4. 🟡 MTN Money

**Pays:** Cameroun, Mali, Côte d'Ivoire, Bénin, Burkina Faso
**Code USSD:** `*156#`
**Montant:** 100 - 500,000 XOF
**Frais:** 1%

```dart
// Exemple d'utilisation
MTNMoneyService.initiateTransaction(
  phoneNumber: '+237XX123456',
  amount: 5000,
  transactionId: 'TAX123',
  currency: 'XOF',
);
```

### 5. 💳 Carte Bancaire

**Pays:** Global
**Montant:** 1,000 - 10,000,000 XOF
**Frais:** 2.5%
**Sécurité:** 3D Secure

```dart
// Exemple d'utilisation
CardPaymentService.initiateTransaction(
  cardData: CardPaymentService.CardData(
    cardNumber: '4242424242424242',
    cardHolder: 'Jean Dupont',
    expiryDate: '12/25',
    cvv: '123',
    country: 'SN',
  ),
  amount: 5000,
  transactionId: 'TAX123',
  currency: 'XOF',
);
```

---

## 💻 Utilisation

### Structure des Fichiers

```
lib/
├── services/
│   └── payment_operators/
│       ├── orange_money_service.dart
│       ├── wave_service.dart
│       ├── moov_money_service.dart
│       ├── mtn_money_service.dart
│       ├── card_payment_service.dart
│       └── payment_operators_manager.dart
├── screens/
│   ├── multi_channel_payment_screen.dart
│   ├── payment_confirmation_screen.dart
│   └── payment_integration_example.dart
└── providers/
    └── payment_provider.dart (amélioré)
```

### Flux de Paiement

#### 1. **Sélection de l'opérateur**

```dart
// Dans le provider
paymentProvider.selectOperator('orange_money');

// Obtenir les frais
double fees = paymentProvider.calculateFees(5000);
double total = paymentProvider.calculateTotal(5000);
```

#### 2. **Création du paiement**

```dart
final success = await paymentProvider.createPaymentWithOperator(
  taxId: 'TAX123',
  amount: 5000,
  operator: 'orange_money',
  operatorData: {
    'phoneNumber': '+221701234567',
  },
);
```

#### 3. **Attendre la confirmation**

```dart
// Le système vérifie automatiquement le statut
// toutes les 5 secondes via checkTransactionStatus()
```

#### 4. **Saisir le code de vérification**

```dart
// L'utilisateur entre le code reçu
final verified = await paymentProvider.verifyPayment(
  paymentId,
  verificationCode: '123456',
);
```

---

## 🛠️ Services

### PaymentOperatorsManager

Service centralisé pour gérer tous les opérateurs.

```dart
// Obtenir les opérateurs disponibles pour un pays
List<String> operators = 
  PaymentOperatorsManager.getAvailableOperators('SN');

// Valider un montant pour un opérateur
bool isValid = 
  PaymentOperatorsManager.validateAmount('orange_money', 5000);

// Calculer les frais
double fees = 
  PaymentOperatorsManager.calculateFees('orange_money', 5000);

// Initier une transaction
Map<String, dynamic> transaction = 
  PaymentOperatorsManager.initiateTransaction(
    operator: 'wave',
    data: {
      'phoneNumber': '+221701234567',
      'amount': 5000,
      'transactionId': 'TAX123',
    },
  );

// Vérifier le statut
Map<String, dynamic> status = 
  PaymentOperatorsManager.checkTransactionStatus(
    'orange_money',
    'OM-1234567890',
  );

// Annuler une transaction
PaymentOperatorsManager.cancelTransaction('wave', 'WAVE-1234567890');
```

### CardPaymentService

Validation complète des cartes bancaires.

```dart
// Valider le numéro avec Luhn
bool isValid = CardPaymentService.validateCardNumber('4242424242424242');

// Valider la date d'expiration
bool isValid = CardPaymentService.validateExpiryDate('12/25');

// Valider le CVV
bool isValid = CardPaymentService.validateCVV('123');

// Détecter le type de carte
String type = CardPaymentService.detectCardType('4242424242424242'); // 'Visa'

// Formater pour l'affichage
String formatted = CardPaymentService.formatCardNumber('4242424242424242');
// Résultat: 'xxxx-xxxx-xxxx-4242'

// Tokeniser la carte (production)
String token = await CardPaymentService.tokenizeCard(cardData);
```

---

## 🔌 Intégration

### Exemple Simple

```dart
// Dans votre écran
import 'package:provider/provider.dart';
import '../screens/multi_channel_payment_screen.dart';

// Appeler l'écran de paiement
final result = await Navigator.of(context).push<bool>(
  MaterialPageRoute(
    builder: (context) => MultiChannelPaymentScreen(
      taxId: 'TAX123',
      taxName: 'Taxe d\'Eau',
      amount: 5000,
      userCountry: 'SN',
    ),
  ),
);

if (result == true) {
  // Paiement réussi
  print('✅ Paiement effectué');
}
```

### Intégration avec Provider

```dart
class MyPaymentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, _) {
        return Column(
          children: [
            // Sélection de l'opérateur
            DropdownButton<String>(
              value: paymentProvider.selectedOperator,
              items: PaymentOperatorsManager.supportedOperators
                  .map((op) => DropdownMenuItem(
                    value: op,
                    child: Text(op),
                  ))
                  .toList(),
              onChanged: (op) {
                if (op != null) {
                  paymentProvider.selectOperator(op);
                }
              },
            ),

            // Afficher les frais
            if (paymentProvider.selectedOperator != null)
              Text('Frais: ${paymentProvider.calculateFees(5000)} XOF'),

            // Bouton de paiement
            ElevatedButton(
              onPressed: () {
                paymentProvider.createPaymentWithOperator(
                  taxId: 'TAX123',
                  amount: 5000,
                  operator: paymentProvider.selectedOperator!,
                  operatorData: {'phoneNumber': '+221701234567'},
                );
              },
              child: const Text('Payer'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 📊 Statistiques des Paiements

```dart
// Récupérer les statistiques globales
Map<String, dynamic> stats = paymentProvider.statistics;

// Informations disponibles
int totalPayments = paymentProvider.totalPayments;
double totalRevenue = paymentProvider.totalRevenue;
int completedPayments = paymentProvider.completedPayments;
int verifiedPayments = paymentProvider.verifiedPayments;

// Par opérateur
int orangeMoney = stats['byProvider']['orangeMoney'];
int wave = stats['byProvider']['wave'];
int moovMoney = stats['byProvider']['moovMoney'];
int mtnMoney = stats['byProvider']['mtnMoney'];
int card = stats['byProvider']['card'];
```

---

## 🔐 Sécurité

### Bonnes Pratiques

1. **Numéros de carte**: NE JAMAIS stocker directement
   - Utiliser Stripe/Flutterwave pour la tokenization
   - Stocker uniquement les derniers 4 chiffres + token

2. **3D Secure**: Toujours utiliser pour les cartes
   - Confirmation via l'application bancaire
   - Protège contre les fraudes

3. **Vérification du code**: Toujours exiger le code OTP
   - Envoyé par l'opérateur au téléphone
   - Valider côté serveur

4. **HTTPS**: Toujours utiliser pour les requêtes API
   - Chiffrement des données en transit

---

## 📈 Prochaines Étapes

1. **Intégration réelle des APIs**
   - Remplacer les mocks par les véritables APIs des opérateurs
   - Ajouter gestion des erreurs spécifiques

2. **Webhooks**
   - Recevoir les confirmations en temps réel des opérateurs

3. **Reçus PDF**
   - Générer et télécharger les reçus de paiement

4. **Historique détaillé**
   - Dashboard admin avec filtres par opérateur, date, statut

5. **Notifications**
   - Email et SMS de confirmation
   - Notifications push in-app

---

## 📞 Support

Pour toute question, contactez: support@municipay.local

**Dernière mise à jour:** 2025-12-10
**Version:** 1.0.0 (MVP)
