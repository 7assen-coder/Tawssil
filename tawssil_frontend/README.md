# Application Mobile Tawssil

## Aperçu

L'application mobile Tawssil est développée avec Flutter et permet aux clients de commander des produits auprès de différents fournisseurs et de suivre leurs livraisons en temps réel. Elle offre également une interface dédiée aux livreurs pour gérer leurs livraisons.

## Technologies Utilisées

- Flutter 3.19.0+
- Dart 3.5.4+
- Packages principaux :
  - http: Pour les requêtes API
  - image_picker: Pour la sélection d'images
  - location: Pour la géolocalisation
  - lottie: Pour les animations
  - easy_localization: Pour la gestion des traductions

## Fonctionnalités

### Pour les Clients

- Inscription et authentification
- Vérification par OTP (email/SMS)
- Parcourir les fournisseurs par catégorie
- Commander des produits
- Suivre les livraisons en temps réel
- Payer en ligne ou à la livraison
- Évaluer les livreurs et les produits

### Pour les Livreurs

- Interface dédiée
- Gestion des livraisons
- Navigation GPS
- Mise à jour du statut des commandes
- Historique des livraisons
- Gestion de la disponibilité

## Installation

### Prérequis

- Flutter SDK 3.19.0+
- Dart 3.5.4+
- Android Studio / Xcode pour les émulateurs
- Un éditeur de code (VS Code recommandé)

### Configuration

1. Clonez le dépôt :
```bash
git clone https://github.com/votre-organisation/tawssil.git
cd tawssil/tawssil_frontend
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Configurez les variables d'environnement dans le fichier `lib/config/env.dart`

## Exécution

### Mode Développement

```bash
flutter run
```

### Génération des Fichiers de Production

```bash
# Pour Android
flutter build apk --release

# Pour iOS
flutter build ipa --release
```

## Configuration du Service de Messagerie

L'application utilise EmailJS pour envoyer les codes OTP par email. Suivez ces étapes pour configurer le service :

### Configuration d'EmailJS

1. Créez un compte sur [EmailJS](https://www.emailjs.com)
2. Créez un service d'email et liez-le à votre compte email
3. Créez un modèle d'email avec les variables suivantes :
   - `{{user_name}}` - Nom de l'utilisateur
   - `{{user_email}}` - Email de l'utilisateur
   - `{{otp_code}}` - Code OTP
   - `{{app_name}}` - Nom de l'application
   - `{{user_type}}` - Type d'utilisateur

### Mise à jour des Identifiants EmailJS

Après la configuration, mettez à jour les identifiants dans le fichier `lib/services/auth_service.dart` :

```dart
Future<bool> _sendRealEmailWithOTP({
  required String email,
  required String fullName,
  required String otpCode,
  required String userType,
}) async {
  try {
    final Uri url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    final Map<String, dynamic> data = {
      'service_id': 'VOTRE_SERVICE_ID',
      'template_id': 'VOTRE_TEMPLATE_ID',
      'user_id': 'VOTRE_USER_ID',
      'template_params': {
        'user_email': email,
        'user_name': fullName,
        'otp_code': otpCode,
        'app_name': 'Tawssil',
        'user_type': userType,
      },
    };
    
    // Reste du code...
  }
}
```

## Structure du Projet

```
tawssil_frontend/
├── assets/
│   ├── animations/      # Fichiers d'animation Lottie
│   ├── images/          # Images et icônes
│   └── translations/    # Fichiers de traduction
├── lib/
│   ├── models/          # Modèles de données
│   ├── screens/         # Écrans de l'application
│   ├── services/        # Services (API, auth, etc.)
│   ├── utils/           # Utilitaires et helpers
│   ├── widgets/         # Widgets réutilisables
│   ├── main.dart        # Point d'entrée
│   └── app.dart         # Configuration de l'application
└── test/                # Tests unitaires et d'intégration
```

## Traductions

L'application prend en charge plusieurs langues :
- Français
- Arabe
- Anglais

Les fichiers de traduction se trouvent dans le dossier `assets/translations/`.

## Personnalisation du Thème

Le thème de l'application peut être personnalisé en modifiant le fichier `lib/config/theme.dart`.

## Tests

### Tests Unitaires

```bash
flutter test
```

### Tests d'Intégration

```bash
flutter test integration_test
```

## Déploiement

### Android

1. Configurez votre fichier `android/key.properties` avec vos informations de signature
2. Exécutez `flutter build appbundle --release` pour générer un bundle pour le Play Store
3. Téléchargez le bundle sur la Console Google Play

### iOS

1. Configurez votre compte développeur Apple dans Xcode
2. Exécutez `flutter build ipa --release`
3. Utilisez Application Loader pour télécharger l'IPA sur App Store Connect

## Dépannage

### Problèmes Courants

1. **Erreurs de connexion API** : Vérifiez l'URL de l'API dans les paramètres de configuration
2. **Problèmes de géolocalisation** : Assurez-vous que les permissions sont correctement configurées
3. **Erreurs de construction** : Exécutez `flutter clean` puis `flutter pub get`

## Support

Pour toute question ou assistance, veuillez contacter l'équipe de développement à sidahmedmhd08@gmail.com
