from django.db import models
from commandes.models import Commande

class Paiement(models.Model):
    STATUT_CHOICES = [
        ('En Attente', 'En Attente'),
        ('Confirme', 'Confirmé'),
        ('Echoue', 'Échoué'),
    ]
    
    METHODE_CHOICES = [
        ('Espum', 'Espèces'),
        ('Cash', 'Cash'),
        ('App', 'Application'),
    ]
    
    id_paiement = models.AutoField(primary_key=True)
    commande = models.OneToOneField(Commande, on_delete=models.CASCADE)
    methode = models.CharField(max_length=10, choices=METHODE_CHOICES)
    statut = models.CharField(max_length=15, choices=STATUT_CHOICES, default='En Attente')
    recu = models.CharField(max_length=255, null=True, blank=True)
    
    def __str__(self):
        return f"Paiement #{self.id_paiement} - {self.statut}"