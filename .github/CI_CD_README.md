# Guide CI/CD pour l'Application Tawssil

Ce fichier explique comment configurer et exécuter les pipelines CI/CD pour l'application Tawssil.

## Structure des Fichiers

Les pipelines CI/CD pour l'application Tawssil sont composés de trois fichiers principaux :

- `flutter_ci.yml` : Pour la construction et les tests de l'interface utilisateur (Flutter)
- `backend_ci.yml` : Pour les tests, la construction et le déploiement du backend (Django)
- `mobile_deployment.yml` : Pour le déploiement de l'application sur les stores (Play Store / App Store)

## Dépendances et Prérequis

### Backend (Django)
Toutes les dépendances sont listées dans le fichier `requirements.txt` à la racine du projet. Les principales dépendances incluent :

- Django 5.2.1
- Django REST Framework 3.15.0
- PostgreSQL (via psycopg2-binary)
- Redis pour la mise en cache
- Outils de géolocalisation (geopy, django-leaflet)
- Services de messagerie (Twilio, SendGrid)

### Frontend (Flutter)
Les dépendances sont gérées via le fichier `pubspec.yaml` dans le dossier `tawssil_frontend`. Les principales dépendances incluent :

- Flutter SDK 3.19.3 ou supérieur
- Dart 3.3.0 ou supérieur
- easy_localization pour l'internationalisation
- http/dio pour les requêtes API
- provider/bloc pour la gestion d'état

### Environnement CI/CD
- GitHub Actions pour l'automatisation
- Docker pour la conteneurisation
- Fastlane pour le déploiement iOS
- Gradle pour le déploiement Android

## Fonctionnalités Améliorées

Notre pipeline CI/CD comprend maintenant :

1. **Analyse de Sécurité**
   - OWASP Dependency-Check pour le frontend
   - Outils Safety, Bandit et Semgrep pour le backend
   - Rapports de vulnérabilités automatisés

2. **Tests de Performance**
   - Tests de performance Locust pour le backend avec scénarios réalistes
   - Tests de charge simulant des utilisateurs authentifiés
   - Rapports automatisés pour révision

3. **Déploiement Progressif**
   - Déploiement contrôlé par pourcentage pour Android
   - Publication progressive pour iOS
   - Déploiement web automatisé

4. **Validation**
   - Validation du format de version
   - Tests automatisés avant déploiement
   - Vérification des migrations Django

5. **Qualité de Code**
   - Analyse statique avec flake8, pylint, black et isort
   - Formatage automatique du code Flutter
   - Vérification de la couverture de code

## Secrets Requis

Les secrets suivants doivent être ajoutés aux Secrets du Dépôt GitHub :

### Pour le Backend :
- `DOCKER_HUB_USERNAME` : Nom d'utilisateur Docker Hub
- `DOCKER_HUB_ACCESS_TOKEN` : Token d'accès Docker Hub
- `SERVER_HOST` : Adresse du serveur pour le déploiement
- `SERVER_USERNAME` : Nom d'utilisateur du serveur
- `SERVER_SSH_KEY` : Clé SSH pour la connexion au serveur
- `SENTRY_DSN` : DSN Sentry pour la surveillance des erreurs
- `DATABASE_URL` : URL de connexion à la base de données de production

### Pour le Déploiement Android :
- `PLAY_STORE_JSON_KEY` : Clé JSON pour le compte Google Play Store
- `KEYSTORE_BASE64` : Keystore Android encodé en base64
- `KEYSTORE_PASSWORD` : Mot de passe du keystore
- `KEY_ALIAS` : Alias de la clé
- `KEY_PASSWORD` : Mot de passe de la clé

### Pour le Déploiement iOS :
- `PROVISIONING_PROFILE` : Profil de provisionnement (encodé en base64)
- `CERTIFICATE_P12` : Certificat de signature (encodé en base64)
- `CERTIFICATE_PASSWORD` : Mot de passe du certificat
- `APPSTORE_API_KEY_JSON` : Clé API pour App Store Connect
- `APPLE_TEAM_ID` : ID de l'équipe Apple Developer

## Comment Utiliser

### Tests et Construction Automatiques

Les pipelines de test et de construction s'exécutent automatiquement lorsque :
- Des modifications sont poussées vers les branches principales (main, master, develop)
- Des pull requests sont créées vers ces branches
- Manuellement via l'option "workflow_dispatch" dans GitHub Actions

