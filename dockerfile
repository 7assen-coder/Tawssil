# Utiliser une image de base Python
FROM python:3.10-slim

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Copier tous les fichiers du projet dans le conteneur
COPY . .

# Installer les dépendances
RUN pip install --no-cache-dir -r requirements.txt

# Exécuter le serveur Django
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "tawssil_backend.wsgi:application"]
