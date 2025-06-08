from django.db import models
from django.utils import timezone
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from .manager import UtilisateurManager
import datetime
import uuid
import qrcode
from io import BytesIO
from django.core.files.base import ContentFile
import PIL.Image

class Utilisateur(AbstractBaseUser, PermissionsMixin):
    """نموذج المستخدم الأساسي للنظام"""
    TYPE_UTILISATEUR_CHOICES = [
        ('Client', 'Client'),
        ('Livreur', 'Livreur'),
        ('Chauffeur', 'Chauffeur'),
        ('Administrateur', 'Administrateur'),
        ('Fournisseur', 'Fournisseur'),
    ]
    
    id_utilisateur = models.AutoField(primary_key=True)
    username = models.CharField(max_length=150, unique=True)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=128)
    telephone = models.CharField(max_length=20)
    adresse = models.CharField(max_length=255, blank=True, null=True)
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    date_naissance = models.DateField(null=True, blank=True)
    photo_profile = models.ImageField(upload_to='utilisateurs/photos/profiles', null=True, blank=True)
    type_utilisateur = models.CharField(max_length=20, choices=TYPE_UTILISATEUR_CHOICES)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    last_login = models.DateTimeField(null=True, blank=True)
    last_modified = models.DateTimeField(auto_now=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    
    objects = UtilisateurManager()
    
    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email', 'type_utilisateur']
    
    def __str__(self):
        if self.type_utilisateur == 'Fournisseur' and hasattr(self, 'profil_fournisseur'):
            return f"{self.profil_fournisseur.nom_commerce} ({self.email})"
        return f"{self.username} ({self.email})"
    
    def save(self, *args, **kwargs):
        # إذا كان هذا إنشاء جديد (لا يوجد id_utilisateur)
        is_new = not self.id_utilisateur
        super().save(*args, **kwargs)
        
        # إنشاء ملف تعريف حسب نوع المستخدم - فقط للمستخدمين الجدد
        if is_new:
            if self.type_utilisateur == 'Client' and not hasattr(self, 'profil_client'):
                Client.objects.create(utilisateur=self)
            elif self.type_utilisateur == 'Livreur' and not hasattr(self, 'profil_livreur'):
                Livreur.objects.create(utilisateur=self)
            elif self.type_utilisateur == 'Chauffeur' and not hasattr(self, 'profil_chauffeur'):
                Chauffeur.objects.create(utilisateur=self)
            elif self.type_utilisateur == 'Administrateur' and not hasattr(self, 'profil_admin'):
                Administrateur.objects.create(utilisateur=self)
            elif self.type_utilisateur == 'Fournisseur' and not hasattr(self, 'profil_fournisseur'):
                Fournisseur.objects.create(utilisateur=self)

class Client(models.Model):
    """نموذج العميل المستخدم للتطبيق"""
    utilisateur = models.OneToOneField(
        Utilisateur, 
        on_delete=models.CASCADE, 
        related_name='profil_client',
        null=True,
        blank=True
    )
    
    def __str__(self):
        return f"Client: {self.utilisateur.username if self.utilisateur else 'Unknown'}"

class Conducteur(models.Model):
    """نموذج أساسي مشترك بين السائقين"""
    STATUT_VERIFICATION_CHOICES = [
        ('En attente', 'En attente'),
        ('Approuvé', 'Approuvé'),
        ('Refusé', 'Refusé')
    ]
    
    note_moyenne = models.FloatField(default=0)
    disponibilite = models.BooleanField(default=False)
    matricule_vehicule = models.CharField(max_length=50, null=True, blank=True)
    photo_vehicule = models.ImageField(upload_to='conducteurs/photos/vehicules', null=True, blank=True)
    photo_permis = models.ImageField(upload_to='conducteurs/photos/permis', null=True, blank=True)
    photo_carte_grise = models.ImageField(upload_to='conducteurs/photos/papiers/carte_grise', null=True, blank=True)
    photo_assurance = models.ImageField(upload_to='conducteurs/photos/papiers/assurance', null=True, blank=True)
    photo_vignette = models.ImageField(upload_to='conducteurs/photos/papiers/vignette', null=True, blank=True)
    photo_carte_municipale = models.ImageField(upload_to='conducteurs/photos/papiers/municipale', null=True, blank=True)
    statut_verification = models.CharField(max_length=20, choices=STATUT_VERIFICATION_CHOICES, default='En attente')
    zone_couverture = models.CharField(max_length=255, null=True, blank=True)
    certification_date = models.DateField(null=True, blank=True, help_text="تاريخ التحقق من الوثائق والموافقة")
    raison_refus = models.TextField(null=True, blank=True, help_text="سبب رفض التحقق إذا كان الحساب مرفوضًا")
    
    class Meta:
        abstract = True
    
    def approuver_verification(self):
        """تحديث حالة التحقق إلى 'موافق عليه' وتسجيل تاريخ التحقق"""
        self.statut_verification = 'Approuvé'
        self.certification_date = timezone.now().date()
        self.raison_refus = None
        self.save()
    
    def refuser_verification(self, raison):
        """رفض التحقق مع تقديم سبب"""
        self.statut_verification = 'Refusé'
        self.raison_refus = raison
        self.certification_date = None
        self.save()
    
    def toggle_disponibilite(self):
        """تبديل حالة التوفر"""
        self.disponibilite = not self.disponibilite
        self.save()

class Livreur(Conducteur):
    """نموذج سائق الدراجة النارية أو الشاحنة الصغيرة"""
    TYPE_VEHICULE_CHOICES = [
        ('Moto', 'Moto'),
        ('Camionnette', 'Camionnette')
    ]
    
    utilisateur = models.OneToOneField(
        Utilisateur, 
        on_delete=models.CASCADE, 
        related_name='profil_livreur',
        null=True,
        blank=True
    )
    type_vehicule = models.CharField(max_length=15, choices=TYPE_VEHICULE_CHOICES, default='Moto')
    
    def __str__(self):
        return f"Livreur: {self.utilisateur.username if self.utilisateur else 'Unknown'} ({self.type_vehicule})"

class Chauffeur(Conducteur):
    """نموذج سائق السيارة أو الشاحنة"""
    TYPE_VEHICULE_CHOICES = [
        ('Voiture', 'Voiture'),
        ('Camion', 'Camion'),
    ]
    
    utilisateur = models.OneToOneField(
        Utilisateur, 
        on_delete=models.CASCADE, 
        related_name='profil_chauffeur',
        null=True,
        blank=True
    )
    type_vehicule = models.CharField(max_length=15, choices=TYPE_VEHICULE_CHOICES, default='Voiture')
    
    def __str__(self):
        return f"Chauffeur: {self.utilisateur.username if self.utilisateur else 'Unknown'} ({self.type_vehicule})"

class Administrateur(models.Model):
    """نموذج المسؤول عن النظام"""
    utilisateur = models.OneToOneField(
        Utilisateur, 
        on_delete=models.CASCADE, 
        related_name='profil_admin',
        null=True,  # جعل الحقل قابل للعدم مؤقتًا
        blank=True
    )
    is_staff = models.BooleanField(default=True)
    is_superuser = models.BooleanField(default=True)
    
    def __str__(self):
        return f"Admin: {self.utilisateur.username if self.utilisateur else 'Unknown'}"

class Fournisseur(models.Model):
    """نموذج مزود الخدمة (مطعم، صيدلية، سوبرماركت)"""
    TYPE_FOURNISSEUR_CHOICES = [
        ('Restaurant', 'Restaurant'),
        ('Pharmacie', 'Pharmacie'),
        ('Supermarché', 'Supermarché'),
    ]
    
    utilisateur = models.OneToOneField(
        Utilisateur, 
        on_delete=models.CASCADE, 
        related_name='profil_fournisseur',
        null=True,
        blank=True
    )
    type_fournisseur = models.CharField(max_length=15, choices=TYPE_FOURNISSEUR_CHOICES, default='Restaurant')
    nom_commerce = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    logo = models.ImageField(upload_to='fournisseurs/logos', null=True, blank=True)
    adresse_commerce = models.TextField(null=True, blank=True, default='')
    horaires_ouverture = models.TextField(null=True, blank=True)
    
    def __str__(self):
        return f"{self.type_fournisseur}: {self.nom_commerce} ({self.utilisateur.email if self.utilisateur else 'Unknown'})"

class OTPCode(models.Model):
    """نموذج لتخزين رموز OTP وإدارتها"""
    user = models.ForeignKey(Utilisateur, on_delete=models.CASCADE, related_name='otp_codes', null=True, blank=True)
    code = models.CharField(max_length=4)
    identifier = models.CharField(max_length=255, help_text="البريد الإلكتروني أو رقم الهاتف")
    type = models.CharField(max_length=10, default="EMAIL", help_text="نوع الرمز: EMAIL أو SMS")
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    verification_attempts = models.IntegerField(default=0, help_text="عدد محاولات التحقق")
    last_attempt_time = models.DateTimeField(null=True, blank=True, help_text="وقت آخر محاولة تحقق")
    is_blocked = models.BooleanField(default=False, help_text="ما إذا كان الرمز محظوراً بسبب تجاوز عدد المحاولات")
    registration_data = models.JSONField(null=True, blank=True, help_text="بيانات التسجيل المؤقتة للمستخدم")

    class Meta:
        verbose_name = "Codes OTP"
        verbose_name_plural = "Codes OTP"

    def __str__(self):
        return f"OTP for {self.identifier}"
    
    def save(self, *args, **kwargs):
        # تعيين وقت انتهاء الصلاحية إذا لم يتم تعيينه
        if not self.expires_at:
            self.expires_at = timezone.now() + datetime.timedelta(minutes=3)
        super().save(*args, **kwargs)
    
    @property
    def is_expired(self):
        """التحقق مما إذا كان الرمز قد انتهت صلاحيته"""
        return self.expires_at < timezone.now()
    
    @property
    def time_remaining(self):
        """الوقت المتبقي بالثواني حتى انتهاء صلاحية الرمز"""
        if self.is_expired:
            return 0
        remaining = self.expires_at - timezone.now()
        return max(0, int(remaining.total_seconds()))
        
    @property
    def backoff_time(self):
        """حساب وقت التأخير التدريجي بناءً على عدد المحاولات"""
        if self.verification_attempts <= 1:
            return 0
        
        # زيادة وقت الانتظار بشكل تدريجي: 5، 10، 20، 30 ثانية...
        backoff_seconds = min(5 * (2 ** (self.verification_attempts - 2)), 30)
        
        if not self.last_attempt_time:
            return 0
            
        time_passed = (timezone.now() - self.last_attempt_time).total_seconds()
        time_to_wait = max(0, backoff_seconds - time_passed)
        
        return int(time_to_wait)