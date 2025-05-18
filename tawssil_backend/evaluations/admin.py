from django.contrib import admin
from .models import Evaluation

class EvaluationAdmin(admin.ModelAdmin):
    """إدارة التقييمات في لوحة المشرف"""
    list_display = ('id', 'display_client', 'display_commande', 'note', 'display_conducteur', 'date_evaluation')
    search_fields = ('client__utilisateur__username', 'commande__id_commande')
    list_filter = ('note', 'date_evaluation')
    
    def display_client(self, obj):
        return obj.client.utilisateur.username
    display_client.short_description = 'العميل'
    
    def display_commande(self, obj):
        return f"#{obj.commande.id_commande}"
    display_commande.short_description = 'الطلب'
    
    def display_conducteur(self, obj):
        if obj.livreur:
            return f"Livreur: {obj.livreur.utilisateur.username}"
        elif obj.chauffeur:
            return f"Chauffeur: {obj.chauffeur.utilisateur.username}"
        return "-"
    display_conducteur.short_description = 'السائق'

# تسجيل النموذج في لوحة الإدارة
admin.site.register(Evaluation, EvaluationAdmin)
