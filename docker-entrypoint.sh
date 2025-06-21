#!/bin/bash

set -e

# Fonction pour attendre que PostgreSQL soit prêt
wait_for_postgres() {
    echo "En attente de la base de données PostgreSQL..."
    
    while ! nc -z db 5432; do
        echo "PostgreSQL n'est pas encore disponible - attente..."
        sleep 2
    done
    
    echo "PostgreSQL est prêt !"
}

# Fonction pour attendre que Redis soit prêt
wait_for_redis() {
    echo "En attente du cache Redis..."
    
    while ! nc -z redis 6379; do
        echo "Redis n'est pas encore disponible - attente..."
        sleep 2
    done
    
    echo "Redis est prêt !"
}

# Attendre que les services soient prêts
wait_for_postgres
wait_for_redis

# Exécuter les migrations Django
echo "Exécution des migrations Django..."
python tawssil_backend/manage.py migrate --noinput

# Créer un superutilisateur si nécessaire
if [ "$DJANGO_SUPERUSER_USERNAME" ] && [ "$DJANGO_SUPERUSER_EMAIL" ] && [ "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "Création du superutilisateur Django..."
    python tawssil_backend/manage.py createsuperuser \
        --noinput \
        --username $DJANGO_SUPERUSER_USERNAME \
        --email $DJANGO_SUPERUSER_EMAIL || echo "Le superutilisateur existe déjà"
fi

# Charger les données initiales si nécessaire
if [ "$LOAD_INITIAL_DATA" = "true" ]; then
    echo "Chargement des données initiales..."
    python tawssil_backend/manage.py loaddata initial_data
fi

# Vérifier l'intégrité de la base de données
echo "Vérification de l'intégrité de la base de données..."
python tawssil_backend/manage.py check --database default

# Exécuter la commande passée en argument
echo "Démarrage de l'application Tawssil..."
exec "$@" 