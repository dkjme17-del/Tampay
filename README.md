# applicationweb

Un projet Flutter multiplateforme (mobile, web, desktop) utilisé comme
client pour un système de gestion documentaire / paiement. Ce dépôt contient
le code Flutter, des scripts d'initialisation de base de données et des
ressources pour construire et tester l'application.

**Status:** code source principal présent dans `lib/`, builds dans `build/`.

**Principaux dossiers**
- `lib/` : code Flutter (UI, providers, services, repositories, widgets).
-- `backend/` : (archive) local Node/SQLite development backend removed from this branch — use Firestore or Cloud Run for server components.
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` : cibles
	plateformes et fichiers de configuration.
- `test/` : tests unitaires et widget tests.

## Contenu important
Script d'initialisation / migration : see `tools/seed_firestore.js` and `tools/seed_data.json` for migrating existing SQLite data (`server.db` / `test_db.sqlite3`) into Firestore.
- Spécifications des endpoints backend : [BACKEND_ENDPOINTS_SPEC.md](BACKEND_ENDPOINTS_SPEC.md)
- Guide d'installation et démarrage : [INSTALLATION.md](INSTALLATION.md)

## Prérequis
- Flutter 3.x+ installé et disponible dans le PATH
- SDK Android / Xcode si vous ciblez mobile
- (Optionnel) Outils pour build desktop/web selon la plateforme

## Installation et exécution
1. Récupérer les dépendances :

```bash
flutter pub get
```

2. (Optionnel) Migrer une base SQLite existante vers Firestore :

```bash
# Placez `server.db` ou `test_db.sqlite3` à la racine du repo,
# puis exécutez le script de migration (nécessite credentials Firebase):
node tools/seed_firestore.js
```

3. Lancer l'application (exemple pour mobile) :

```bash
flutter run
```

Pour web : `flutter run -d chrome`. Pour build de production : `flutter build <platform>`.

## Structure du projet et points d'intérêt
- `lib/main.dart` : point d'entrée.
- `lib/providers/`, `lib/services/`, `lib/repositories/` : logique métier et accès aux données.
- `lib/screens/` : écrans principaux de l'application.
- `lib/widgets/` : composants UI réutilisables.

## Backend / Endpoints
Ce dépôt contient la spécification des endpoints dans
`BACKEND_ENDPOINTS_SPEC.md`. Si vous déployez un backend local ou utilisez
une API distante, vérifiez les variables d'environnement et les fichiers de
configuration correspondants (consultez `MANIFEST.md` et `PAYMENT_SYSTEM_README.md`).

## Tests
Lancer les tests unitaires et widget :

```bash
flutter test
```

## Contribution
- Créez une branche feature/nom-court
- Ouvrez une pull request décrivant le changement
- Respectez les conventions du repo (voir `CONTRIBUTING.md`)

## Debug & Développement
- Logs : utilisez `flutter run -v` pour plus de verbosité
- Hot reload : disponible lors du développement sur un device/emulateur

## CI / Build
Suggestions : configurer une pipeline CI qui exécute `flutter pub get`,
`flutter analyze` et `flutter test`, puis builds pour les plateformes ciblées.

## Licence
Vérifiez la présence d'un fichier `LICENSE` à la racine. Si absent, contacter
les mainteneurs pour préciser la licence.

## Contacts
- Voir `MAINTAINERS` ou la section `CONTRIBUTING.md` pour les personnes de contact.

---

Si vous voulez, je peux :
- adapter ce README pour un usage particulier (ex. mettre l'accent sur la
	configuration backend ou les étapes de build mobile/desktop),
- ajouter des badges (build, coverage),
- ou committer directement la version finale.

