from django.contrib import admin
from .models import Commande, LigneCommande, Colis, Voyage

class LigneCommandeInline(admin.TabularInline):
    model = LigneCommande
    extra = 1

class CommandeAdmin(admin.ModelAdmin):
    """إدارة الطلبات في لوحة المشرف"""
    list_display = ('id_commande', 'display_client', 'display_fournisseur', 'montant_total', 'statut', 'date_commande', 'display_livreur_chauffeur')
    search_fields = ('id_commande', 'client__utilisateur__username', 'fournisseur__nom_commerce')
    list_filter = ('statut', 'date_commande')
    inlines = [LigneCommandeInline]
    
    fieldsets = (
        ('معلومات الطلب', {
            'fields': ('client', 'fournisseur', 'adresse_livraison', 'montant_total', 'frais_livraison', 'instructions_speciales')
        }),
        ('معلومات التوصيل', {
            'fields': ('livreur', 'chauffeur', 'date_livraison_estimee', 'date_livraison_reelle')
        }),
        ('حالة الطلب', {
            'fields': ('statut', 'code_qr', 'qr_image')
        }),
    )
    
    readonly_fields = ('date_commande', 'code_qr', 'qr_image')
    
    def display_client(self, obj):
        return obj.client.utilisateur.username
    display_client.short_description = 'العميل'
    
    def display_fournisseur(self, obj):
        if obj.fournisseur:
            return f"{obj.fournisseur.nom_commerce}"
        return "-"
    display_fournisseur.short_description = 'المزود'
    
    def display_livreur_chauffeur(self, obj):
        if obj.livreur:
            return f"Livreur: {obj.livreur.utilisateur.username}"
        elif obj.chauffeur:
            return f"Chauffeur: {obj.chauffeur.utilisateur.username}"
        return "-"
    display_livreur_chauffeur.short_description = 'السائق'
    
    actions = ['generate_qr_codes', 'mark_as_delivered', 'mark_as_in_delivery']
    
    def generate_qr_codes(self, request, queryset):
        for commande in queryset:
            commande.generate_qr_code()
        self.message_user(request, f"{queryset.count()} تم إنشاء رموز QR للطلبات المحددة")
    generate_qr_codes.short_description = "إنشاء رموز QR للطلبات المحددة"
    
    def mark_as_delivered(self, request, queryset):
        for commande in queryset:
            commande.update_status('Livrée')
        self.message_user(request, f"{queryset.count()} تم تحديث حالة الطلبات إلى 'تم التسليم'")
    mark_as_delivered.short_description = "تحديث الطلبات المحددة إلى 'تم التسليم'"
    
    def mark_as_in_delivery(self, request, queryset):
        for commande in queryset:
            commande.update_status('En livraison')
        self.message_user(request, f"{queryset.count()} تم تحديث حالة الطلبات إلى 'في مرحلة التوصيل'")
    mark_as_in_delivery.short_description = "تحديث الطلبات المحددة إلى 'في مرحلة التوصيل'"


class LigneCommandeAdmin(admin.ModelAdmin):
    """إدارة عناصر الطلبات في لوحة المشرف"""
    list_display = ('id', 'display_commande', 'display_produit', 'quantite', 'prix_unitaire', 'display_sous_total')
    search_fields = ('commande__id_commande', 'produit__nom')
    list_filter = ('commande__statut',)
    
    def display_commande(self, obj):
        return f"#{obj.commande.id_commande}"
    display_commande.short_description = 'الطلب'
    
    def display_produit(self, obj):
        return obj.produit.nom
    display_produit.short_description = 'المنتج'
    
    def display_sous_total(self, obj):
        return f"{obj.sous_total} DZD"
    display_sous_total.short_description = 'المجموع الفرعي'


class ColisAdmin(admin.ModelAdmin):
    """إدارة الطرود في لوحة المشرف"""
    list_display = ('id_colis', 'display_expediteur', 'display_destinataire', 'poids', 'statut', 'montant', 'display_commande')
    search_fields = ('id_colis', 'expediteur__utilisateur__username', 'destinataire__utilisateur__username')
    list_filter = ('statut',)
    
    def display_expediteur(self, obj):
        return obj.expediteur.utilisateur.username
    display_expediteur.short_description = 'المرسل'
    
    def display_destinataire(self, obj):
        return obj.destinataire.utilisateur.username
    display_destinataire.short_description = 'المستلم'
    
    def display_commande(self, obj):
        if obj.commande:
            return f"#{obj.commande.id_commande}"
        return "-"
    display_commande.short_description = 'الطلب المرتبط'


class VoyageAdmin(admin.ModelAdmin):
    """إدارة الرحلات في لوحة المشرف"""
    list_display = ('id_voyage', 'display_voyageur', 'destination', 'date_depart', 'date_arrivee', 'poids_disponible', 'tarif_transport')
    search_fields = ('id_voyage', 'voyageur__utilisateur__username', 'destination')
    list_filter = ('date_depart',)
    
    def display_voyageur(self, obj):
        return obj.voyageur.utilisateur.username
    display_voyageur.short_description = 'المسافر'


# تسجيل النماذج في لوحة الإدارة
admin.site.register(Commande, CommandeAdmin)
admin.site.register(LigneCommande, LigneCommandeAdmin)
admin.site.register(Colis, ColisAdmin)
admin.site.register(Voyage, VoyageAdmin)
