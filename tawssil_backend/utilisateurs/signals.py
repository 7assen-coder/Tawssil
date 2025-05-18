from django.db.models.signals import post_save, post_delete, pre_save
from django.dispatch import receiver
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from django.db import transaction
from .models import Utilisateur, Client, Livreur, Chauffeur, Administrateur, Fournisseur

@receiver(post_save, sender=Utilisateur)
def create_user_profile(sender, instance, created, **kwargs):
    """
    إشارة لإنشاء ملف شخصي مناسب بناءً على نوع المستخدم
    """
    if created:  # فقط عند إنشاء مستخدم جديد
        if instance.type_utilisateur == 'Client' and not hasattr(instance, 'profil_client'):
            Client.objects.create(utilisateur=instance)
        elif instance.type_utilisateur == 'Livreur' and not hasattr(instance, 'profil_livreur'):
            Livreur.objects.create(utilisateur=instance)
        elif instance.type_utilisateur == 'Chauffeur' and not hasattr(instance, 'profil_chauffeur'):
            Chauffeur.objects.create(utilisateur=instance)
        elif instance.type_utilisateur == 'Administrateur' and not hasattr(instance, 'profil_admin'):
            Administrateur.objects.create(utilisateur=instance)
        elif instance.type_utilisateur == 'Fournisseur' and not hasattr(instance, 'profil_fournisseur'):
            Fournisseur.objects.create(utilisateur=instance, 
                                     nom_commerce=f"Commerce de {instance.username}", 
                                     type_fournisseur="Restaurant",
                                     adresse_commerce=instance.adresse or "À spécifier")

@receiver(post_save, sender=Utilisateur)
def update_user_profile(sender, instance, **kwargs):
    """
    التأكد من اتساق نوع المستخدم والملف الشخصي
    """
    try:
        with transaction.atomic():
            # تحقق مما إذا كان نوع المستخدم قد تغير
            if instance.type_utilisateur == 'Client' and not hasattr(instance, 'profil_client'):
                Client.objects.create(utilisateur=instance)
            elif instance.type_utilisateur == 'Livreur' and not hasattr(instance, 'profil_livreur'):
                Livreur.objects.create(utilisateur=instance)
            elif instance.type_utilisateur == 'Chauffeur' and not hasattr(instance, 'profil_chauffeur'):
                Chauffeur.objects.create(utilisateur=instance)
            elif instance.type_utilisateur == 'Administrateur' and not hasattr(instance, 'profil_admin'):
                Administrateur.objects.create(utilisateur=instance)
            elif instance.type_utilisateur == 'Fournisseur' and not hasattr(instance, 'profil_fournisseur'):
                Fournisseur.objects.create(utilisateur=instance, 
                                         nom_commerce=f"Commerce de {instance.username}", 
                                         type_fournisseur="Restaurant",
                                         adresse_commerce=instance.adresse or "À spécifier")
    except Exception as e:
        print(f"Error in update_user_profile signal: {e}") 