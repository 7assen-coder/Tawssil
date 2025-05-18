from django.db import models
from utilisateurs.models import Utilisateur

class Message(models.Model):
    """نموذج الرسائل بين المستخدمين"""
    expediteur = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='messages_envoyes')
    destinataire = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='messages_recus')
    contenu = models.TextField()
    date_envoi = models.DateTimeField(auto_now_add=True)
    lu = models.BooleanField(default=False)
    
    def __str__(self):
        return f"Message de {self.expediteur.username} à {self.destinataire.username} le {self.date_envoi}"
