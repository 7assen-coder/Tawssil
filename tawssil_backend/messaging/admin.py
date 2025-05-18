from django.contrib import admin
from .models import Message

class MessageAdmin(admin.ModelAdmin):
    """إدارة الرسائل في لوحة المشرف"""
    list_display = ('id', 'display_expediteur', 'display_destinataire', 'contenu_court', 'date_envoi', 'lu')
    search_fields = ('expediteur__username', 'destinataire__username', 'contenu')
    list_filter = ('lu', 'date_envoi')
    
    def display_expediteur(self, obj):
        return obj.expediteur.username
    display_expediteur.short_description = 'المرسل'
    
    def display_destinataire(self, obj):
        return obj.destinataire.username
    display_destinataire.short_description = 'المستلم'
    
    def contenu_court(self, obj):
        return obj.contenu[:50] + '...' if len(obj.contenu) > 50 else obj.contenu
    contenu_court.short_description = 'محتوى الرسالة'

# تسجيل النموذج في لوحة الإدارة
admin.site.register(Message, MessageAdmin)
