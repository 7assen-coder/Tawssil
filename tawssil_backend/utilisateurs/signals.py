from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Utilisateur, Client, Livreur, Chauffeur, Administrateur

@receiver(post_save, sender=Utilisateur)
def create_user_profile(sender, instance, created, **kwargs):
    """
    إشارة لإنشاء ملف شخصي مناسب بناءً على نوع المستخدم
    """
    if created:  # فقط عند إنشاء مستخدم جديد
        if instance.type_utilisateur == 'Client':
            Client.objects.get_or_create(id_client=instance)
        elif instance.type_utilisateur == 'Livreur':
            Livreur.objects.get_or_create(id_livreur=instance)
        elif instance.type_utilisateur == 'Chauffeur':
            Chauffeur.objects.get_or_create(id_chauffeur=instance)
        elif instance.type_utilisateur == 'Administrateur':
            # إنشاء سجل مسؤول مع تعيين nom_admin من حقل nom للمستخدم
            admin, created = Administrateur.objects.get_or_create(id_admin=instance)
            if created and instance.nom:
                admin.nom_admin = instance.nom
                admin.save()

@receiver(post_save, sender=Utilisateur)
def update_user_profile(sender, instance, created, **kwargs):
    """
    تحديث ملف المستخدم الشخصي عند تغيير النوع أو البيانات
    """
    if not created:  # عند تحديث مستخدم موجود
        # إنشاء أو تحديث الملف الشخصي المناسب
        if instance.type_utilisateur == 'Client':
            Client.objects.get_or_create(id_client=instance)
        elif instance.type_utilisateur == 'Livreur':
            Livreur.objects.get_or_create(id_livreur=instance)
        elif instance.type_utilisateur == 'Chauffeur':
            Chauffeur.objects.get_or_create(id_chauffeur=instance)
        elif instance.type_utilisateur == 'Administrateur':
            # إنشاء أو تحديث سجل مسؤول مع تعيين nom_admin من حقل nom للمستخدم
            admin, created = Administrateur.objects.get_or_create(id_admin=instance)
            if instance.nom:
                admin.nom_admin = instance.nom
                admin.save() 