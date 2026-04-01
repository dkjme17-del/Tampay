# 🎯 Guide de Développement - MuniciPay

## Étapes pour tester l'application

### 1. **Lancer l'app**
```bash
cd d:\dossierApp\applicationweb
flutter run
```

### 2. **Scénario de test - Citoyen**

**Inscription:**
- Appuyez sur "Pas de compte? S'inscrire"
- Remplissez:
  - Nom: "Jean Dupont"
  - Téléphone: "+225 07 12 34 56 78"
- Appuyez sur "S'inscrire"

**Paiement de taxe:**
1. Vous arrivez sur la page d'accueil
2. Cliquez sur une taxe (ex: "Taxe commerciale - 50,000 CFA")
3. Remplissez:
   - Nom: "Jean Dupont"
   - Téléphone: "+225 07 12 34 56 78"
   - Sélectionnez une méthode (Mobile Money/Carte/Virement)
4. Appuyez sur "Confirmer le paiement"
5. Voir le reçu avec QR code

**Historique:**
- Appuyez sur "Historique" en bas
- Voir tous vos paiements
- Cliquez sur un paiement pour voir les détails

### 3. **Scénario de test - Admin**

**Connexion admin:**
- Sur l'écran de login, entrez:
  - Téléphone: "+2250700000000"
- Appuyez sur "Se connecter"

**Dashboard:**
- Voir les statistiques en temps réel
- Recettes totales
- Nombre de paiements par statut
- Liste des paiements avec filtrage

**Filtrage:**
- Cliquez sur "Tous", "En attente", "Complétés", "Vérifiés"
- Le tableau se met à jour

**Vérifier un paiement:**
1. Cliquez sur un paiement dans la liste
2. Appuyez sur "Vérifier le paiement"
3. Le statut passe à "VERIFIED"

---

## Structure du code

### Modèles (Models)
```dart
// Chaque modèle représente une entité de base de données
Tax      -> Définit une taxe locale
Payment  -> Enregistre une transaction
User     -> Profil utilisateur
```

### Providers (Gestion d'état)
```dart
TaxProvider      -> Gère la liste des taxes
PaymentProvider  -> Gère les paiements et statistiques
UserProvider     -> Gère la connexion/inscription
```

### Écrans (Screens)
```dart
LoginScreen             -> Authentification
HomeScreen             -> Accueil citoyen
PaymentScreen          -> Formulaire de paiement
HistoryScreen          -> Historique des transactions
AdminDashboardScreen   -> Tableau de bord municipal
```

---

## Ajouter une nouvelle fonctionnalité

### Exemple: Ajouter un écran "Paramètres"

**1. Créer le fichier écran**
```bash
touch lib/screens/settings_screen.dart
```

**2. Implémenter l'écran**
```dart
class SettingsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paramètres')),
      body: // ... votre code
    );
  }
}
```

**3. L'ajouter à home_screen.dart**
```dart
// Dans BottomNavigationBar
BottomNavigationBarItem(
  icon: Icon(Icons.settings),
  label: 'Paramètres',
),
```

---

## Génération des fichiers Hive

Si vous modifiez les modèles (`tax.dart`, `payment.dart`, `user.dart`):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Cela génère les fichiers `.g.dart`:
- `tax.g.dart`
- `payment.g.dart`
- `user.g.dart`

---

## Debugging

### Voir les logs
```bash
flutter logs
```

### Hot reload (lors du développement)
```
Appuyez sur 'r' dans le terminal pour recharger
Appuyez sur 'R' pour un redémarrage complet
```

### Inspecteur d'éléments
```bash
flutter run -d chrome --profile
# Puis ouvrez http://localhost:39325
```

---

## Points d'amélioration futurs

### 1. **Backend réel**
```
API REST → PostgreSQL
```

### 2. **Authentification**
- JWT tokens
- Refresh tokens
- Logout sécurisé

### 3. **Paiements réels**
- Intégration Flutterwave
- Mobile Money réel
- Vérification de paiement

### 4. **Vérification QR**
```dart
// Scanner QR code avec caméra
mobile_scanner: ^4.0.1
```

### 5. **Notifications**
```dart
flutter_local_notifications: ^17.1.0
// + Push notifications (Firebase)
```

### 6. **Rapports**
```dart
pdf: ^3.10.0
// Générer PDF des rapports mensuels
```

### 7. **Multi-langue**
```dart
intl: ^0.19.0
// Français, Anglais, autres langues
```

---

## Troubleshooting

### Erreur: "Hive box not found"
→ Assurez-vous que `DatabaseService.initDatabase()` est appelé dans `main()`

### Erreur: "Provider not found"
→ Vérifiez que le `MultiProvider` enveloppe l'app dans `main.dart`

### Erreur: "Import not found"
→ Exécutez `flutter pub get` et relancez

### Erreur de compilation après modification de modèles
→ Exécutez `flutter pub run build_runner build --delete-conflicting-outputs`

---

## Performance

### Optimisations déjà en place
✅ `ListView.builder` pour les listes longues
✅ `NeverScrollableScrollPhysics` pour les listes imbriquées
✅ Caching des données avec Hive
✅ Lazy loading des fournisseurs

### À implémenter
- [ ] Pagination pour les listes
- [ ] Cache API
- [ ] Compression des images
- [ ] Minification du code

---

**Bon codage! 🚀**
