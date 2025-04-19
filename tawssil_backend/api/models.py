from django.db import models
from rest_framework import serializers
from django.contrib.auth.hashers import make_password

class Utilisateur(models.Model):
    id_utilisateur = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100, null=True, blank=True)
    prenom = models.CharField(max_length=100, null=True, blank=True)
    email = models.EmailField(max_length=255, unique=True)
    mot_de_passe = models.CharField(max_length=255)
    telephone = models.CharField(max_length=20, null=True, blank=True)
    adresse = models.TextField(null=True, blank=True)
    type_utilisateur = models.CharField(
        max_length=20,
        choices=[
            ('Client', 'Client'),
            ('Chauffeur', 'Chauffeur'),
            ('Livreur', 'Livreur'),
            ('Administrateur', 'Administrateur'),
        ]
    )
    photo_cart = models.TextField(null=True, blank=True)

    class Meta:
        db_table = 'utilisateur'
        managed = False

class Client(models.Model):
    id_client = models.OneToOneField(
        Utilisateur,
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='id_client',
        related_name='client_profile'
    )

    class Meta:
        db_table = 'client'
        managed = False

class Livreur(models.Model):
    id_livreur = models.OneToOneField(
        Utilisateur,
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='id_livreur',
        related_name='livreur_profile'
    )
    type_transport = models.CharField(
        max_length=10,
        choices=[
            ('Moto', 'Moto'),
            ('Camion', 'Camion'),
        ],
        null=True,
        blank=True
    )
    disponibilite = models.BooleanField(null=True, blank=True)
    zone_couverture = models.TextField(null=True, blank=True)

    class Meta:
        db_table = 'livreur'
        managed = False

class Chauffeur(models.Model):
    id_chauffeur = models.OneToOneField(
        Utilisateur,
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='id_chauffeur',
        related_name='chauffeur_profile'
    )
    note_moyenne = models.FloatField(null=True, blank=True)
    disponibilite = models.BooleanField(null=True, blank=True)

    class Meta:
        db_table = 'chauffeur'
        managed = False

class Administrateur(models.Model):
    id_admin = models.OneToOneField(
        Utilisateur,
        on_delete=models.CASCADE,
        primary_key=True,
        db_column='id_admin',
        related_name='admin_profile'
    )

    class Meta:
        db_table = 'administrateur'
        managed = False

class Colis(models.Model):
    id_colis = models.AutoField(primary_key=True)
    expediteur = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        related_name='colis_envoyes',
        db_column='expediteur'
    )
    destinataire = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        related_name='colis_recus',
        db_column='destinataire'
    )
    poids = models.FloatField(null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    dimensions = models.TextField(null=True, blank=True)
    statut = models.CharField(
        max_length=20,
        choices=[
            ('En attente', 'En attente'),
            ('En Transit', 'En Transit'),
            ('Livre', 'Livre'),
        ],
        null=True,
        blank=True
    )
    montant = models.FloatField(null=True, blank=True)

    class Meta:
        db_table = 'colis'
        managed = False

class Voyage(models.Model):
    id_voyage = models.AutoField(primary_key=True)
    voyageur = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        db_column='voyageur',
        related_name='voyages'
    )
    destination = models.TextField(null=True, blank=True)
    date_depart = models.DateTimeField(null=True, blank=True)
    date_arrivee = models.DateTimeField(null=True, blank=True)
    poids_disponible = models.FloatField(null=True, blank=True)
    tarif_transport = models.FloatField(null=True, blank=True)

    class Meta:
        db_table = 'voyage'
        managed = False

class Commande(models.Model):
    id_commande = models.AutoField(primary_key=True)
    client = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        db_column='client',
        related_name='commandes'
    )
    livreur = models.ForeignKey(
        Livreur,
        on_delete=models.CASCADE,
        db_column='livreur',
        related_name='livraisons'
    )
    adresse_depart = models.TextField(null=True, blank=True)
    adresse_arrivee = models.TextField(null=True, blank=True)
    methode_paiement = models.CharField(
        max_length=20,
        choices=[
            ('Cash', 'Cash'),
            ('App', 'App'),
            ('App Bancaire', 'App Bancaire'),
        ],
        null=True,
        blank=True
    )
    montant = models.FloatField(null=True, blank=True)
    statut = models.CharField(
        max_length=20,
        choices=[
            ('En attente', 'En attente'),
            ('Acceptee', 'Acceptee'),
            ('En cours', 'En cours'),
            ('Terminee', 'Terminee'),
            ('Annulee', 'Annulee'),
        ],
        null=True,
        blank=True
    )
    qr_code = models.TextField(null=True, blank=True)
    recu_transaction = models.TextField(null=True, blank=True)

    class Meta:
        db_table = 'commande'
        managed = False

class Paiement(models.Model):
    id_paiement = models.AutoField(primary_key=True)
    commande = models.ForeignKey(
        Commande,
        on_delete=models.CASCADE,
        db_column='commande',
        related_name='paiements'
    )
    methode = models.CharField(
        max_length=20,
        choices=[
            ('Cash', 'Cash'),
            ('App', 'App'),
        ],
        null=True,
        blank=True
    )
    statut = models.CharField(
        max_length=20,
        choices=[
            ('En Attente', 'En Attente'),
            ('Confirme', 'Confirme'),
            ('Echoue', 'Echoue'),
        ],
        null=True,
        blank=True
    )
    recu = models.TextField(null=True, blank=True)

    class Meta:
        db_table = 'paiement'
        managed = False

class Vehicule(models.Model):
    id_vehicule = models.AutoField(primary_key=True)
    chauffeur = models.ForeignKey(
        Chauffeur,
        on_delete=models.CASCADE,
        db_column='chauffeur',
        related_name='vehicules'
    )
    marque = models.CharField(max_length=100, null=True, blank=True)
    matricule = models.CharField(max_length=50, null=True, blank=True)
    type = models.CharField(
        max_length=20,
        choices=[
            ('Moto', 'Moto'),
            ('Taxi', 'Taxi'),
            ('Camion', 'Camion'),
        ],
        null=True,
        blank=True
    )
    disponible = models.BooleanField(null=True, blank=True)

    class Meta:
        db_table = 'vehicule'
        managed = False

class Trajet(models.Model):
    id_trajet = models.AutoField(primary_key=True)
    chauffeur = models.ForeignKey(
        Chauffeur,
        on_delete=models.CASCADE,
        db_column='chauffeur',
        related_name='trajets'
    )
    client = models.ForeignKey(
        Client,
        on_delete=models.CASCADE,
        db_column='client',
        related_name='trajets'
    )
    adresse_depart = models.TextField(null=True, blank=True)
    adresse_arrivee = models.TextField(null=True, blank=True)
    prix = models.FloatField(null=True, blank=True)
    statut = models.CharField(
        max_length=20,
        choices=[
            ('En attente', 'En attente'),
            ('En cours', 'En cours'),
            ('Termine', 'Termine'),
        ],
        null=True,
        blank=True
    )

    class Meta:
        db_table = 'trajet'
        managed = False

class Notification(models.Model):
    id_notification = models.AutoField(primary_key=True)
    utilisateur = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        db_column='utilisateur',
        related_name='notifications'
    )
    message = models.TextField(null=True, blank=True)
    date_envoi = models.DateTimeField(null=True, blank=True)
    statut = models.CharField(
        max_length=10,
        choices=[
            ('Lu', 'Lu'),
            ('Non Lu', 'Non Lu'),
        ],
        null=True,
        blank=True
    )

    class Meta:
        db_table = 'notification'
        managed = False