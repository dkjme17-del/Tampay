# 🏛️ TamPay- Application de Gestion des Taxes Locales

## 📋 Vue d'ensemble

**TamPay** est une application mobile Flutter complète conçue pour digitaliser le paiement des taxes locales dans les communes. Cette solution élimine la fraude, améliore la traçabilité et augmente les recettes municipales.

### 🎯 Problème résolu

- ❌ **Avant**: Les commerçants payaient plusieurs fois la même taxe faute de traçabilité
- ❌ **Avant**: Les agents collecteurs ne versaient pas correctement l'argent à la mairie
- ❌ **Avant**: Perte de milliards due à la corruption et au manque de digitalisation

### ✅ Solution apportée

- ✅ **Paiement numérique** avec trace complète
- ✅ **QR code vérifiable** par les agents de contrôle
- ✅ **Dashboard administrateur** en temps réel
- ✅ **Historique sécurisé** de tous les paiements
- ✅ **Zéro fraude** grâce à la traçabilité complète

---

## 🚀 Démarrage rapide

### Prérequis
- Flutter SDK 3.9.2+
- Dart 3.9+
- Un navigateur moderne (Chrome, Edge, Safari, Firefox)

### Installation

```bash
# Cloner ou télécharger le projet
cd d:\dossierApp\applicationweb

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run -d chrome
```

### L'app se lance sur http://localhost:xxxx 🎉

---

## 📱 Fonctionnalités principales

### 👤 Espace Citoyen/Commerçant

#### 1️⃣ **Inscription & Connexion**
- Inscription rapide avec nom + téléphone
- Connexion sécurisée par numéro
- Création automatique de compte

#### 2️⃣ **Consultation des taxes**
- Liste de toutes les taxes disponibles
- Montant de chaque taxe
- Zone/quartier concerné
- Description détaillée

#### 3️⃣ **Paiement de taxe**
- Confirmation du montant
- Saisie du nom et téléphone
- Choix de la méthode (Mobile Money/Carte/Virement)
- Génération du reçu avec QR code

#### 4️⃣ **Reçu électronique**
- QR code vérifiable
- ID de paiement unique
- Montant et date
- Informations du payeur

#### 5️⃣ **Historique des paiements**
- Tous les paiements effectués
- Statut de chaque paiement
- Montants et dates
- Détails au clic

### 👨‍💼 Espace Administrateur Municipal

#### Dashboard Principal
- 💰 Recettes totales collectées
- 📊 Nombre total de paiements
- ✓ Paiements complétés
- ⏳ Paiements en attente
- ✅ Paiements vérifiés

#### Gestion des paiements
- Filtrage par statut
- Liste complète des transactions
- Informations du payeur
- Zone et montant
- Actions de vérification

---

## 🏗️ Architecture technique

### Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── constants/
│   └── app_theme.dart          # Thème et couleurs
├── models/                       # Modèles de données
│   ├── tax.dart                # 🏛️ Taxe
│   ├── payment.dart            # 💳 Paiement
│   └── user.dart               # 👤 Utilisateur
├── services/
│   ├── database_service.dart    # Hive
│   └── qrcode_service.dart      # QR Codes
├── providers/                    # Gestion d'état
│   ├── tax_provider.dart
│   ├── payment_provider.dart
│   └── user_provider.dart
├── screens/                      # Pages
│   ├── login_screen.dart        # 🔐 Login
│   ├── home_screen.dart         # 🏠 Accueil
│   ├── payment_screen.dart      # 💸 Paiement
│   ├── history_screen.dart      # 📋 Historique
│   └── admin_dashboard_screen.dart  # 📊 Admin
└── widgets/
    └── custom_widgets.dart      # Composants
