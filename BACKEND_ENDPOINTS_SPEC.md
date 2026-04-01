# Configuration Backend - Endpoints de Paiement Multicanal

Cet fichier documente les endpoints backend nécessaires pour supporter le système de paiement multicanal.

## 📋 Endpoints à créer

### 1. POST `/api/payments/`
**Créer un paiement**

```bash
POST /api/payments/
Authorization: Bearer <token>
Content-Type: application/json

{
  "taxId": "TAX_WATER_001",
  "amount": 5000,
  "paymentMethod": "orange_money",
  "paymentGateway": "orange_money"
}
```

**Réponse (201 Created):**
```json
{
  "paymentId": "PAY123456",
  "taxId": "TAX_WATER_001",
  "userId": "USR789",
  "amount": 5000,
  "status": "pending",
  "paymentMethod": "orange_money",
  "paymentGateway": "orange_money",
  "verificationCode": "ABC123",
  "createdAt": "2025-12-10T14:30:00Z",
  "message": "Paiement 5000 XOF via orange_money en attente"
}
```

---

### 2. POST `/api/payments/orange-money/initiate`
**Initier un paiement Orange Money**

```bash
POST /api/payments/orange-money/initiate
Authorization: Bearer <token>
Content-Type: application/json

{
  "paymentId": "PAY123456",
  "phoneNumber": "+221701234567",
  "amount": 5000
}
```

**Réponse (200 OK):**
```json
{
  "status": "initiated",
  "provider": "orange_money",
  "phoneNumber": "+221701234567",
  "amount": 5000,
  "reference": "OM-1702233000123",
  "message": "Entrez le code USSD #150# sur votre téléphone",
  "ussdCode": "#150#"
}
```

---

### 3. POST `/api/payments/wave/initiate`
**Initier un paiement Wave**

```bash
POST /api/payments/wave/initiate
Authorization: Bearer <token>
Content-Type: application/json

{
  "paymentId": "PAY123456",
  "phoneNumber": "+221701234567",
  "amount": 5000
}
```

**Réponse (200 OK):**
```json
{
  "status": "initiated",
  "provider": "wave",
  "phoneNumber": "+221701234567",
  "amount": 5000,
  "reference": "WAVE-1702233000456",
  "message": "Confirmez le paiement Wave sur votre téléphone",
  "deepLink": "wave://pay?ref=WAVE-1702233000456"
}
```

---

### 4. POST `/api/payments/moov-money/initiate`
**Initier un paiement Moov Money**

```bash
POST /api/payments/moov-money/initiate
Authorization: Bearer <token>
Content-Type: application/json

{
  "paymentId": "PAY123456",
  "phoneNumber": "+228XX123456",
  "amount": 5000
}
```

**Réponse (200 OK):**
```json
{
  "status": "initiated",
  "provider": "moov_money",
  "phoneNumber": "+228XX123456",
  "amount": 5000,
  "reference": "MM-1702233000789",
  "message": "Confirmez le paiement Moov Money",
  "ussdCode": "*556#"
}
```

---

### 5. POST `/api/payments/mtn-money/initiate`
**Initier un paiement MTN Money**

```bash
POST /api/payments/mtn-money/initiate
Authorization: Bearer <token>
Content-Type: application/json

{
  "paymentId": "PAY123456",
  "phoneNumber": "+237XX123456",
  "amount": 5000
}
```

**Réponse (200 OK):**
```json
{
  "status": "initiated",
  "provider": "mtn_money",
  "phoneNumber": "+237XX123456",
  "amount": 5000,
  "reference": "MTN-1702233001012",
  "message": "Confirmez le paiement MTN Money",
  "ussdCode": "*156#"
}
```

---

### 6. POST `/api/payments/card/initiate`
**Initier un paiement par Carte Bancaire**

```bash
POST /api/payments/card/initiate
Authorization: Bearer <token>
Content-Type: application/json

{
  "paymentId": "PAY123456",
  "cardNumber": "4242424242424242",
  "cardHolder": "Jean Dupont",
  "expiryDate": "12/25",
  "cvv": "123",
  "amount": 5000
}
```

**Réponse (200 OK):**
```json
{
  "status": "initiated",
  "provider": "card",
  "cardLast4": "4242",
  "cardHolder": "Jean Dupont",
  "amount": 5000,
  "reference": "CARD-1702233001345",
  "message": "3D Secure: Confirmez sur votre banque",
  "authURL": "https://3dsecure.example.com/auth/CARD-1702233001345"
}
```

⚠️ **IMPORTANT:** 
- NE JAMAIS stocker `cardNumber`, `cvv` en base de données
- Utiliser Stripe/Flutterwave pour tokenization
- Utiliser HTTPS seulement

---

### 7. GET `/api/payments/:id/status`
**Vérifier le statut d'un paiement**

```bash
GET /api/payments/PAY123456/status
Authorization: Bearer <token>
```

**Réponse (200 OK):**
```json
{
  "paymentId": "PAY123456",
  "status": "pending",
  "reference": "OM-1702233000123",
  "paymentMethod": "orange_money"
}
```

---

### 8. POST `/api/payments/:id/confirm`
**Confirmer un paiement avec le code de vérification**

```bash
POST /api/payments/PAY123456/confirm
Authorization: Bearer <token>
Content-Type: application/json

{
  "verificationCode": "ABC123"
}
```

**Réponse (200 OK):**
```json
{
  "message": "Paiement confirmé avec succès",
  "paymentId": "PAY123456",
  "status": "verified",
  "amount": 5000
}
```

**Réponse d'erreur (400 Bad Request):**
```json
{
  "error": "Code incorrect"
}
```

