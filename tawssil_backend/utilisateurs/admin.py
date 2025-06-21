from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django.utils.html import format_html
from .models import Utilisateur, Client, Livreur, Chauffeur, Administrateur, Fournisseur, OTPCode

class UtilisateurCreationForm(UserCreationForm):
    """
    نموذج لإنشاء مستخدم جديد في لوحة الإدارة مع تشفير كلمة المرور
    """
    class Meta:
        model = Utilisateur
        fields = ('username', 'email', 'type_utilisateur')

class UtilisateurChangeForm(UserChangeForm):
    """
    نموذج لتعديل المستخدمين في لوحة الإدارة مع الحفاظ على تشفير كلمة المرور
    """
    class Meta:
        model = Utilisateur
        fields = ('username', 'email', 'password', 'type_utilisateur', 'is_active')

class UtilisateurAdmin(admin.ModelAdmin):
    # استخدام نماذج الإدارة المخصصة
    form = UtilisateurChangeForm
    add_form = UtilisateurCreationForm
    
    # الحقول التي تظهر في قائمة المستخدمين
    list_display = ('username', 'email', 'type_utilisateur', 'is_active', 'date_joined', 'display_location')
    
    # الحقول التي يمكن البحث عنها
    search_fields = ('username', 'email', 'telephone')
    
    # الحقول التي يمكن التصفية بها في الجانب
    list_filter = ('type_utilisateur', 'is_active')
    
    # تجميع الحقول في أقسام عند العرض/التعديل
    fieldsets = (
        ('معلومات المستخدم الأساسية', {
            'fields': ('username', 'email', 'password', 'telephone', 'adresse', 'date_naissance', 'photo_profile')
        }),
        ('نوع المستخدم', {
            'fields': ('type_utilisateur',)
        }),
        ('الموقع الجغرافي', {
            'fields': ('latitude', 'longitude',)
        }),
        ('حالة الحساب', {
            'fields': ('is_active',)
        }),
        ('معلومات النظام', {
            'fields': ('date_joined', 'last_login', 'last_modified'),
            'classes': ('collapse',)
        }),
    )

    # الحقول المستخدمة عند إنشاء مستخدم جديد
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'password1', 'password2', 'type_utilisateur', 'is_active'),
        }),
    )
    
    ordering = ('-date_joined',)
    filter_horizontal = ()
    readonly_fields = ('date_joined', 'last_login', 'last_modified')

    def display_location(self, obj):
        if obj.latitude and obj.longitude:
            return f"{obj.latitude:.6f}, {obj.longitude:.6f}"
        return "غير محدد"
    display_location.short_description = 'الموقع الجغرافي'

class ClientAdmin(admin.ModelAdmin):
    list_display = ('id', 'display_username', 'display_email')
    search_fields = ('utilisateur__username', 'utilisateur__email')
    
    def display_username(self, obj):
        return obj.utilisateur.username if obj.utilisateur else 'Unknown'
    display_username.short_description = 'Username'
    
    def display_email(self, obj):
        return obj.utilisateur.email if obj.utilisateur else 'Unknown'
    display_email.short_description = 'Email'

class LivreurAdmin(admin.ModelAdmin):
    list_display = ('id', 'display_username', 'display_email', 'disponibilite', 'note_moyenne', 'statut_verification', 'certification_date')
    search_fields = ('utilisateur__username', 'utilisateur__email')
    list_filter = ('disponibilite', 'statut_verification', 'certification_date')
    
    fieldsets = (
        ('معلومات الحساب', {
            'fields': ('utilisateur', 'type_vehicule', 'note_moyenne', 'disponibilite')
        }),
        ('معلومات التحقق', {
            'fields': ('statut_verification', 'certification_date', 'raison_refus')
        }),
        ('المعلومات الشخصية', {
            'fields': ('matricule_vehicule', 'zone_couverture')
        }),
        ('صور ووثائق', {
            'fields': ('photo_vehicule', 'photo_permis', 'photo_carte_grise', 'photo_assurance', 'photo_vignette', 'photo_carte_municipale')
        }),
    )
    
    def display_username(self, obj):
        return obj.utilisateur.username if obj.utilisateur else 'Unknown'
    display_username.short_description = 'Username'
    
    def display_email(self, obj):
        return obj.utilisateur.email if obj.utilisateur else 'Unknown'
    display_email.short_description = 'Email'
    
    actions = ['approve_verification', 'reject_verification', 'toggle_availability']
    
    def approve_verification(self, request, queryset):
        for livreur in queryset:
            livreur.approuver_verification()
        self.message_user(request, f"{queryset.count()} تم تحديث حالة السائقين إلى 'موافق عليه'")
    approve_verification.short_description = "الموافقة على السائقين المحددين"
    
    def reject_verification(self, request, queryset):
        # هنا يجب إضافة منطق لجمع سبب الرفض من المسؤول
        for livreur in queryset:
            livreur.refuser_verification("لم يتم تقديم الوثائق المطلوبة بشكل كامل")
        self.message_user(request, f"{queryset.count()} تم تحديث حالة السائقين إلى 'مرفوض'")
    reject_verification.short_description = "رفض السائقين المحددين"
    
    def toggle_availability(self, request, queryset):
        for livreur in queryset:
            livreur.toggle_disponibilite()
        self.message_user(request, f"{queryset.count()} تم تبديل حالة التوفر للسائقين المحددين")
    toggle_availability.short_description = "تبديل حالة التوفر للسائقين المحددين"

