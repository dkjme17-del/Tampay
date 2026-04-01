# 👥 Guide de Contribution - MuniciPay

Ce document explique comment contribuer au projet MuniciPay et maintenir la qualité du code.

---

## 📋 Table des matières

1. [Code de conduite](#code-de-conduite)
2. [Avant de commencer](#avant-de-commencer)
3. [Processus de contribution](#processus-de-contribution)
4. [Standards de code](#standards-de-code)
5. [Structure des branches](#structure-des-branches)
6. [Pull Requests](#pull-requests)
7. [Reporting de bugs](#reporting-de-bugs)
8. [Tests](#tests)
9. [Documentation](#documentation)
10. [FAQ](#faq)

---

## 🤝 Code de conduite

Tous les contributeurs doivent:

- ✅ Respecter les autres membres de l'équipe
- ✅ Utiliser une communication constructive
- ✅ Signaler les bugs de manière respectueuse
- ✅ Accepter les critiques du code positivement
- ✅ Maintenir la confidentialité des données de test

**Toute violation** peut résulter en exclusion du projet.

---

## 🚀 Avant de commencer

### 1. Environnement de développement

```bash
# Fork le repository
git clone <votre-fork>
cd applicationweb

# Créer une branche de développement
git checkout -b feature/ma-fonctionnalite

# Installer les dépendances
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Vérifier que tout fonctionne
flutter analyze
```

### 2. Votre profil Git

```bash
git config user.name "Votre Nom"
git config user.email "votre.email@example.com"
```

### 3. Lire la documentation

- [ ] `MUNICIPAY_README.md` - Vue d'ensemble du projet
- [ ] `ARCHITECTURE.md` - Comprendre l'architecture
- [ ] `README_FR.md` - Documentation détaillée

---

## 📝 Processus de contribution

### Étape 1: Créer une issue

Avant de commencer le code, créez une issue pour discuter:

```markdown
## Description
Courte description de ce que vous voulez faire

## Contexte
Pourquoi c'est important?

## Solution proposée
Comment vous allez le faire?

## Critères d'acceptation
- [ ] Critère 1
- [ ] Critère 2
- [ ] Critère 3
```

### Étape 2: Créer une branche

```bash
# Créer à partir de main
git checkout main
git pull origin main

# Créer votre branche
git checkout -b feature/nom-descriptif
# ou
git checkout -b bugfix/nom-du-bug
# ou
git checkout -b docs/mise-a-jour-docs
```

### Étape 3: Développer

```bash
# Développer votre fonctionnalité
# ...

# Tester régulièrement
flutter analyze
flutter run

# Commit souvent avec messages clairs
git add .
git commit -m "feat: ajouter la fonction de vérification"
```

### Étape 4: Push et Pull Request

```bash
# Pusher votre branche
git push origin feature/nom-descriptif

# Créer une Pull Request sur GitHub
# Décrire vos changements en détail
```

### Étape 5: Révision et merge

- 👀 Un mainteneur révise votre code
- 💬 Discussions possibles et modifications
- ✅ Merge après approbation

---

## 💻 Standards de code

### Convention de nommage

#### Fichiers
```
✓ user_provider.dart      (snake_case)
✓ UserProvider           (pour les classes)
✓ lib/screens/           (répertoires en minuscules)
✗ UserProvider.dart      (pas de camelCase)
```

#### Variables et fonctions
```dart
// ✓ Bon
String userName = "Ahmed";
void loadUserData() { }
Future<void> performPayment() { }

// ✗ Mauvais
String UserName = "Ahmed";
void load_user_data() { }
Future loadUserData() { }
```

#### Constantes
```dart
// ✓ Bon
static const String APP_NAME = "MuniciPay";
static const double DEFAULT_PADDING = 16.0;

// ✗ Mauvais
static const String appName = "MuniciPay";
static const double defaultPadding = 16.0;
```

### Style de code

#### Indentation et formatage
```bash
# Formater automatiquement
flutter format .

# Ou un fichier spécifique
flutter format lib/main.dart
```

#### Imports
```dart
// 1. Dart imports
import 'dart:async';
import 'dart:convert';

// 2. Package imports
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 3. Relative imports
import '../models/user.dart';
import '../services/database_service.dart';
```

#### Espacement
```dart
// ✓ Bon
class User {
  final String name;
  final String phone;

  User({required this.name, required this.phone});
}

// ✗ Mauvais (pas d'espace)
class User{final String name;final String phone;}
```

### Documentation du code

```dart
/// Calcule le total des paiements pour une taxe.
/// 
/// [taxId] - L'identifiant unique de la taxe
/// 
/// Retourne la somme de tous les paiements complétés
/// pour la taxe spécifiée.
double calculateTaxTotal(String taxId) {
  // ...
}

/// Catégorie de la taxe
enum TaxCategory {
  commercial,
  residential,
  industrial,
}
```

### Gestion d'erreurs

```dart
// ✓ Bon
try {
  final user = await database.getUser(userId);
  if (user != null) {
    setState(() => _user = user);
  }
} catch (e) {
  print('Erreur lors du chargement: $e');
  _showErrorDialog('Impossible de charger l\'utilisateur');
}

// ✗ Mauvais
try {
  final user = await database.getUser(userId);
  setState(() => _user = user);
} catch (e) {
  // Ignorer l'erreur
}
```

---

## 🌳 Structure des branches

```
main (production)
  ├── feature/authentication      (nouvelle fonctionnalité)
  ├── feature/payment-gateway     (nouvelle fonctionnalité)
  ├── bugfix/login-crash          (correction de bug)
  ├── docs/update-readme          (documentation)
  └── refactor/database-layer     (refactorisation)
```

### Nommage des branches

- `feature/*` - Nouvelles fonctionnalités
- `bugfix/*` - Corrections de bugs
- `hotfix/*` - Corrections urgentes
- `docs/*` - Mises à jour de documentation
- `refactor/*` - Refactorisations

---

## 📤 Pull Requests

### Modèle de PR

```markdown
## Description
Courte description des changements

## Type de changement
- [ ] Nouvelle fonctionnalité
- [ ] Correction de bug
- [ ] Changement majeur
- [ ] Documentation

## Changements
- Ajouter X
- Modifier Y
- Supprimer Z

## Tests réalisés
- [ ] Test 1
- [ ] Test 2
- [ ] Test 3

## Screenshots (si applicable)
[Ajouter des screenshots]

## Issues liées
Ferme #123

## Checklist
- [ ] J'ai lu le CONTRIBUTING.md
- [ ] Mon code suit le style du projet
- [ ] J'ai testé mes changements
- [ ] J'ai mis à jour la documentation
- [ ] Pas de warnings à la compilation
```

### Critères d'acceptation

Avant de merger, la PR doit avoir:

- ✅ Code review approuvé
- ✅ Tests passants
- ✅ Pas de merge conflicts
- ✅ Documentation mise à jour
- ✅ Style de code correct

---

## 🐛 Reporting de bugs

### Template de bug

```markdown
## Description
Qu'est-ce qui ne fonctionne pas?

## À reproduire
Étapes pour reproduire le problème:
1. Aller à...
2. Cliquer sur...
3. Observer...

## Comportement attendu
Qu'est-ce qui devrait se passer?

## Comportement réel
Qu'est-ce qui se passe réellement?

## Logs
```
[Coller les logs d'erreur]
```

## Environnement
- Flutter: X.X.X
- Dart: X.X.X
- OS: Windows/MacOS/Linux
- Navigateur: Chrome/Edge/Firefox

## Urgence
- [ ] Bloquant (application crash)
- [ ] Critique (fonctionnalité ne fonctionne pas)
- [ ] Important (comportement incorrect)
- [ ] Mineur (petits problèmes)
```

---

## 🧪 Tests

### Exécuter les tests

```bash
# Tous les tests
flutter test

# Test spécifique
flutter test test/widgets/tax_card_test.dart

# Avec couverture
flutter test --coverage
```

### Écrire des tests

```dart
void main() {
  group('UserProvider', () {
    test('login with valid phone', () async {
      final provider = UserProvider();
      final user = await provider.login('+225 07 12 34 56');
      
      expect(user, isNotNull);
      expect(user!.phone, '+225 07 12 34 56');
    });

    test('registration creates new user', () async {
      final provider = UserProvider();
      final success = await provider.registerUser(
        'Test User',
        '+225 07 12 34 57',
      );
      
      expect(success, isTrue);
    });
  });
}
```

### Couverture de test

Visez au minimum:

- 70% de couverture pour les services
- 80% de couverture pour les providers
- 60% de couverture pour les widgets

```bash
# Voir la couverture
flutter test --coverage
lcov --list coverage/lcov.info
```

---

## 📚 Documentation

### Mettre à jour la documentation

Quand vous ajoutez une fonctionnalité:

1. **Mettre à jour ARCHITECTURE.md**
   ```markdown
   ### Nouvelle Fonctionnalité
   Description technique
   
   **Fichiers concernés:**
   - lib/services/new_service.dart
   - lib/providers/new_provider.dart
   ```

2. **Mettre à jour README_FR.md**
   ```markdown
   ## Utilisation
   Comment utiliser la nouvelle fonctionnalité
   ```

3. **Ajouter des commentaires au code**
   ```dart
   /// Nouvelle fonction avec documentation
   void newFunction() {
     // Implémentation
   }
   ```

### Exemple complet

```dart
/// Service pour gérer les paiements avec le portail externe.
/// 
/// Exemple:
/// ```dart
/// final service = ExternalPaymentService();
/// final result = await service.initiatePayment(
///   amount: 50000,
///   paymentMethod: 'mobile_money',
/// );
/// ```
class ExternalPaymentService {
  /// Initie un paiement via le portail externe.
  /// 
  /// [amount] - Montant en devise locale
  /// [paymentMethod] - Méthode de paiement (mobile_money, carte, etc)
  /// 
  /// Retourne un [PaymentResult] contenant l'ID de transaction
  /// ou lève une [PaymentException] en cas d'erreur.
  Future<PaymentResult> initiatePayment({
    required double amount,
    required String paymentMethod,
  }) async {
    // ...
  }
}
```

---

## ⚙️ Commandes utiles

```bash
# Analyser le code
flutter analyze

# Formater le code
flutter format .

# Nettoyer et reconstruire
flutter clean
flutter pub get

# Régénérer les modèles
flutter pub run build_runner build --delete-conflicting-outputs

# Exécuter les tests
flutter test

# Vérifier les dépendances
flutter pub outdated

# Voir les upgrades disponibles
flutter pub upgrade
```

---

## 📋 Checklist avant de soumettre

- [ ] Code écrit et testé
- [ ] `flutter analyze` passe sans erreurs
- [ ] `flutter format` appliqué
- [ ] Tests écrits et passants
- [ ] Documentation mise à jour
- [ ] Commit messages clairs
- [ ] Branche à jour avec main
- [ ] Pas de fichiers de debug
- [ ] Pas de secrets (tokens, clés) commités

---

## 🚀 Workflow complet

```bash
# 1. Fork et clone
git clone <votre-fork>
cd applicationweb

# 2. Créer une branche
git checkout -b feature/awesome-feature

# 3. Développer
# ... ajouter du code ...
flutter format .
flutter analyze

# 4. Tester
flutter test
flutter run

# 5. Commit
git add .
git commit -m "feat: ajouter la fonctionnalité awesome"

# 6. Push
git push origin feature/awesome-feature

# 7. Créer une Pull Request
# ... sur GitHub ...

# 8. Attendre la révision
# ... faire les modifications si demandées ...

# 9. Merge! 🎉
```

---

## 📞 FAQ

**Q: Je dois ajouter une dépendance, comment je fais?**
```bash
flutter pub add nom_du_package
# Puis créer une issue pour discuter
```

**Q: Mon code ne formate pas correctement.**
```bash
# Utiliser le formateur automatique
flutter format lib/
```

**Q: Mes tests échouent, comment déboguer?**
```bash
flutter test -v  # Mode verbose
flutter test --pause-on-start  # Debugger
```

**Q: Comment squash mes commits?**
```bash
git rebase -i HEAD~3  # Pour les 3 derniers commits
# Puis faire les changements et push -f
```

**Q: Je me suis trompé de branche, comment fixer?**
```bash
git reset --hard HEAD~1  # Revenir au dernier commit
# Ou créer une nouvelle branche
```

**Q: Comment récupérer les mises à jour du repo principal?**
```bash
git fetch upstream
git rebase upstream/main
git push origin feature/ma-branche -f
```

---

## 🎓 Ressources

### Flutter et Dart
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)
- [Provider Documentation](https://pub.dev/packages/provider)

### Git et GitHub
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Guides](https://guides.github.com)
- [Conventional Commits](https://www.conventionalcommits.org)

### Testing
- [Flutter Testing](https://flutter.dev/docs/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)

---

## 🙏 Merci de contribuer!

Vos contributions font de MuniciPay un meilleur projet!

**Questions?** → Ouvrir une issue ou contacter les mainteneurs

---

**Dernière mise à jour:** 2024
**Mainteneurs:** Équipe MuniciPay
