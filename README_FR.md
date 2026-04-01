# 🏛️ MuniciPay - Gestion Numérique des Taxes Locales

Une application Flutter complète pour digitaliser le paiement des taxes locales et éliminer la fraude.

## ✨ Fonctionnalités principales

### 👤 Pour les Citoyens/Commerçants
- ✅ Inscription et connexion sécurisée
- 💳 Paiement numérique des taxes (Mobile Money, Carte, Virement)
- 📱 Génération automatique de QR code pour chaque paiement
- 📜 Reçu électronique instantané
- 📋 Historique complet des paiements
- 🔍 Traçabilité totale

### 👨‍💼 Pour les Administrateurs Municipaux
- 📊 Tableau de bord en temps réel
- 📈 Statistiques détaillées (revenus, zones, métiers)
- ✓ Vérification des paiements via QR code
- 🎯 Filtrage par statut (complété, en attente, vérifié)
- 📍 Analyse par zone/quartier
- 🚨 Alertes de fraude potentielle

## 🛠️ Architecture

```
lib/
├── main.dart              # Point d'entrée + initialisation
├── constants/
│   └── app_theme.dart     # Thème et constants UI
├── models/
│   ├── tax.dart           # Modèle de taxe
│   ├── payment.dart       # Modèle de paiement
│   └── user.dart          # Modèle utilisateur
├── providers/
│   ├── tax_provider.dart       # Gestion d'état taxes
│   ├── payment_provider.dart   # Gestion d'état paiements
│   └── user_provider.dart      # Gestion d'état utilisateurs
├── services/
│   ├── database_service.dart   # Accès base de données Hive
│   └── qrcode_service.dart     # Génération/vérification QR
├── screens/
│   ├── login_screen.dart       # Connexion/Inscription
│   ├── home_screen.dart        # Écran d'accueil
│   ├── payment_screen.dart     # Paiement de taxe
│   ├── history_screen.dart     # Historique paiements
│   └── admin_dashboard_screen.dart  # Tableau de bord admin
└── widgets/
    └── custom_widgets.dart     # Widgets réutilisables
```

## 🚀 Démarrage rapide

### 1. **Installer les dépendances**
```bash
cd applicationweb
flutter pub get
```

### 2. **Générer les fichiers Hive** (déjà fait)
```bash
flutter pub run build_runner build
```

### 3. **Lancer l'application**
```bash
flutter run
```

## 📱 Comptes de Test

### Utilisateur Citoyen
- **Numéro**: +225 XXXXXXXXXX (N'importe quel numéro)
- **Nom**: Entrez un nom quelconque
- **Rôle**: Citoyen

### Administrateur Municipal
- **Numéro**: +2250700000000
- **Mot de passe**: (pas de mot de passe pour le MVP)
- **Rôle**: Admin

## 🎯 Flux d'utilisation

### Pour un Citoyen
1. S'inscrire ou se connecter
2. Sélectionner une taxe à payer
3. Remplir ses informations
4. Choisir une méthode de paiement
5. Confirmer le paiement
6. Recevoir le QR code et le reçu
7. Consulter l'historique

### Pour un Admin
1. Se connecter avec +2250700000000
2. Voir le dashboard avec les stats
3. Filtrer les paiements par statut
4. Scanner les QR codes (futur)
5. Marquer les paiements comme vérifiés

## 💾 Base de Données

L'application utilise **Hive** pour le stockage local:

- **Taxes**: Types de taxes disponibles
- **Paiements**: Historique des transactions
- **Utilisateurs**: Profils des citoyens et admins

### Initialisation de test
Au premier lancement, l'app crée automatiquement:
- 4 taxes d'exemple (commerce, transport, artisan, circulation)
- 1 utilisateur admin pour tester le dashboard

## 🔐 Sécurité

- ✅ QR codes uniques et vérifiables
- ✅ Numérotation séquentielle des paiements
- ✅ Codes de vérification MD5
- ✅ Validation côté serveur (à implémenter avec backend)
- ✅ Traçabilité complète

## 📊 Statistiques disponibles

Le dashboard admin affiche:
- **Recettes totales**: Somme de tous les paiements complétés
- **Nombre total de paiements**: 
- **Paiements complétés**: Transactions validées
- **Paiements en attente**: En cours de traitement
- **Paiements vérifiés**: Confirmés par un agent

## 🔧 Customisation

### Modifier le thème
```dart
// constants/app_theme.dart
static const primaryColor = Color(0xFF2563EB);  // Bleu
static const secondaryColor = Color(0xFF10B981); // Vert
```

### Ajouter de nouvelles taxes
Dans `main.dart`, modifiez `_initializeTestData()`:
```dart
Tax(
  id: uuid.v4(),
  name: 'Nouvelle taxe',
  description: 'Description',
  amount: 50000,
  category: 'categorie',
  zone: 'Zone',
)
```

## 📱 Dépendances principales

- **flutter_provider**: Gestion d'état
- **hive**: Base de données locale
- **qr_flutter**: Génération QR codes
- **google_fonts**: Typographie
- **uuid**: Génération d'IDs uniques

## 🚀 Prochaines étapes

### Phase 2: Backend
- [ ] API REST (Node.js/Express)
- [ ] Base de données (PostgreSQL)
- [ ] Authentification JWT
- [ ] Intégration paiements réels

### Phase 3: Fonctionnalités avancées
- [ ] Scanner QR codes avec caméra
- [ ] Notifications push
- [ ] Export rapports PDF
- [ ] Multi-langue
- [ ] Mode hors ligne avancé

### Phase 4: Déploiement
- [ ] Optimisation performance
- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] Release Android/iOS
- [ ] PlayStore/AppStore

## 📞 Support

Pour toute question, consultez:
- La documentation Flutter: https://flutter.dev/docs
- Hive: https://docs.hivedb.dev
- Provider: https://pub.dev/packages/provider

## 📄 Licence

Projet hackathon - 2025

---

**Créé avec ❤️ pour une meilleure traçabilité fiscale**
