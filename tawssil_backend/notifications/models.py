from django.db import models
from utilisateurs.models import Utilisateur

class Notification(models.Model):
    STATUT_CHOICES = [
        ('Lu', 'Lu'),
        ('Non Lu', 'Non Lu'),
    ]
    
    id_notification = models.AutoField(primary_key=True)
    utilisateur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE)
    message = models.TextField()
    date_envoi = models.DateTimeField(auto_now_add=True)
    statut = models.CharField(max_length=10, choices=STATUT_CHOICES, default='Non Lu')
    
    def __str__(self):
        return f"Notification pour {self.utilisateur.prenom} {self.utilisateur.nom} - {self.statut}"