from django.db import models
from django.db.models import Avg
from utilisateurs.models import Client, Livreur, Chauffeur
from commandes.models import Commande

class Evaluation(models.Model):
    """نموذج تقييم السائق من قبل العميل"""
    client = models.ForeignKey(Client, on_delete=models.CASCADE, related_name='evaluations')
    commande = models.ForeignKey(Commande, on_delete=models.CASCADE, related_name='evaluations')
    # نوع المقيم: إما ليفرور أو شوفور
    livreur = models.ForeignKey(Livreur, on_delete=models.CASCADE, related_name='evaluations', null=True, blank=True)
    chauffeur = models.ForeignKey(Chauffeur, on_delete=models.CASCADE, related_name='evaluations', null=True, blank=True)
    note = models.PositiveSmallIntegerField(choices=[(i, i) for i in range(1, 6)])  # تقييم من 1 إلى 5
    commentaire = models.TextField(null=True, blank=True)
    date_evaluation = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Évaluation {self.note}/5 - Commande #{self.commande.id_commande}"
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # تحديث متوسط ​​التقييم للسائق
        if self.livreur:
            evals = Evaluation.objects.filter(livreur=self.livreur)
            if evals.exists():
                avg = evals.aggregate(Avg('note'))['note__avg']
                self.livreur.note_moyenne = round(avg, 1)
                self.livreur.save(update_fields=['note_moyenne'])
        elif self.chauffeur:
            evals = Evaluation.objects.filter(chauffeur=self.chauffeur)
            if evals.exists():
                avg = evals.aggregate(Avg('note'))['note__avg']
                self.chauffeur.note_moyenne = round(avg, 1)
                self.chauffeur.save(update_fields=['note_moyenne'])
