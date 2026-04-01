# 🚀 Guide d'Installation et Démarrage - MuniciPay

## ✅ Prérequis

Avant de commencer, assurez-vous d'avoir:

- **Flutter SDK 3.9.2 ou plus** ([Télécharger](https://flutter.dev/docs/get-started/install))
- **Dart 3.9 ou plus** (inclus avec Flutter)
- **Un navigateur moderne** (Chrome, Edge, Safari, Firefox)
- **VS Code ou Android Studio** (optionnel pour développement)
- **Git** (pour cloner le projet)

---

## 📥 Étape 1: Vérifier Flutter/Dart

```bash
# Vérifier version de Flutter
flutter --version

# Vérifier version de Dart
dart --version

# Vérifier l'environnement
flutter doctor
```

**Résultat attendu:**
```
✓ Flutter X.X.X
✓ Dart X.X.X
✓ Chrome
✓ VS Code (optionnel)
```

---

## 📂 Étape 2: Obtenir le projet

### Option A: Cloner depuis Git
```bash
git clone <repository-url>
cd applicationweb
```

### Option B: Télécharger le dossier
```bash
# Extraire le fichier ZIP
cd d:\dossierApp\applicationweb
```

---

## 📦 Étape 3: Installer les dépendances

```bash
# Aller dans le dossier du projet
cd d:\dossierApp\applicationweb

# Installer toutes les dépendances
flutter pub get

# Cela télécharge ~150 MB de packages
# Patience... ⏳
```

**Résultat attendu:**
```
Running pub get... 
+ provider 6.1.5+1
+ hive 2.2.3
+ qr_flutter 4.1.0
... (plus de packages)

Running pub install... 
✓ Package dependencies resolved
```

---

## 🔨 Étape 4: Générer les fichiers Hive

```bash
# Générer les adapters pour les modèles
flutter pub run build_runner build --delete-conflicting-outputs

# Cela crée:
# - lib/models/tax.g.dart
# - lib/models/payment.g.dart
# - lib/models/user.g.dart
```

**Résultat attendu:**
```
[INFO] Succeeded after 10s with 9 outputs (43 actions)
```

---

## ✨ Étape 5: Vérifier la compilation

```bash
# Analyser le code pour erreurs
flutter analyze

# Formater le code
flutter format .
```

**Résultat attendu:**
```
Analyzing applicationweb...
✓ No issues found!
```

---

## 🎮 Étape 6: Lancer l'application

### Option A: Sur navigateur (RECOMMANDÉ)
```bash
# Lancer sur Chrome
flutter run -d chrome

# L'app se lance sur http://localhost:9191
# Voir l'URL exacte dans le terminal
```

### Option B: Sur simulateur/émulateur
```bash
# Lancer sur iOS Simulator
flutter run -d ios

# Lancer sur Android Emulator
flutter run -d android
```

### Option C: Lancer sans spécifier de device
```bash
# Flutter choisit automatiquement
flutter run
```

---

## ⏳ Attendre le démarrage

La première fois, cela peut prendre 1-2 minutes:

```
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...
Waiting for connection from debug service on Chrome...
Allocating controller instance for new app connection...
Waiting for iOS app to start or reconnect...
✓ Built build/web
✓ Connected to Chrome

🔥 To hot reload changes while running, press "r". 
💪 To quit, press "q".
```

---

## 🎉 L'app est maintenant en cours d'exécution!

Vous devriez voir:

1. **Écran de login** → Interface MuniciPay
2. **Boutons d'inscription/connexion** → Fonctionnels
3. **Formulaires** → Prêts à être remplis

---

## 🧪 Test rapide

### Test 1: S'inscrire
```
1. Cliquer "Pas de compte? S'inscrire"
2. Entrer:
   - Nom: "Test User"
   - Téléphone: "+225 07 12 34 56"
3. Cliquer "S'inscrire"
4. Vous arrivez à l'accueil
```

### Test 2: Payer une taxe
```
1. Cliquer sur "Taxe commerciale - 50,000 CFA"
2. Remplir:
   - Nom: "Test User"
   - Téléphone: "+225 07 12 34 56"
   - Méthode: "Mobile Money"
3. Cliquer "Confirmer le paiement"
4. Voir le reçu avec QR code
```

### Test 3: Historique
```
1. Cliquer "Historique" en bas
2. Voir votre paiement
3. Cliquer pour voir les détails
```

### Test 4: Admin
```
1. Logout (cliquer le bouton)
2. Login avec: "+2250700000000"
3. Voir le dashboard administrateur
4. Voir statistiques en temps réel
```

---

## 💻 Commandes utiles pendant le développement

```bash
# Hot reload (rechargement rapide du code)
# Dans le terminal où flutter run s'exécute, appuyez sur: r

# Hot restart (redémarrage complet)
# Appuyez sur: R

# Quitter l'app
# Appuyez sur: q

# Voir les logs
flutter logs

# Analyser le code
flutter analyze

# Formater le code
flutter format .

# Nettoyer les fichiers build
flutter clean

# Régénérer après modif de modèles
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🐛 Troubleshooting

### Problème: "Flutter command not found"
**Solution:**
```bash
# Ajouter Flutter au PATH
# Windows: Aller dans Paramètres → Variables d'environnement
# Ajouter le chemin du dossier flutter/bin
```

### Problème: "Hive box not found"
**Solution:**
```bash
# L'app ne s'est pas initialisée correctement
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### Problème: "Chrome not found"
**Solution:**
```bash
# Installer Chrome ou utiliser un autre navigateur
flutter run -d edge  # Pour Microsoft Edge
flutter run -d firefox  # Pour Firefox
```

### Problème: Port déjà utilisé
**Solution:**
```bash
# Flutter automatiquement en trouvera un autre
# Ou spécifier manuellement:
flutter run --web-port 8080
```

### Problème: Build échoue
**Solution:**
```bash
# Nettoyer et reconstruire
flutter clean
flutter pub get
flutter analyze  # Voir les erreurs
```

### Problème: "Provider not found"
**Solution:**
```bash
# Vérifier que pubspec.yaml a les dépendances
flutter pub get
flutter pub outdated
```

---

## 📱 Architecture du projet

Après installation, vous avez:

```
applicationweb/
├── android/           # Configuration Android
├── ios/              # Configuration iOS
├── lib/              # CODE PRINCIPAL
│   ├── main.dart     # Point d'entrée
│   ├── models/       # Modèles de données
│   ├── providers/    # Gestion d'état
│   ├── screens/      # Écrans
│   ├── services/     # Logique métier
│   ├── widgets/      # Composants
│   └── constants/    # Thème
├── test/             # Tests
├── pubspec.yaml      # Dépendances
└── README.md         # Documentation
```

---

## 📚 Prochaines étapes

Après vérification que tout fonctionne:

1. **Lire les README:**
   - `MUNICIPAY_README.md` - Vue d'ensemble
   - `README_FR.md` - Documentation détaillée
   - `ARCHITECTURE.md` - Architecture technique

2. **Parcourir le code:**
   - Commencer par `lib/main.dart`
   - Puis `lib/screens/login_screen.dart`
   - Puis `lib/providers/user_provider.dart`

3. **Modifier l'app:**
   - Ajouter une nouvelle fonctionnalité
   - Changer le thème
   - Ajouter une nouvelle taxe

4. **Déployer (futur):**
   - Compiler pour Web: `flutter build web`
   - Compiler pour Android: `flutter build apk`
   - Compiler pour iOS: `flutter build ios`

---

## 🌐 Déployer sur le web

### Build pour production

```bash
# Compiler l'app pour le web
flutter build web

# Cela crée un dossier build/web/
# Prêt à être déployé sur un serveur
```

### Déployer sur Firebase Hosting

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Initialiser le projet
firebase init hosting

# Déployer
firebase deploy
```

### Résultat
Votre app est accessible sur:
```
https://votre-projet.firebaseapp.com
```

---

## ✅ Checklist de démarrage

- [ ] Flutter SDK installé et vérifié
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Fichiers Hive générés (`flutter pub run build_runner build`)
- [ ] Pas d'erreurs (`flutter analyze`)
- [ ] App lance (`flutter run -d chrome`)
- [ ] Login écran s'affiche
- [ ] S'inscrire fonctionne
- [ ] Paiement fonctionne
- [ ] Dashboard admin accessible
- [ ] Historique affiche les paiements

---

## 🎓 Documentation complète

Pour comprendre le projet:

1. **QUICKSTART.md** - Résumé rapide (5 min)
2. **MUNICIPAY_README.md** - Explication complète (30 min)
3. **ARCHITECTURE.md** - Architecture technique (45 min)
4. **DEVELOPMENT_GUIDE_FR.md** - Guide développeur (1h)
5. **README_FR.md** - Référence complète

---

## 🆘 Besoin d'aide?

### Documentation Flutter
- [flutter.dev](https://flutter.dev) - Documentation officielle
- [pub.dev](https://pub.dev) - Packages Flutter

### Packages utilisés
- [Provider](https://pub.dev/packages/provider)
- [Hive](https://pub.dev/packages/hive)
- [QR Flutter](https://pub.dev/packages/qr_flutter)

### Debugging
```bash
# Afficher les logs
flutter logs

# Connecter le debugger
flutter run --release

# Analyser la performance
flutter run --profile
```

---

## 🚀 Vous êtes prêt!

```
    ╔══════════════════════════════════╗
    ║  🎉 MuniciPay est installée!    ║
    ║  ✨ Prêt pour le développement!  ║
    ╚══════════════════════════════════╝
```

**Bon développement!** 💻

---

## 📞 Questions fréquentes

**Q: Puis-je développer sur mon téléphone?**
R: Pas directement, mais vous pouvez déployer sur un appareil Android/iOS connecté via USB.

**Q: Comment modifier le thème?**
R: Éditer `lib/constants/app_theme.dart`

**Q: Comment ajouter une nouvelle page?**
R: Créer un fichier dans `lib/screens/` et ajouter la navigation.

**Q: Les données persistent-elles?**
R: Oui, Hive les sauvegarde localement. Même après redémarrage.

**Q: Comment accéder à l'admin?**
R: Téléphone: "+2250700000000"

---

**Dernière vérification:** ✅ Tout fonctionne?
```
- [ ] Login screen affichée
- [ ] S'inscrire → Accueil OK
- [ ] Paiement → Reçu OK
- [ ] Historique affiche données OK
- [ ] Admin login OK
```

Parfait! Vous êtes prêt à commencer! 🚀
