from django.db.models.signals import post_save
from django.dispatch import receiver
from django.core.mail import send_mail
from django.conf import settings
from .models import Message

@receiver(post_save, sender=Message)
def notify_message_recipient(sender, instance, created, **kwargs):
    """
    إشعار المستلم عند استلام رسالة جديدة
    """
    if created and instance.destinataire.email:
        try:
            send_mail(
                subject=f'Nouveau message de {instance.expediteur.username}',
                message=f'Vous avez reçu un nouveau message de {instance.expediteur.username}.\n\nContenu: {instance.contenu[:100]}...',
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[instance.destinataire.email],
                fail_silently=True,
            )
        except Exception as e:
            print(f"Error sending email notification: {e}") 