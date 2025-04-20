from django.db import models
from utilisateurs.models import Client, Livreur

class Colis(models.Model):
    STATUT_CHOICES = [
        ('En attente', 'En attente'),
        ('En Transit', 'En Transit'),
        ('Livre', 'Livré'),
    ]
    
    id_colis = models.AutoField(primary_key=True)
    expediteur = models.ForeignKey(Client, related_name='colis_expedies', on_delete=models.CASCADE)
    destinataire = models.ForeignKey(Client, related_name='colis_recus', on_delete=models.CASCADE)
    poids = models.FloatField()
    description = models.TextField(null=True, blank=True)
    dimensions = models.CharField(max_length=100, null=True, blank=True)
    statut = models.CharField(max_length=15, choices=STATUT_CHOICES, default='En attente')
    montant = models.FloatField()
    
    def __str__(self):
        return f"Colis #{self.id_colis} - {self.statut}"

class Voyage(models.Model):
    id_voyage = models.AutoField(primary_key=True)
    voyageur = models.ForeignKey(Client, on_delete=models.CASCADE)
    destination = models.CharField(max_length=255)
    date_depart = models.DateTimeField()
    date_arrivee = models.DateTimeField()
    poids_disponible = models.FloatField()
    tarif_transport = models.FloatField()
    
    def __str__(self):
        return f"Voyage vers {self.destination} le {self.date_depart}"

class Commande(models.Model):
    STATUT_CHOICES = [
        ('En attente', 'En attente'),
        ('Acceptee', 'Acceptée'),
        ('En cours', 'En cours'),
        ('Terminee', 'Terminée'),
        ('Annulee', 'Annulée'),
    ]
    
    METHODE_PAIEMENT_CHOICES = [
        ('Cash', 'Cash'),
        ('App', 'Application'),
    ]
    
    id_commande = models.AutoField(primary_key=True)
    client = models.ForeignKey(Client, on_delete=models.CASCADE)
    livreur = models.ForeignKey(Livreur, on_delete=models.SET_NULL, null=True, blank=True)
    adresse_depart = models.CharField(max_length=255)
    adresse_arrivee = models.CharField(max_length=255)
    methode_paiement = models.CharField(max_length=10, choices=METHODE_PAIEMENT_CHOICES)
    montant = models.FloatField()
    statut = models.CharField(max_length=15, choices=STATUT_CHOICES, default='En attente')
    qr_code = models.TextField(null=True, blank=True)
    recu_transaction = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"Commande #{self.id_commande} - {self.statut}"