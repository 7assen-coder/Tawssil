from django.db import models
from django.utils import timezone

class Utilisateur(models.Model):
    TYPE_UTILISATEUR_CHOICES = [
        ('Client', 'Client'),
        ('Livreur', 'Livreur'),
        ('Chauffeur', 'Chauffeur'),
        ('Administrateur', 'Administrateur'),
    ]
    
    id_utilisateur = models.AutoField(primary_key=True)
    nom = models.CharField(max_length=100, null=True, blank=True)
    prenom = models.CharField(max_length=100, null=True, blank=True)
    email = models.EmailField(max_length=255, unique=True)
    mot_de_passe = models.CharField(max_length=255)
    telephone = models.CharField(max_length=20, null=True, blank=True)
    adresse = models.TextField(null=True, blank=True)
    type_utilisateur = models.CharField(max_length=15, choices=TYPE_UTILISATEUR_CHOICES)
    photo_cart = models.ImageField(upload_to='utilisateurs/photos', null=True, blank=True)
    date_joined = models.DateTimeField(default=timezone.now)
    last_login = models.DateTimeField(null=True, blank=True)
    last_modified = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    
    def __str__(self):
        return f"{self.prenom} {self.nom} ({self.email})"

class Client(models.Model):
    id_client = models.OneToOneField(Utilisateur, primary_key=True, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Client: {self.id_client.prenom} {self.id_client.nom}"

class Livreur(models.Model):
    TYPE_TRANSPORT_CHOICES = [
        ('Moto', 'Moto'),
        ('Camion', 'Camion'),
    ]
    
    id_livreur = models.OneToOneField(Utilisateur, primary_key=True, on_delete=models.CASCADE, related_name='profil_livreur')
    type_transport = models.CharField(max_length=10, choices=TYPE_TRANSPORT_CHOICES, null=True, blank=True)
    note_moyenne = models.FloatField(null=True, blank=True, default=0)
    disponibilite = models.BooleanField(default=False)
    zone_couverture = models.CharField(max_length=255, null=True, blank=True)
    photo_voiture = models.ImageField(upload_to='livreurs/photos/voitures', null=True, blank=True)
    matricule_voiture = models.CharField(max_length=50, null=True, blank=True)
    photo_permis = models.ImageField(upload_to='livreurs/photos/permis', null=True, blank=True)
    photo_carte_grise = models.ImageField(upload_to='livreurs/photos/papiers/carte_grise', null=True, blank=True)
    photo_assurance = models.ImageField(upload_to='livreurs/photos/papiers/assurance', null=True, blank=True)
    photo_vignette = models.ImageField(upload_to='livreurs/photos/papiers/vignette', null=True, blank=True)
    photo_carte_municipale = models.ImageField(upload_to='livreurs/photos/papiers/municipale', null=True, blank=True)
    
    def __str__(self):
        return f"Livreur: {self.id_livreur.prenom} {self.id_livreur.nom}"

class Chauffeur(models.Model):
    id_chauffeur = models.OneToOneField(
        Utilisateur, 
        primary_key=True, 
        on_delete=models.CASCADE, 
        related_name='profil_chauffeur'
    )
    note_moyenne = models.FloatField(null=True, blank=True, default=0)
    disponibilite = models.BooleanField(default=False)
    type_voiture = models.CharField(max_length=100, null=True, blank=True)
    photo_voiture = models.ImageField(upload_to='chauffeurs/photos/voitures', null=True, blank=True)
    matricule_voiture = models.CharField(max_length=50, null=True, blank=True)
    photo_permis = models.ImageField(upload_to='chauffeurs/photos/permis', null=True, blank=True)
    photo_carte_grise = models.ImageField(upload_to='chauffeurs/photos/papiers/carte_grise', null=True, blank=True)
    photo_assurance = models.ImageField(upload_to='chauffeurs/photos/papiers/assurance', null=True, blank=True)
    photo_vignette = models.ImageField(upload_to='chauffeurs/photos/papiers/vignette', null=True, blank=True)
    photo_carte_municipale = models.ImageField(upload_to='chauffeurs/photos/papiers/municipale', null=True, blank=True)
    
    def __str__(self):
        return f"Chauffeur: {self.id_chauffeur.prenom} {self.id_chauffeur.nom}"

class Administrateur(models.Model):
    id_admin = models.OneToOneField(
        Utilisateur, 
        primary_key=True, 
        on_delete=models.CASCADE, 
        related_name='profil_admin'
    )
    nom_admin = models.CharField(max_length=100, null=True, blank=True)
    
    def __str__(self):
        return f"Admin: {self.id_admin.prenom} {self.id_admin.nom}"