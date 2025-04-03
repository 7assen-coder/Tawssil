# Utiliser une image de base Python
FROM python:3.10

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Copier tous les fichiers du projet dans le conteneur
COPY . .

# Installer les dépendances
RUN pip install -r requirements.txt

# Exécuter le serveur Django
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
