# Processus de paiement — MuniciPay

Ce document décrit le processus de paiement implémenté dans le projet MuniciPay (développement local). Il couvre le flux côté client, les endpoints backend, le simulateur pour la Côte d'Ivoire (CI) et des exemples pour tester manuellement.

**Objectif**
- Décrire comment créer un paiement, récupérer le QR/Code de vérification et vérifier un paiement.
- Expliquer le simulateur CI (utilisé en dev) et comment l'activer/désactiver.

**Prérequis**
- Firestore initialisé dans votre projet Firebase (ou accès à un projet Firebase existant).
- (Optionnel) Si vous migrez des données locales, placez votre fichier SQLite (`server.db` ou `test_db.sqlite3`) à la racine du repo ou utilisez le JSON de seed `tools/seed_data.json`.
- Application Flutter configurée pour utiliser Firebase (voir `lib/firebase_options.dart`) — `Firebase.initializeApp()` est appelé automatiquement lors du démarrage.

**Flux de paiement (haute-niveau)**
- L'utilisateur (connecté) sélectionne une taxe à payer et choisit un opérateur / méthode de paiement.
- L'application crée une requête de paiement vers `/api/payments` avec `{ taxId, amount, paymentMethod, metadata }`.
- Le backend crée une entrée `payments` et retourne `{ paymentId, qrCode, verificationCode }`.
- Le client affiche le QR (ou instructions de paiement) et le code de vérification.
- Une fois le paiement effectué par l'utilisateur (réel ou simulé), l'application appelle `/api/payments/:id/verify` avec `{ verificationCode }` pour marquer la transaction comme `verified`.

**Endpoints importants**
- `POST /api/payments` — Crée un paiement.
  - Corps attendu: `{ taxId, amount, paymentMethod, metadata? }`.
  - Réponse: `{ paymentId, qrCode, verificationCode }`.
- `GET /api/payments/:id` — Récupère l'état du paiement.
- `PUT /api/payments/:id/verify` — Vérifie le paiement à l'aide du `verificationCode`.
- `POST /api/auth/register` — Inscription (maintenant avec `password`).
- `POST /api/auth/login` — Authentification par `phone` + `password`.

Voir également: `tools/seed_data.json` et `tools/seed_firestore.js` pour la migration vers Firestore (si nécessaire).

**Simulation (Côte d'Ivoire)**
- Un simulateur de paiement a été ajouté côté client dans `lib/services/payment_simulator.dart`.
- Comportement: si `PaymentOperatorsManager.simulateCI` est activé ET le numéro de téléphone du payeur correspond à un indicatif CI (`+225`), la création de paiement retournera des données simulées `{ paymentId, qrCode, verificationCode }` sans appeler le backend.
- Utilité: tests locaux, démonstration et développement sans opérateurs réels.
- Activation/désactivation:
  - Par code: modifier le booléen `simulateCI` dans `lib/services/payment_operators/payment_operators_manager.dart`.
  - Pour les tests automatisés, privilégier l'activation explicite dans les fixtures ou mocks.

**Exemples curl**
- Créer un paiement (réel backend):

```bash
curl -X POST http://localhost:3000/api/payments \
  -H "Content-Type: application/json" \
  -d '{"taxId":"tax-001","amount":50000,"paymentMethod":"mobile_money","metadata":{"phone":"+2250700000001"}}'
```

- Vérifier un paiement:

```bash
curl -X PUT http://localhost:3000/api/payments/<paymentId>/verify \
  -H "Content-Type: application/json" \
  -d '{"verificationCode":"123456"}'
```

- Créer un utilisateur test (inscription):

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"+2250700000002","name":"Tester","password":"secret"}'
```

- Se connecter (login):

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+2250700000002","password":"secret"}'
```

**Intégration côté client (résumé)**
- `SyncService.createPayment(...)` doit recevoir l'opérateur/méthode choisie et appeler `ApiService.post('/payments', payload)`.
- Si le simulateur CI retourne une réponse simulée, `SyncService` doit persister localement la transaction (box Hive `payments`) et exposer `paymentId`, `qrCode`, `verificationCode` au `PaymentProvider`.
- `PaymentProvider` affiche ensuite le QR et propose l'action `Vérifier` qui appelle `SyncService.verifyPayment(paymentId, verificationCode)`.

**Étapes de test manuel rapide**
1. (Optionnel) Migrer vos données SQLite vers Firestore:

```bash
node tools/seed_firestore.js
```

2. S'inscrire via l'app ou tester le simulateur CI (numéros `+225`).
3. Créer un paiement (simulé ou via intégration réelle selon configuration).
4. Vérifier le paiement avec le `verificationCode` retourné.
5. Vérifier l'état dans Firestore (collection `payments`).

**Dépannage**
- Si l'endpoint `/api/payments` renvoie une erreur 422: contrôlez le payload envoyé (champs requis: `taxId`, `amount`, `paymentMethod`).
- Si le simulateur ne renvoie pas de simulation: vérifiez que le numéro commence par `+225` et que `simulateCI` est activé.
- Pour les tests unitaires Flutter: préférez mocker `PaymentSimulator` ou injecter `simulateCI = false` pour tester les appels réels au backend.

**Contacts / Prochaine étape**
- Si vous voulez, je peux:
  - Mettre à jour `lib/screens` pour afficher clairement quand la simulation CI est active.
  - Ajouter des scripts de test qui automatisent la création + vérification d'un paiement simulé.

---
Fichier créé: PAYMENT_PROCESS_README.md