### Révision des Rapports de Sécurité

Pour consulter les rapports de sécurité :
1. Allez dans l'onglet "Actions" sur GitHub
2. Sélectionnez l'exécution de workflow la plus récente
3. Téléchargez les artefacts depuis la section "Artifacts"
4. Examinez les rapports HTML pour les problèmes de sécurité
5. Priorisez les vulnérabilités critiques et élevées

### Tests de Performance

Les rapports de performance sont générés automatiquement et téléchargés en tant qu'artefacts. Examinez-les pour :
- Identifier les goulots d'étranglement de l'API
- Surveiller les temps de réponse
- Planifier les optimisations
- Évaluer l'impact des nouvelles fonctionnalités

### Déploiement de l'Application Mobile

Pour déployer l'application sur les stores avec un déploiement progressif :

1. Allez dans l'onglet "Actions" sur GitHub
2. Sélectionnez "Mobile Deployment"
3. Cliquez sur "Run workflow"
4. Entrez :
   - Version de l'application (ex. 1.0.0)
   - Notes de version
   - Pourcentage de déploiement (par défaut 10%)
   - Canaux de déploiement (production, beta, alpha)

## Configuration des Tests d'Intégration

### Pour Flutter :
1. Créez un répertoire `integration_test` dans le projet
2. Ajoutez des fichiers de test d'intégration
3. Les tests s'exécuteront automatiquement avant le déploiement
4. Utilisez les mocks pour simuler les réponses API

### Pour le Backend :
1. Créez des scénarios de test de performance dans `locustfile.py`
2. Ajoutez des points de terminaison de test supplémentaires selon les besoins
3. Utilisez des fixtures pour préparer les données de test
4. Configurez les tests pour utiliser une base de données dédiée

## Conseils et Directives

### Pour les Tests Frontend :
- Définissez les tests dans le dossier `test/` du projet Flutter
- Envisagez d'utiliser le développement piloté par les tests (TDD)
- Pour les tests d'interface utilisateur, utilisez le dossier `integration_test`
- Testez sur différentes tailles d'écran et orientations

### Pour les Tests Backend :
- Définissez les tests dans les fichiers `tests.py` des applications Django
- Utilisez une base de données de test indépendante
- Surveillez les rapports de couverture de code
- Testez les cas limites et les scénarios d'erreur

### Pour le Déploiement :
- Vérifiez toujours les paramètres de déploiement dans `Fastfile` pour Android et iOS
- Testez minutieusement l'application avant le déploiement réel
- Utilisez des déploiements progressifs pour minimiser les risques
- Préparez des scénarios de rollback en cas de problème

## Dépannage

Si le processus CI/CD échoue, vérifiez :
1. Les journaux d'erreurs dans l'onglet Actions
2. La validité des secrets et des clés
3. La configuration des fichiers et des chemins dans les fichiers YAML
4. L'ordre des étapes d'exécution dans les pipelines
5. Téléchargez les artefacts pour des journaux plus détaillés
6. Vérifiez les versions des dépendances dans requirements.txt et pubspec.yaml

## Bonnes Pratiques de Sécurité

1. Ne jamais commit directement des données sensibles dans le dépôt
2. Faire tourner les secrets périodiquement
3. Utiliser des tokens d'accès à portée limitée
4. Examiner les permissions de workflow dans GitHub
5. Examiner régulièrement les rapports d'analyse de sécurité
6. Maintenir les dépendances à jour pour éviter les vulnérabilités connues
7. Utiliser des images Docker officielles et à jour

## Amélioration Continue

Notre pipeline CI/CD comprend :
1. Analyse de sécurité pour les vulnérabilités
2. Tests de performance dans le pipeline
3. Tests automatisés de l'interface utilisateur
4. Déploiement progressif
5. Génération automatique des fichiers de traduction

Améliorations futures à envisager :
1. Intégration de tests A/B
2. Tests automatisés de régression visuelle
3. Couverture étendue des tests d'intégration
4. Analyse de la qualité du code avec SonarQube
5. Déploiement blue/green pour le backend
6. Surveillance automatisée post-déploiement

## Contact et Support

Pour toute question concernant le pipeline CI/CD ou pour signaler des problèmes :
- Email : sidahmedmhd08@gmail.com
- GitHub Issues : Créez une issue avec le tag "CI/CD" 