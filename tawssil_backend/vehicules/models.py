from django.db import models
from utilisateurs.models import Chauffeur

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