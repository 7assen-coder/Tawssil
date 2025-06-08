from django.db import models
from django.utils import timezone
import uuid
import qrcode
from io import BytesIO
from django.core.files.base import ContentFile
from utilisateurs.models import Client, Livreur, Chauffeur, Fournisseur
from produits.models import Produit

class Commande(models.Model):
    """نموذج الطلب المقدم من العميل"""
    STATUT_CHOICES = [
        ('En attente', 'En attente'),
        ('Acceptée', 'Acceptée'),
        ('En préparation', 'En préparation'),
        ('En livraison', 'En livraison'),
        ('Livrée', 'Livrée'),
        ('Annulée', 'Annulée'),
    ]
    
    id_commande = models.AutoField(primary_key=True)
    client = models.ForeignKey(Client, on_delete=models.CASCADE, related_name='commandes')
    fournisseur = models.ForeignKey(Fournisseur, on_delete=models.CASCADE, related_name='commandes', null=True, blank=True)
    livreur = models.ForeignKey(Livreur, on_delete=models.SET_NULL, related_name='livraisons', null=True, blank=True)
    chauffeur = models.ForeignKey(Chauffeur, on_delete=models.SET_NULL, related_name='courses', null=True, blank=True)
    date_commande = models.DateTimeField(auto_now_add=True)
    adresse_livraison = models.TextField()
    montant_total = models.DecimalField(max_digits=10, decimal_places=2)
    frais_livraison = models.DecimalField(max_digits=6, decimal_places=2)
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='En attente')
    code_qr = models.CharField(max_length=255, null=True, blank=True)  # رمز QR مشفر
    qr_image = models.ImageField(upload_to='commandes/qrcodes', null=True, blank=True)
    instructions_speciales = models.TextField(null=True, blank=True)
    date_livraison_estimee = models.DateTimeField(null=True, blank=True)
    date_livraison_reelle = models.DateTimeField(null=True, blank=True)
    
    def __str__(self):
        return f"Commande #{self.id_commande} - {self.client.utilisateur.username}"
    
    def generate_qr_code(self):
        """إنشاء رمز QR مشفر للطلب"""
        if not self.code_qr:
            # إنشاء رمز فريد مشفر
            self.code_qr = f"TAWSSIL-{uuid.uuid4().hex[:12].upper()}-{self.id_commande}"
            self.save(update_fields=['code_qr'])
            
            # إنشاء رمز QR كصورة
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(self.code_qr)
            qr.make(fit=True)
            
            img = qr.make_image(fill_color="black", back_color="white")
            buffer = BytesIO()
            img.save(buffer, format='PNG')
            
            filename = f'qr-{self.id_commande}.png'
            self.qr_image.save(filename, ContentFile(buffer.getvalue()), save=True)
        
        return self.code_qr
    
    def update_status(self, new_status):
        """تحديث حالة الطلب مع تسجيل التاريخ المناسب"""
        self.statut = new_status
        
        if new_status == 'Livrée':
            self.date_livraison_reelle = timezone.now()
        
        self.save()


class LigneCommande(models.Model):
    """نموذج عناصر الطلب"""
    commande = models.ForeignKey(Commande, on_delete=models.CASCADE, related_name='elements')
    produit = models.ForeignKey(Produit, on_delete=models.CASCADE)
    quantite = models.PositiveIntegerField(default=1)
    prix_unitaire = models.DecimalField(max_digits=10, decimal_places=2)
    
    def __str__(self):
        return f"{self.quantite} x {self.produit.nom}"
    
    @property
    def sous_total(self):
        return self.prix_unitaire * self.quantite

class Colis(models.Model):
    """نموذج الطرد المرسل"""
    STATUT_CHOICES = [
        ('En attente', 'En attente'),
        ('En Transit', 'En Transit'),
        ('Livre', 'Livré'),
    ]
    
    id_colis = models.AutoField(primary_key=True)
    expediteur = models.ForeignKey('utilisateurs.Client', related_name='colis_expedies', on_delete=models.CASCADE)
    destinataire = models.ForeignKey('utilisateurs.Client', related_name='colis_recus', on_delete=models.CASCADE)
    poids = models.FloatField()
    description = models.TextField(null=True, blank=True)
    dimensions = models.CharField(max_length=100, null=True, blank=True)
    statut = models.CharField(max_length=15, choices=STATUT_CHOICES, default='En attente')
    montant = models.FloatField()
    commande = models.OneToOneField(Commande, on_delete=models.CASCADE, null=True, blank=True, related_name='colis_associe')
    
    def __str__(self):
        return f"Colis #{self.id_colis} - {self.statut}"

class Voyage(models.Model):
    """نموذج رحلة المستخدم"""
    STATUT_CHOICES = [
        ('En attente', 'En attente'),
        ('Acceptée', 'Acceptée'),
        ('En route', 'En route'),
        ('Terminée', 'Terminée'),
        ('Annulée', 'Annulée'),
    ]
    id_voyage = models.AutoField(primary_key=True)
    voyageur = models.ForeignKey('utilisateurs.Client', on_delete=models.CASCADE)
    destination = models.CharField(max_length=255)
    date_depart = models.DateTimeField()
    date_arrivee = models.DateTimeField()
    poids_disponible = models.FloatField()
    tarif_transport = models.FloatField()
    statut = models.CharField(max_length=20, choices=STATUT_CHOICES, default='En attente')
    
    def __str__(self):
        return f"Voyage vers {self.destination} le {self.date_depart}"
