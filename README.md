# Projet Tawssil - Plateforme de Livraison

## Aperçu du Projet

Tawssil est une plateforme complète de livraison qui connecte les clients, les fournisseurs et les livreurs. Le système comprend trois composants principaux :

1. **Application Mobile Flutter** - Pour les clients et les livreurs
2. **Tableau de Bord d'Administration** - Interface web pour la gestion de la plateforme
3. **Backend Django** - API RESTful pour gérer toutes les opérations

## Architecture du Système

```
Tawssil/
├── tawssil_frontend/   # Application mobile Flutter
├── admin_dashboard/    # Interface d'administration React
├── tawssil_backend/    # API backend Django
├── nginx/              # Configuration du serveur web
└── UIUX/               # Ressources de design
```

## Technologies Utilisées

### Frontend Mobile
- Flutter 3.19.0+
- Dart 3.5.4+
- Packages: http, image_picker, location, lottie, etc.

### Tableau de Bord d'Administration
- React 19.1.0
- Material UI 7.1.0
- Axios pour les requêtes API
- Leaflet pour les cartes interactives

### Backend
- Django 5.2
- Django REST Framework 3.14.0
- PostgreSQL 13+
- JWT pour l'authentification

## Fonctionnalités Principales

### Application Mobile
- Inscription et authentification des utilisateurs
- Vérification par OTP (email/SMS)
- Géolocalisation en temps réel
- Suivi des commandes
- Système de paiement
- Évaluations et commentaires

### Tableau de Bord d'Administration
- Gestion des utilisateurs (clients, livreurs, fournisseurs)
- Suivi des commandes et livraisons
- Rapports et statistiques
- Gestion des produits et catalogues
- Vérification des documents des livreurs

### Backend
- API RESTful sécurisée
- Gestion des utilisateurs et des rôles
- Traitement des commandes
- Système de notification
- Gestion des paiements

## Prérequis

- Docker et Docker Compose
- Python 3.10+
- Node.js 18+
- Flutter SDK 3.19.0+
- PostgreSQL 13+

## Installation et Configuration

### Configuration de l'Environnement

1. Cloner le dépôt :
```bash
git clone https://github.com/votre-organisation/tawssil.git
cd tawssil
```

2. Configurer les variables d'environnement :
```bash
cp env.example .env
# Modifier le fichier .env avec vos paramètres
```

### Lancement avec Docker

```bash
docker-compose up -d
```

Cette commande va :
- Créer et configurer la base de données PostgreSQL
- Démarrer le serveur backend Django
- Configurer le serveur Nginx

### Installation Manuelle

#### Backend
```bash
cd tawssil_backend
python -m venv venv
source venv/bin/activate  # Sur Windows: venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

#### Tableau de Bord d'Administration
```bash
cd admin_dashboard
npm install
npm start
```

#### Application Mobile
```bash
cd tawssil_frontend
flutter pub get
flutter run
```

## Déploiement

### Backend
Le backend peut être déployé sur n'importe quel serveur prenant en charge Docker :
```bash
docker-compose -f docker-compose.prod.yml up -d
```

### Application Mobile
Pour générer les fichiers APK/IPA pour publication :
```bash
cd tawssil_frontend
flutter build apk --release  # Pour Android
flutter build ipa --release  # Pour iOS
```

### Tableau de Bord d'Administration
Pour construire l'application React pour la production :
```bash
cd admin_dashboard
npm run build
```

## Pipeline CI/CD

Le projet utilise GitHub Actions pour l'intégration et le déploiement continus :

- Tests automatisés pour le frontend et le backend
- Construction et déploiement automatiques
- Analyse de sécurité et de performance

Pour plus de détails, consultez le fichier `.github/CI_CD_README.md`.

## Documentation API

L'API REST est documentée avec Swagger UI, accessible à :
```
http://votre-serveur/api/docs/
```

## Sécurité

- Authentification JWT
- Validation des entrées utilisateur
- Protection CSRF
- Chiffrement des données sensibles
- Vérification des permissions basée sur les rôles

## Développement

### Structure du Code Backend

```
tawssil_backend/
├── commandes/       # Gestion des commandes
├── evaluations/     # Système d'évaluation
├── messaging/       # Système de messagerie
├── paiements/       # Traitement des paiements
├── produits/        # Gestion des produits
├── tawssil_backend/ # Configuration principale
├── utilisateurs/    # Gestion des utilisateurs
└── vehicules/       # Informations sur les véhicules
```

### Conventions de Codage

- PEP 8 pour Python
- Dart Analysis pour Flutter
- ESLint pour JavaScript/React

## Licence

Propriétaire - Tous droits réservés

## Contact

Pour toute question ou assistance, veuillez contacter :
- Email : Sidahmedmhd08@gmail.com
- Site Web : www.tawssil.com