---

### 9. GET `/api/payments/user/:userId`
**Obtenir les paiements d'un utilisateur**

```bash
GET /api/payments/user/USR789
Authorization: Bearer <token>
```

**Réponse (200 OK):**
```json
[
  {
    "id": "PAY123456",
    "taxId": "TAX_WATER_001",
    "userId": "USR789",
    "amount": 5000,
    "status": "verified",
    "paymentMethod": "orange_money",
    "verificationCode": "ABC123",
    "verifiedAt": "2025-12-10T14:35:00Z",
    "createdAt": "2025-12-10T14:30:00Z",
    "taxName": "Taxe d'Eau"
  },
  {
    "id": "PAY123457",
    "taxId": "TAX_ELEC_001",
    "userId": "USR789",
    "amount": 10000,
    "status": "pending",
    "paymentMethod": "wave",
    "verificationCode": null,
    "verifiedAt": null,
    "createdAt": "2025-12-10T15:00:00Z",
    "taxName": "Taxe d'Électricité"
  }
]
```

---

### 10. GET `/api/payments/stats/all`
**Obtenir les statistiques globales des paiements (Admin)**

```bash
GET /api/payments/stats/all
Authorization: Bearer <admin_token>
```

**Réponse (200 OK):**
```json
{
  "totalPayments": 150,
  "totalRevenue": 750000.00,
  "completedPayments": 145,
  "verifiedPayments": 145,
  "byProvider": {
    "orangeMoney": 50,
    "wave": 35,
    "moovMoney": 20,
    "mtnMoney": 30,
    "card": 15
  }
}
```

---

## 🗄️ Modifications de Base de Données

### Migration SQL pour ajouter les colonnes

```sql
-- Ajouter les colonnes pour le système multicanal
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_gateway VARCHAR(50);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_reference VARCHAR(100);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS gateway_response JSONB;

-- Index pour les performances
CREATE INDEX idx_payments_gateway_ref ON payments(gateway_reference);
CREATE INDEX idx_payments_gateway ON payments(payment_gateway);
CREATE INDEX idx_payments_status ON payments(status);
```

---

## 🔐 Sécurité - Checklist

- [x] Vérifier JWT token sur tous les endpoints
- [x] Vérifier authorization (admin pour stats)
- [x] NE JAMAIS retourner les cartes complètes
- [x] NE JAMAIS stocker CVV/données sensibles
- [x] HTTPS seulement en production
- [x] Rate limiting sur les endpoints
- [x] Valider tous les montants côté serveur
- [x] Logger tous les paiements
- [x] Audit trail complet

---

## 📊 Exemple de Flux Complet

### Scenario: Paiement par Orange Money

```
1. Frontend: POST /api/payments/
   ↓
   Backend crée le paiement (status='pending')
   ↓ Retourne paymentId + verificationCode

2. Frontend: POST /api/payments/orange-money/initiate
   ↓
   Backend appelle PaymentProcessor.processOrangeMoney()
   ↓ Retourne reference OTPoronge

3. Frontend: Afficher instruction USSD #150#

4. Utilisateur: Compose #150# sur son téléphone
   ↓
   Orange Money envoie OTP à l'utilisateur

5. Frontend: Polling GET /api/payments/:id/status
   ↓
   Vérifier si le statut est passé à 'verified'

6. Frontend: POST /api/payments/:id/confirm
   ↓
   Utilisateur entre le code OTP
   ↓
   Backend valide et met à jour le statut

7. Backend: POST vers Orange Money API
   ↓ Confirmer la transaction
   ↓ Mettre à jour la base de données

8. Frontend: Afficher ✅ Paiement réussi
```

---

## 🧪 Tests d'Intégration

### Avec Postman

```bash
# 1. Login
POST http://localhost:3000/api/auth/login
{
  "phone": "27712345678",
  "password": "password123"
}
→ Copier le token

# 2. Créer un paiement
POST http://localhost:3000/api/payments/
Authorization: Bearer <token>
{
  "taxId": "1",
  "amount": 5000,
  "paymentMethod": "orange_money",
  "paymentGateway": "orange_money"
}

# 3. Initier le paiement
POST http://localhost:3000/api/payments/orange-money/initiate
Authorization: Bearer <token>
{
  "paymentId": "PAY123456",
  "phoneNumber": "+221701234567",
  "amount": 5000
}

# 4. Vérifier le statut
GET http://localhost:3000/api/payments/PAY123456/status
Authorization: Bearer <token>

# 5. Confirmer
POST http://localhost:3000/api/payments/PAY123456/confirm
Authorization: Bearer <token>
{
  "verificationCode": "ABC123"
}
```

---

## 📈 Métriques à Suivre

```sql
-- Revenue par opérateur
SELECT payment_method, COUNT(*) as count, SUM(amount) as total
FROM payments
WHERE status = 'verified'
GROUP BY payment_method;

-- Taux de succès
SELECT 
  COUNT(CASE WHEN status='verified' THEN 1 END)::float / 
  COUNT(*)::float as success_rate
FROM payments;

-- Transactions en attente
SELECT COUNT(*) FROM payments WHERE status='pending' AND created_at < NOW() - INTERVAL '1 hour';
```

---

## 🚀 Déploiement

1. Créer les endpoints Node.js selon la spécification ci-dessus
2. Tester avec Postman
3. Déployer sur le serveur backend
4. Vérifier les logs
5. Activer dans l'app Flutter
6. Tester end-to-end

---

**Date:** 2025-12-10  
**Créé par:** GitHub Copilot  
**Version:** 1.0.0
