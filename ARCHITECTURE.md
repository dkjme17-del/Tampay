# 🏗️ Architecture et Design MuniciPay

## Vue d'ensemble de l'architecture

```
┌─────────────────────────────────────────────────────────┐
│                   UI Layer (Screens)                     │
│  LoginScreen | HomeScreen | PaymentScreen | etc...      │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────┐
│              State Management (Providers)                │
│  TaxProvider | PaymentProvider | UserProvider           │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────┐
│               Business Logic (Services)                  │
│  DatabaseService | QRCodeService                        │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────┐
│                 Data Layer (Models)                      │
│              Tax | Payment | User                        │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────┴──────────────────────────────────┐
│             Storage Layer (Hive Database)               │
│         Persistent local storage with encryption        │
└─────────────────────────────────────────────────────────┘
```

---

## 1. 📱 UI Layer (Screens)

### Responsabilités
- Affichage des données
- Capture des interactions utilisateur
- Appel des providers
- Navigation

### Écrans principaux

```
LoginScreen
├─ Inscription
│  ├─ Saisie: Nom + Téléphone
│  └─ Action: Créer compte
└─ Connexion
   ├─ Saisie: Téléphone
   └─ Action: Se connecter

HomeScreen (Citoyen)
├─ Bienvenue
├─ Affichage des taxes
│  ├─ Taxe 1: Montant, Zone
│  ├─ Taxe 2: Montant, Zone
│  └─ ...
└─ Navigation

PaymentScreen
├─ Résumé du paiement
├─ Formulaire
│  ├─ Nom, Téléphone
│  └─ Méthode de paiement
└─ Reçu QR

HistoryScreen
├─ Liste paiements
└─ Détails au clic

AdminDashboardScreen
├─ Statistiques
├─ Tableau de paiements
└─ Actions de vérification
```

---

## 2. 🧠 State Management (Providers)

### Pattern utilisé: ChangeNotifier + Provider

```dart
// Exemple structure
class TaxProvider extends ChangeNotifier {
  List<Tax> _taxes = [];
  Tax? _selectedTax;
  
  List<Tax> get taxes => _taxes;
  Tax? get selectedTax => _selectedTax;
  
  void setSelectedTax(Tax tax) {
    _selectedTax = tax;
    notifyListeners();  // Notify UI
  }
}
```

### Les 3 Providers

#### 1. TaxProvider
```dart
Responsabilités:
├─ Charger les taxes
├─ Filtrer par catégorie
├─ Filtrer par zone
└─ Gérer la sélection
```

#### 2. PaymentProvider
```dart
Responsabilités:
├─ Ajouter un paiement
├─ Filtrer par statut
├─ Filtrer par zone
├─ Calculer les revenus
└─ Mettre à jour statut
```

#### 3. UserProvider
```dart
Responsabilités:
├─ Gérer la connexion
├─ Gérer l'inscription
├─ Gérer le logout
└─ Vérifier les droits (admin/citoyen)
```

### Avantages
✅ Reactive (réactif aux changements)  
✅ Testable (MockProvider)  
✅ Découplé (Screens ne connaissent pas Services)  
✅ Performant (écoute sélective)  

---

## 3. 💼 Business Logic (Services)

### DatabaseService

```dart
// Singleton pattern
static Box<Tax> getTaxBox()
static Future<void> addTax(Tax tax)
static List<Tax> getAllTaxes()
static List<Payment> getPaymentsByStatus(String status)
```

**Responsabilités:**
- Initialiser Hive
- CRUD operations (Create, Read, Update, Delete)
- Requêtes filtrées
- Transactions

### QRCodeService

```dart
static String generateQRCode(...)
static Map<String, dynamic>? decodeQRCode(...)
static String _generateVerificationCode(...)
```

**Responsabilités:**
- Générer codes QR uniques
- Vérifier codes QR
- Générer codes de vérification
- Encoder/décoder données

---

## 4. 📦 Data Models

### Hiérarchie des modèles

```
HiveObject (Hive base class)
├─ Tax
├─ Payment
└─ User
```

### Tax Model
```dart
@HiveType(typeId: 0)
class Tax extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String description;
  @HiveField(3) double amount;
  @HiveField(4) String category;
  @HiveField(5) String zone;
}
```

### Payment Model
```dart
@HiveType(typeId: 1)
class Payment extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String taxId;
  @HiveField(2) String taxName;
  @HiveField(3) double amount;
  @HiveField(4) DateTime paymentDate;
  @HiveField(5) String paymentMethod;
  @HiveField(6) String status;
  @HiveField(7) String qrCode;
  // ... plus de champs
}
```

