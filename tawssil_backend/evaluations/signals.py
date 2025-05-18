from django.db.models.signals import post_save
from django.dispatch import receiver
from django.db.models import Avg
from .models import Evaluation

@receiver(post_save, sender=Evaluation)
def update_conducteur_rating(sender, instance, **kwargs):
    """
    تحديث متوسط تقييم السائق بعد إضافة تقييم جديد
    """
    if instance.livreur:
        evals = Evaluation.objects.filter(livreur=instance.livreur)
        if evals.exists():
            avg = evals.aggregate(Avg('note'))['note__avg']
            instance.livreur.note_moyenne = round(avg, 1)
            instance.livreur.save(update_fields=['note_moyenne'])
    elif instance.chauffeur:
        evals = Evaluation.objects.filter(chauffeur=instance.chauffeur)
        if evals.exists():
            avg = evals.aggregate(Avg('note'))['note__avg']
            instance.chauffeur.note_moyenne = round(avg, 1)
            instance.chauffeur.save(update_fields=['note_moyenne']) 