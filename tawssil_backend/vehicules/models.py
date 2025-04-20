from django.db import models
from utilisateurs.models import Chauffeur, Client

class Vehicule(models.Model):
    TYPE_CHOICES = [
        ('Moto', 'Moto'),
        ('Taxi', 'Taxi'),
        ('Camion', 'Camion'),
    ]
    
    id_vehicule = models.AutoField(primary_key=True)
    chauffeur = models.ForeignKey(Chauffeur, on_delete=models.CASCADE)
    marque = models.CharField(max_length=100, null=True, blank=True)
    matricule = models.CharField(max_length=50, null=True, blank=True)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES)
    disponible = models.BooleanField(default=True)
    
    def __str__(self):
        return f"{self.type} - {self.matricule}"

class Trajet(models.Model):
    STATUT_CHOICES = [
        ('En attente', 'En attente'),
        ('En Cours', 'En Cours'),
        ('Termine', 'Terminé'),
    ]
    
    id_trajet = models.AutoField(primary_key=True)
    chauffeur = models.ForeignKey(Chauffeur, on_delete=models.CASCADE)
    client = models.ForeignKey(Client, on_delete=models.CASCADE)
    adresse_depart = models.CharField(max_length=255)
    adresse_arrivee = models.CharField(max_length=255)
    prix = models.FloatField()
    statut = models.CharField(max_length=15, choices=STATUT_CHOICES, default='En attente')
    
    def __str__(self):
        return f"Trajet #{self.id_trajet} - {self.statut}"