### User Model
```dart
@HiveType(typeId: 2)
class User extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String name;
  @HiveField(2) String phone;
  @HiveField(3) String email;
  @HiveField(4) String role;  // citizen, admin, etc.
  @HiveField(5) String zone;
  @HiveField(6) DateTime registrationDate;
}
```

### Annotations Hive
```dart
@HiveType(typeId: X)  // ID unique pour chaque modèle
  ↓
@HiveField(0)         // Index du champ dans la BD
  ↓
.g.dart               // Fichier généré par build_runner
```

---

## 5. 💾 Storage Layer (Hive)

### Pourquoi Hive?

| Critère | Hive | SQLite | SharedPrefs |
|---------|------|--------|-------------|
| Vitesse | ⚡⚡⚡ Très rapide | ⚡⚡ Rapide | ⚡⚡⚡ Très rapide |
| Objets Dart | ✅ Natif | ❌ JSON | ❌ Primitifs |
| Complexité | 🟢 Simple | 🟠 Moyen | 🟢 Simple |
| Requêtes | 🟠 Basiques | 🟢 Avancées | ❌ Aucune |
| Mobile | 🟢 Optimisé | 🟢 Optimisé | 🟢 Optimisé |

### Structure des données

```
Hive Storage
├─ Box<Tax>
│  └─ taxId_001 → Tax object
│  └─ taxId_002 → Tax object
│  └─ ...
├─ Box<Payment>
│  └─ payment_001 → Payment object
│  └─ payment_002 → Payment object
│  └─ ...
└─ Box<User>
   └─ user_001 → User object
   └─ user_002 → User object
   └─ ...
```

### Avantages
✅ Type-safe (pas de conversions JSON)  
✅ Ultra-rapide (indexing)  
✅ Offline-first (données locales)  
✅ Chiffrement disponible  
✅ Zéro configuration  

---

## 6. 🎨 Widget Layer

### Widgets réutilisables

```dart
CustomCard
├─ Elevation
├─ Background Color
├─ Padding
└─ OnTap callback

TaxCard
├─ Tax name
├─ Description
├─ Amount
├─ Zone badge
└─ OnTap action

PaymentCard
├─ Tax name
├─ Amount
├─ Date
├─ Status badge
└─ OnTap action
```