```

### Stack technique

- **Framework**: Flutter 3.9+
- **Langage**: Dart
- **Gestion d'état**: Provider 6.1.5
- **Base de données**: Hive 2.2.3 (stockage local)
- **QR Codes**: qr_flutter 4.1.0
- **Design**: Material Design 3

---

## 📊 Modèles de données

### Tax (Taxe)
```dart
id: "uuid-unique"
name: "Taxe commerciale"
amount: 50000 (CFA)
category: "commerce"
zone: "Centre-Ville"
```

### Payment (Paiement)
```dart
id: "paiement-001"
taxId: "tax-uuid"
amount: 50000
status: "completed" // pending, completed, verified
qrCode: "base64_data"
paymentDate: 2025-12-10
method: "mobile_money"
zone: "Centre-Ville"
```

### User (Utilisateur)
```dart
id: "user-uuid"
name: "Jean Dupont"
phone: "+225 07 12 34 56"
role: "citizen" // citizen, admin, collector, agent
zone: "Centre-Ville"
```

---

## 🎮 Guide d'utilisation

### Citoyen paie une taxe

```
1. Démarrage → Login
2. Inscription (nom + téléphone)
3. Accueil → Sélectionner une taxe
4. Paiement → Remplir formulaire
5. Confirmation → Reçu + QR code
6. Historique → Voir tous les paiements
```

### Admin vérifie les paiements

```
1. Login avec +2250700000000
2. Voir le dashboard
3. Voir statistiques en temps réel
4. Filtrer les paiements
5. Cliquer pour vérifier
6. Marquer comme "Vérifié"
```

---

## 💾 Données initiales

### Taxes de test
1. **Taxe commerciale** - 50,000 CFA
2. **Taxe de transport** - 30,000 CFA
3. **Taxe artisanale** - 25,000 CFA
4. **Taxe de circulation** - 15,000 CFA

### Admin test
- **Téléphone**: +2250700000000
- **Rôle**: Administrateur

---

## 🎨 Design

### Couleurs
- 🔵 Bleu (#2563EB) - Principal
- 🟢 Vert (#10B981) - Succès
- 🟠 Orange (#F59E0B) - Avertissement
- 🔴 Rouge (#EF4444) - Erreur

---

## 🔒 Sécurité

### Implémentées
✅ QR codes uniques  
✅ Codes de vérification MD5  
✅ Traçabilité complète  
✅ Profils utilisateur distincts  

### À venir
🔄 Authentification JWT  
🔄 Chiffrement  
🔄 Validation serveur  
🔄 Logs d'audit  

---

## 🚀 Roadmap

### Phase 2: Backend & API (Décembre 2025)
- Node.js/Express
- PostgreSQL
- Authentification JWT
- Intégration paiements réels

### Phase 3: Avancé (Janvier 2026)
- Scanner QR code
- Export PDF
- Multi-langue
- Mode hors ligne

### Phase 4: Production (Février 2026)
- Tests complets
- Optimisation
- PlayStore/AppStore
- Support utilisateur

---

## 📞 Support

### Documentation
- [Dart Docs](https://dart.dev)
- [Flutter Docs](https://flutter.dev)
- [Hive Docs](https://docs.hivedb.dev)
- [Provider Package](https://pub.dev/packages/provider)

### Troubleshooting

**Hive box not found**
```bash
# S'assurer que DatabaseService.initDatabase() 
# est appelé dans main()
```

**Provider not found**
```bash
# Vérifier que MultiProvider enveloppe l'app
```

**Hot reload ne fonctionne pas**
```bash
# Appuyer 'R' pour hot restart complet
```

---

## 📝 Développement

### Fichiers générés
```
lib/models/tax.g.dart
lib/models/payment.g.dart
lib/models/user.g.dart
```

### Régénérer après modification
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 📈 Métriques

Le dashboard admin affiche:
- Recettes totales (mise à jour en temps réel)
- Nombre total de paiements
- Paiements par statut
- Statistiques par zone
- Analyse par période

---

## 🌍 Contexte africain

✅ Pas besoin Internet permanent  
✅ Compatible Mobile Money  
✅ Interface intuitive  
✅ Fonctionne sur téléphones basiques  
✅ Multi-langue  
✅ Coût réduit  

---

## 🎯 Impact attendu

```
AVANT (Manuel)           APRÈS (MuniciPay)
─────────────────────   ─────────────────────
Fraude massive    →     Zéro fraude
Perte de milliards →    +30% revenus
Pas de traçabilité →    Traçabilité 100%
Corruption        →     Transparence totale
```

---

## 👥 Équipe

Développé dans le cadre d'un hackathon sur la digitalisation des taxes locales en Afrique de l'Ouest.

---

**Créé avec ❤️ pour une meilleure traçabilité fiscale** 🚀

Merci d'utiliser MuniciPay!

Admin créé avec succès:
{
  id: '7c68d5c0-66d9-4d71-9229-ddaa1c622c84',
  name: 'Admin Test',
  phone: '+2250700000000',
  email: 'admin@municipay.ci',
  zone: 'Centre-Ville',
  password: 'adminpass'
}