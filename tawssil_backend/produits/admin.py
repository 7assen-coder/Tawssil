from django.contrib import admin
from .models import Produit

class ProduitAdmin(admin.ModelAdmin):
    """إدارة المنتجات في لوحة المشرف"""
    list_display = ('id', 'nom', 'display_fournisseur', 'prix', 'categorie', 'disponible')
    search_fields = ('nom', 'description', 'fournisseur__nom_commerce')
    list_filter = ('disponible', 'categorie', 'fournisseur__type_fournisseur')
    
    def display_fournisseur(self, obj):
        return obj.fournisseur.nom_commerce
    display_fournisseur.short_description = 'المزود'

# تسجيل النموذج في لوحة الإدارة
admin.site.register(Produit, ProduitAdmin)