### Avantages
✅ DRY (Don't Repeat Yourself)  
✅ Cohérence visuelle  
✅ Maintenance simplifiée  
✅ Réutilisable entre écrans  

---

## 7. 🔀 Flux de données

### Scénario: Paiement d'une taxe

```
1. USER INTERACTION
   └─ Clique sur "Taxe commerciale"

2. UI → PROVIDER
   └─ TaxProvider.setSelectedTax(tax)

3. PROVIDER → SCREEN
   └─ notifyListeners() → rebuild

4. USER FILLS FORM
   └─ Nom, Téléphone, Méthode

5. UI → SERVICE
   └─ PaymentScreen._processPayment()

6. SERVICE → BUSINESS LOGIC
   ├─ QRCodeService.generateQRCode()
   ├─ QRCodeService.generatePaymentId()
   └─ Payment object created

7. SERVICE → STORAGE
   └─ DatabaseService.addPayment(payment)

8. STORAGE → HIVE
   └─ payment saved to database

9. SERVICE → PROVIDER
   └─ PaymentProvider.addPayment()

10. PROVIDER → UI
    └─ notifyListeners() → show receipt

11. USER SEES RECEIPT
    └─ QR code + Payment details
```

---

## 8. 🔒 Sécurité

### Implémentées

```
┌─ Authentification
│  ├─ Téléphone unique (ID utilisateur)
│  └─ Profil distinctif (admin/citoyen)
│
├─ Intégrité
│  ├─ UUID uniques pour paiements
│  ├─ MD5 code de vérification
│  └─ QR code vérifiable
│
├─ Immuabilité
│  ├─ Payment immutable après création
│  ├─ Historique complet
│  └─ Aucun paiement supprimable
│
└─ Traçabilité
   ├─ Tous les paiements loggés
   ├─ Metadata (date, heure, zone)
   └─ Audit trail possible
```

### À implémenter

```
├─ Chiffrement local (AES)
├─ JWT tokens (serveur)
├─ HTTPS (serveur)
├─ Rate limiting
└─ 2FA (future)
```

---

## 9. 📊 État global de l'app

### Hiérarchie des Providers

```
MaterialApp
└─ MultiProvider
   ├─ ChangeNotifierProvider(TaxProvider)
   ├─ ChangeNotifierProvider(PaymentProvider)
   └─ ChangeNotifierProvider(UserProvider)
       └─ Accessible dans tous les écrans
          via context.read<Provider>()
```

### Transitions d'état

```
NOT_LOGGED_IN
├─ Voir LoginScreen
├─ Action: Inscription ou Connexion
└─ ↓ UserProvider.login() / register()

LOGGED_IN (CITOYEN)
├─ Voir HomeScreen
├─ Voir taxes disponibles
├─ Sélectionner → PaymentScreen
├─ Payer → Receipt Dialog
├─ Histoire → HistoryScreen
└─ ↓ Continuer ou Logout

LOGGED_IN (ADMIN)
├─ Voir AdminDashboardScreen
├─ Voir statistiques
├─ Filtrer paiements
├─ Vérifier transactions
└─ ↓ Actions de gestion

LOGOUT
├─ UserProvider.logout()
└─ ↓ Retour à LoginScreen
```

---

## 10. 🚀 Performance

### Optimisations en place

```
UI Rendering
├─ ListView.builder (lazy loading)
├─ NeverScrollableScrollPhysics (imbrication)
└─ Const widgets

State Management
├─ Selective listening (Selector patterns)
├─ Lazy initialization (Providers)
└─ Memoization

Data Layer
├─ Hive indexing (ultra-rapide)
├─ In-memory caching
└─ Efficient queries
```

### Benchmarks attendus

```
Login:                    < 500ms
Page load:                < 200ms
Payment submission:       < 1s
UI rebuild:              60 FPS
Memory usage:            < 50MB
```

---

## 11. 🧪 Testabilité

### Facile à tester

```dart
// Créer un MockProvider
class MockPaymentProvider extends Mock 
  implements PaymentProvider {}

// Créer un MockDatabase
class MockDatabaseService extends Mock 
  implements DatabaseService {}

// Test UI
testWidgets('Payment screen displays amount', (tester) async {
  final mockProvider = MockPaymentProvider();
  // ...
});
```

### Layers à tester

```
UI Layer       → Widget tests
Provider Layer → Unit tests
Service Layer  → Unit tests
Model Layer    → Unit tests
```

---

## 12. 🔄 Cycle de vie

### App lifecycle

```
main()
├─ DatabaseService.initDatabase()
├─ _initializeTestData()
└─ runApp(MyApp())
    ├─ MultiProvider initialized
    ├─ LoginScreen shown
    └─ App ready

User interaction
├─ Screens receive events
├─ Providers update state
├─ UI rebuilds
└─ Hive persists data

Logout
├─ UserProvider.logout()
├─ Reset state
└─ Show LoginScreen

Restart app
├─ Load from Hive
├─ Restore state
└─ Show last screen
```

---

## 13. 📈 Scalabilité

### Ajout d'une nouvelle feature

```
1. Créer le modèle
   └─ models/new_feature.dart

2. Créer le provider
   └─ providers/new_provider.dart

3. Ajouter au MultiProvider
   └─ main.dart

4. Créer l'écran
   └─ screens/new_screen.dart

5. Implémenter la logique
   └─ Utiliser DatabaseService

6. Ajouter la navigation
   └─ Depuis HomeScreen
```

---

## 14. 🎯 Pattern Summary

| Pattern | Où? | Pourquoi? |
|---------|-----|----------|
| **MVVM** | Providers + Screens | Séparation UI/Logique |
| **Singleton** | DatabaseService | Instance unique |
| **Factory** | QRCodeService | Construction objects |
| **Observer** | ChangeNotifier | Reactive updates |
| **Repository** | DatabaseService | Abstraction données |

---

## 15. 📚 Dépendances entre couches

```
Screens
   ↓ (depends on)
Providers
   ↓ (depends on)
Services
   ↓ (depends on)
Models
   ↓ (depends on)
Hive Storage

⚠️ JAMAIS le contraire!
Hive n'appelle jamais Screens
```

---

## 🎓 Conclusion

MuniciPay utilise une **architecture propre et professionnelle** idéale pour:
- ✅ Maintenance à long terme
- ✅ Évolution facile
- ✅ Testing complet
- ✅ Performance
- ✅ Scalabilité

**Prête pour production avec optimisations!**
