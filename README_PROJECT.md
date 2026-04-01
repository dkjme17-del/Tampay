# MuniciPay - applicationweb

Ce dépôt contient le client Flutter et des outils pour le prototype MuniciPay
(gestion et paiement des taxes locales). Il inclut :

-- Une application Flutter multiplateforme (mobile, web, desktop) dans `lib/`.
-- Le prototype de backend local a été retiré de cette branche; utilisez Firestore (recommandé) ou déployez un backend sur Cloud Run si vous avez besoin d'opérations côté serveur.
- Scripts d'initialisation de base de données et utilitaires pour tests.

Ce README donne les instructions de mise en route, de test et d'utilisation
des simulateurs de paiement fournis pour le développement.

## Résumé rapide

- Si vous utilisez Firestore, initialisez les données via `tools/seed_firestore.js` (voir `tools/seed_data.json`).
- Lancer l'application Flutter : `flutter run` (ou `flutter run -d windows|chrome`).
- Simulation de paiements CI : numéro requis commençant par `+225` (Côte d'Ivoire).

## Arborescence importante

- `lib/` : code source Flutter (screens, providers, services, models, widgets).
-- `backend/` : (archivé) le dossier backend n'est plus présent ici — migration vers Firestore / Cloud Run disponible.
- `test/` : tests unitaires.

## Prérequis

- Flutter (2.x/3.x/plus récent) installé et configuré.
- Node.js (v16+) pour le backend local.
- Python (optionnel) pour les scripts utilitaires fournis.

## Installation et démarrage (en local)

1. Récupérer les dépendances Flutter :

```bash
flutter pub get
```

2. Installer les dépendances du backend et initialiser la DB :

```bash
cd backend
npm install
# (optionnel) appliquer init.sql vers server.db :
python apply_init_sql.py
# si le serveur est déjà créé, exécuter la migration :
python migrate_db.py
node server.js
```

3. Lancer l'application Flutter :

```bash
flutter run
```

## Endpoints utiles

- `POST /api/auth/register` - body: `{ phone, name, password }`
- `POST /api/auth/login` - body: `{ phone, password }`
- `GET /api/taxes` - lister les taxes
- `POST /api/payments` - créer un paiement (API de dev génère QR/verification)

Voir `BACKEND_ENDPOINTS_SPEC.md` pour la liste complète et les formats.

## Simulateur de paiement

Le projet inclut `lib/services/payment_simulator.dart` pour simuler des
paiements lorsque `PaymentOperatorsManager.simulateCI == true` et que le
numéro commence par `+225`. Le simulateur renvoie `paymentId`, `qrCode` et
`verificationCode` — utilisé par l'application pour afficher un reçu.

Exemple (dans le code) :

```dart
final resp = PaymentSimulator.simulatePayment(
  operator: 'orange_money',
  phoneNumber: '+2250700000000',
  amount: 3000.0,
);
```

Ou déclencher via l'UI : sélectionner `Mobile Money`, entrer un numéro
qui commence par `+225`, puis appuyer sur "Payer".

## Debug & dépannage

- Si le backend indique l'absence d'une colonne, exécuter `python migrate_db.py`.
- Lancer `python list_taxes.py` pour lister les taxes insérées.
- Si l'UI bloque au paiement, vérifiez `lib/providers/payment_provider.dart`
  qui contient un fallback local (timeout 8s) lorsque le backend est lent.

## Tests

Lancer les tests unitaires Flutter :

```bash
flutter test
```

## Contribution

- Fork / branch feature
- Respecter `ANALYSIS_OPTIONS` et `CONTRIBUTING.md`
- Ouvrir une PR claire avec description et tests si possible

## Contacts & mainteneurs

Voir `CONTRIBUTING.md` et `MAINTAINERS` pour les personnes de contact.

---

Si vous voulez que j'ajoute des sections (ex : badges CI, export CSV des taxes,
ou instructions pour build de production), dites-moi lesquelles et je les
ajouterai.
