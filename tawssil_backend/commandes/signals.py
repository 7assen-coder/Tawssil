from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings
from .models import Commande

@receiver(post_save, sender=Commande)
def handle_commande_status_change(sender, instance, created, **kwargs):
    """
    معالجة تغييرات حالة الطلب
    """
    if created:
        # إنشاء رمز QR للطلب الجديد
        instance.generate_qr_code()
        
        # إرسال إشعار إلى العميل
        try:
            send_mail(
                subject=f'Nouvelle commande #{instance.id_commande}',
                message=f'Votre commande #{instance.id_commande} a été créée avec succès.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[instance.client.utilisateur.email],
                fail_silently=True,
            )
        except Exception as e:
            print(f"Error sending email: {e}")
            
        # يمكن إضافة إشعار إلى الفورنيسور أيضًا
        if instance.fournisseur and instance.fournisseur.utilisateur.email:
            try:
                send_mail(
                    subject=f'Nouvelle commande #{instance.id_commande}',
                    message=f'Vous avez reçu une nouvelle commande #{instance.id_commande}.',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[instance.fournisseur.utilisateur.email],
                    fail_silently=True,
                )
            except Exception as e:
                print(f"Error sending email to fournisseur: {e}")
    else:
        # التحقق من تغيير الحالة وإرسال الإشعارات المناسبة
        # هذا الجزء يمكن تحسينه باستخدام dirty fields أو طرق أخرى لتتبع التغييرات
        if instance.statut == 'En livraison':
            # إشعار العميل بأن الطلب قيد التسليم
            try:
                send_mail(
                    subject=f'Commande #{instance.id_commande} en cours de livraison',
                    message=f'Votre commande #{instance.id_commande} est en cours de livraison.',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[instance.client.utilisateur.email],
                    fail_silently=True,
                )
            except Exception as e:
                print(f"Error sending email: {e}")
                
        elif instance.statut == 'Livrée':
            # تحديث تاريخ التسليم
            if not instance.date_livraison_reelle:
                instance.date_livraison_reelle = timezone.now()
                instance.save(update_fields=['date_livraison_reelle'])
            
            # إشعار العميل باكتمال التسليم
            try:
                send_mail(
                    subject=f'Commande #{instance.id_commande} livrée',
                    message=f'Votre commande #{instance.id_commande} a été livrée avec succès.',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[instance.client.utilisateur.email],
                    fail_silently=True,
                )
            except Exception as e:
                print(f"Error sending email: {e}") 