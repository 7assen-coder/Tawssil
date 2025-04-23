from django.contrib import admin
from .models import Utilisateur, Client, Livreur, Chauffeur, Administrateur

class UtilisateurAdmin(admin.ModelAdmin):
    # الحقول التي تظهر في قائمة المستخدمين
    list_display = ('id_utilisateur', 'email', 'nom', 'prenom', 'type_utilisateur', 'is_active', 'date_joined')
    
    # الحقول التي يمكن البحث عنها
    search_fields = ('email', 'nom', 'prenom')
    
    # الحقول التي يمكن التصفية بها في الجانب
    list_filter = ('type_utilisateur', 'is_active', 'is_staff', 'is_superuser')
    
    # تجميع الحقول في أقسام عند العرض/التعديل
    fieldsets = (
        ('معلومات المستخدم', {
            'fields': ('nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 'adresse', 'photo_cart')
        }),
        ('النوع', {
            'fields': ('type_utilisateur',)
        }),
        ('الحالة والصلاحيات', {
            'description': 'is_staff للوصول للوحة الإدارة، is_superuser لجميع الصلاحيات',
            'fields': ('is_active', 'is_staff', 'is_superuser'),
        }),
    )
    
    # يتم ملء حقول date_joined و last_login تلقائيًا ولا تظهر في النموذج

class ClientAdmin(admin.ModelAdmin):
    list_display = ('display_id_client',)
    search_fields = ('id_client__email', 'id_client__nom', 'id_client__prenom')
    
    def display_id_client(self, obj):
        """عرض معرف العميل فقط كرقم"""
        return obj.id_client.id_utilisateur
    display_id_client.short_description = 'ID'

class LivreurAdmin(admin.ModelAdmin):
    list_display = ('display_id_livreur', 'type_transport', 'disponibilite')
    list_filter = ('disponibilite', 'type_transport')
    search_fields = ('id_livreur__email', 'id_livreur__nom', 'id_livreur__prenom')
    
    def display_id_livreur(self, obj):
        """عرض معرف الموصل فقط كرقم"""
        return obj.id_livreur.id_utilisateur
    display_id_livreur.short_description = 'ID'

class ChauffeurAdmin(admin.ModelAdmin):
    list_display = ('display_id_chauffeur', 'disponibilite', 'note_moyenne', 'type_voiture')
    list_filter = ('disponibilite',)
    search_fields = ('id_chauffeur__email', 'id_chauffeur__nom', 'id_chauffeur__prenom', 'matricule_voiture')
    
    def display_id_chauffeur(self, obj):
        """عرض معرف السائق فقط كرقم"""
        return obj.id_chauffeur.id_utilisateur
    display_id_chauffeur.short_description = 'ID'

class AdministrateurAdmin(admin.ModelAdmin):
    list_display = ('display_id_admin', 'nom_admin')
    search_fields = ('id_admin__email', 'id_admin__nom', 'id_admin__prenom', 'nom_admin')
    
    def display_id_admin(self, obj):
        """عرض معرف المسؤول فقط كرقم بدلاً من الاسم الكامل والبريد الإلكتروني"""
        return obj.id_admin.id_utilisateur
    display_id_admin.short_description = 'ID'

# تسجيل النماذج مع فئات الإدارة المخصصة
admin.site.register(Utilisateur, UtilisateurAdmin)
admin.site.register(Client, ClientAdmin)
admin.site.register(Livreur, LivreurAdmin)
admin.site.register(Chauffeur, ChauffeurAdmin)
admin.site.register(Administrateur, AdministrateurAdmin)