class ChauffeurAdmin(admin.ModelAdmin):
    list_display = ('id', 'display_username', 'display_email', 'type_vehicule', 'disponibilite', 'statut_verification', 'certification_date')
    search_fields = ('utilisateur__username', 'utilisateur__email')
    list_filter = ('disponibilite', 'type_vehicule', 'statut_verification', 'certification_date')
    
    fieldsets = (
        ('معلومات الحساب', {
            'fields': ('utilisateur', 'type_vehicule', 'note_moyenne', 'disponibilite')
        }),
        ('معلومات التحقق', {
            'fields': ('statut_verification', 'certification_date', 'raison_refus')
        }),
        ('المعلومات الشخصية', {
            'fields': ('matricule_vehicule', 'zone_couverture')
        }),
        ('صور ووثائق', {
            'fields': ('photo_vehicule', 'photo_permis', 'photo_carte_grise', 'photo_assurance', 'photo_vignette', 'photo_carte_municipale')
        }),
    )
    
    def display_username(self, obj):
        return obj.utilisateur.username if obj.utilisateur else 'Unknown'
    display_username.short_description = 'Username'
    
    def display_email(self, obj):
        return obj.utilisateur.email if obj.utilisateur else 'Unknown'
    display_email.short_description = 'Email'
    
    actions = ['approve_verification', 'reject_verification', 'toggle_availability']
    
    def approve_verification(self, request, queryset):
        for chauffeur in queryset:
            chauffeur.approuver_verification()
        self.message_user(request, f"{queryset.count()} تم تحديث حالة السائقين إلى 'موافق عليه'")
    approve_verification.short_description = "الموافقة على السائقين المحددين"
    
    def reject_verification(self, request, queryset):
        # هنا يجب إضافة منطق لجمع سبب الرفض من المسؤول
        for chauffeur in queryset:
            chauffeur.refuser_verification("لم يتم تقديم الوثائق المطلوبة بشكل كامل")
        self.message_user(request, f"{queryset.count()} تم تحديث حالة السائقين إلى 'مرفوض'")
    reject_verification.short_description = "رفض السائقين المحددين"
    
    def toggle_availability(self, request, queryset):
        for chauffeur in queryset:
            chauffeur.toggle_disponibilite()
        self.message_user(request, f"{queryset.count()} تم تبديل حالة التوفر للسائقين المحددين")
    toggle_availability.short_description = "تبديل حالة التوفر للسائقين المحددين"

class AdministrateurAdmin(admin.ModelAdmin):
    list_display = ('id', 'display_username', 'display_email', 'display_is_staff', 'display_is_superuser')
    search_fields = ('utilisateur__username', 'utilisateur__email')
    
    def display_username(self, obj):
        return obj.utilisateur.username if obj.utilisateur else 'Unknown'
    display_username.short_description = 'Username'
    
    def display_email(self, obj):
        return obj.utilisateur.email if obj.utilisateur else 'Unknown'
    display_email.short_description = 'Email'
    
    def display_is_staff(self, obj):
        return obj.is_staff
    display_is_staff.short_description = 'Is Staff'
    display_is_staff.boolean = True

    def display_is_superuser(self, obj):
        return obj.is_superuser
    display_is_superuser.short_description = 'Is Superuser'
    display_is_superuser.boolean = True

class FournisseurAdmin(admin.ModelAdmin):
    list_display = ('get_id_utilisateur', 'nom_commerce', 'type_fournisseur', 'display_latitude', 'display_longitude')
    search_fields = ('utilisateur__username', 'utilisateur__email', 'nom_commerce', 'utilisateur__latitude', 'utilisateur__longitude')
    list_filter = ('type_fournisseur',)
    
    def get_id_utilisateur(self, obj):
        return obj.utilisateur.id_utilisateur if obj.utilisateur else None
    get_id_utilisateur.short_description = 'ID Utilisateur'

    def display_email(self, obj):
        return obj.utilisateur.email if obj.utilisateur else 'Unknown'
    display_email.short_description = 'Email'
    
    def display_latitude(self, obj):
        return obj.utilisateur.latitude if obj.utilisateur else None
    display_latitude.short_description = 'Latitude'
    
    def display_longitude(self, obj):
        return obj.utilisateur.longitude if obj.utilisateur else None
    display_longitude.short_description = 'Longitude'

class OTPCodeAdmin(admin.ModelAdmin):
    """إدارة رموز OTP في لوحة المشرف"""
    list_display = ('id', 'code', 'identifier', 'type', 'display_user', 'is_used', 'display_expired', 'created_at', 'expires_at')
    list_filter = ('is_used', 'created_at')
    search_fields = ('code', 'identifier', 'user__username', 'user__email')
    readonly_fields = ('created_at', 'expires_at', 'is_expired', 'time_remaining')
    fieldsets = (
        ('معلومات الرمز', {
            'fields': ('user', 'code', 'identifier', 'type', 'is_used', 'is_blocked')
        }),
        ('معلومات الصلاحية', {
            'fields': ('created_at', 'expires_at', 'is_expired', 'time_remaining')
        }),
        ('معلومات التسجيل والتحقق', {
            'fields': ('verification_attempts', 'last_attempt_time', 'registration_data')
        }),
    )
    
    def display_user(self, obj):
        if obj.user:
            return f"{obj.user.username} ({obj.user.email})"
        else:
            return "لا يوجد مستخدم مرتبط"
    display_user.short_description = 'المستخدم'
    
    def display_expired(self, obj):
        return obj.is_expired
    display_expired.short_description = 'منتهي الصلاحية'
    display_expired.boolean = True

# تسجيل النماذج مع فئات الإدارة المخصصة
admin.site.register(Utilisateur, UtilisateurAdmin)
admin.site.register(Client, ClientAdmin)
admin.site.register(Livreur, LivreurAdmin)
admin.site.register(Chauffeur, ChauffeurAdmin)
admin.site.register(Administrateur, AdministrateurAdmin)
admin.site.register(Fournisseur, FournisseurAdmin)
admin.site.register(OTPCode, OTPCodeAdmin)