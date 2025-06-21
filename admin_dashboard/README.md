# Tableau de Bord d'Administration Tawssil

## Aperçu

Le tableau de bord d'administration est une interface web développée avec React qui permet aux administrateurs de gérer tous les aspects de la plateforme Tawssil, y compris les utilisateurs, les commandes, les produits et les paiements.

## Technologies Utilisées

- React 19.1.0
- Material UI 7.1.0
- Axios pour les requêtes API
- Chart.js pour les graphiques
- Leaflet pour les cartes interactives

## Fonctionnalités

- **Gestion des Utilisateurs**
  - Clients
  - Livreurs
  - Fournisseurs
  - Administrateurs

- **Gestion des Commandes**
  - Suivi en temps réel
  - Historique des commandes
  - Statistiques de livraison

- **Gestion des Produits**
  - Catalogues des fournisseurs
  - Ajout/modification de produits
  - Gestion des catégories

- **Rapports et Statistiques**
  - Chiffre d'affaires
  - Performances des livreurs
  - Activité des clients

- **Vérification des Documents**
  - Validation des documents des livreurs
  - Vérification des fournisseurs

## Installation

### Prérequis

- Node.js 18+ 
- npm 9+ ou yarn 1.22+

### Installation des Dépendances

```bash
# Avec npm
npm install

# Avec yarn
yarn install
```

### Configuration

Créez un fichier `.env` à la racine du projet avec les variables suivantes :

```
REACT_APP_API_URL=http://localhost:8000/api
REACT_APP_MAPS_API_KEY=votre_clé_api_maps
```

## Utilisation

### Démarrage du Serveur de Développement

```bash
# Avec npm
npm start

# Avec yarn
yarn start
```

L'application sera accessible à l'adresse [http://localhost:3000](http://localhost:3000).

### Construction pour la Production

```bash
# Avec npm
npm run build

# Avec yarn
yarn build
```

Les fichiers de production seront générés dans le dossier `build`.

### Exécution des Tests

```bash
# Avec npm
npm test

# Avec yarn
yarn test
```

## Structure du Projet

```
admin_dashboard/
├── public/                # Fichiers statiques
├── src/
│   ├── components/        # Composants réutilisables
│   │   ├── Header.js
│   │   ├── Sidebar.js
│   │   └── ...
│   ├── context/           # Contextes React
│   ├── pages/             # Pages principales
│   │   ├── Dashboard.js
│   │   ├── DriverManagement.js
│   │   ├── ProviderManagement.js
│   │   └── ...
│   ├── services/          # Services API
│   │   └── api.js
│   ├── styles/            # Fichiers CSS
│   ├── App.js             # Composant principal
│   └── index.js           # Point d'entrée
└── package.json           # Dépendances
```

## Authentification

Le tableau de bord utilise l'authentification JWT. Les administrateurs doivent se connecter avec leurs identifiants pour accéder au système.

## Gestion des Utilisateurs

### Clients

- Affichage des informations des clients
- Historique des commandes
- Gestion des comptes (activation/désactivation)

### Livreurs

- Vérification des documents (permis, assurance, etc.)
- Suivi des performances
- Gestion des disponibilités

### Fournisseurs

- Validation des informations commerciales
- Gestion des catalogues de produits
- Suivi des ventes et commandes

## Personnalisation

### Thème

Le tableau de bord utilise Material UI avec un thème personnalisable. Pour modifier le thème, éditez le fichier `src/theme.js`.

### Langues

L'interface est disponible en français par défaut. Pour ajouter d'autres langues, utilisez le système de traduction intégré.

## Déploiement

### Avec Nginx

1. Construisez l'application pour la production
2. Copiez le contenu du dossier `build` dans le répertoire de votre serveur web
3. Configurez Nginx pour servir l'application et rediriger les requêtes API

Exemple de configuration Nginx :

```nginx
server {
    listen 80;
    server_name admin.tawssil.com;
    
    root /var/www/admin_dashboard/build;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    location /api {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## Support

Pour toute question ou assistance, veuillez contacter l'équipe de développement à sidahmedmhd08@gmail.com
