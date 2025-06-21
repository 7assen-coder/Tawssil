# Utiliser une image Python officielle comme base avec une version spécifique pour éviter les vulnérabilités
FROM python:3.11-slim-bookworm

# Définir des variables d'environnement pour optimiser Python
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Définir le répertoire de travail dans le conteneur
WORKDIR /app

# Mettre à jour et installer les dépendances système nécessaires
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
        gettext \
        postgresql-client \
        curl \
        netcat-openbsd \
        libgdal-dev \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copier uniquement le fichier requirements.txt d'abord pour profiter du cache Docker
COPY requirements.txt /app/
RUN pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt \
    && pip check

# Copier le reste du projet dans le conteneur
COPY . /app/

# Analyser et corriger les vulnérabilités des dépendances Python
RUN pip install safety \
    && safety check --full-report || true \
    && pip install pip-audit \
    && pip-audit --fix || true \
    && pip uninstall -y safety pip-audit

# Créer un utilisateur non-root pour plus de sécurité
RUN useradd -m appuser --uid 10001
RUN chown -R appuser:appuser /app
USER appuser

# Créer les répertoires nécessaires pour les fichiers statiques et médias
RUN mkdir -p /app/tawssil_backend/static /app/tawssil_backend/media

# Copier et configurer le script d'entrée
COPY --chown=appuser:appuser ./docker-entrypoint.sh /app/
RUN chmod +x /app/docker-entrypoint.sh

# Collecter les fichiers statiques Django
RUN python tawssil_backend/manage.py collectstatic --noinput

# Exposer le port sur lequel l'application s'exécutera
EXPOSE 8000

# Configurer le point d'entrée pour exécuter le script d'initialisation
ENTRYPOINT ["/app/docker-entrypoint.sh"]

# Commande par défaut pour démarrer Gunicorn avec les paramètres optimaux
CMD ["gunicorn", "tawssil_backend.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "4", "--threads", "2", "--timeout", "60"]
