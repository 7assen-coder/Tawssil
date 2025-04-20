from django.db import models

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
    photo_cart = models.TextField(null=True, blank=True)
    
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
    
    id_livreur = models.OneToOneField(Utilisateur, primary_key=True, on_delete=models.CASCADE)
    type_transport = models.CharField(max_length=10, choices=TYPE_TRANSPORT_CHOICES, null=True, blank=True)
    disponibilite = models.BooleanField(default=False)
    zone_couverture = models.CharField(max_length=255, null=True, blank=True)
    
    def __str__(self):
        return f"Livreur: {self.id_livreur.prenom} {self.id_livreur.nom}"

class Chauffeur(models.Model):
    id_chauffeur = models.OneToOneField(Utilisateur, primary_key=True, on_delete=models.CASCADE)
    note_moyenne = models.FloatField(null=True, blank=True, default=0)
    disponibilite = models.BooleanField(default=False)
    
    def __str__(self):
        return f"Chauffeur: {self.id_chauffeur.prenom} {self.id_chauffeur.nom}"

class Administrateur(models.Model):
    id_admin = models.OneToOneField(Utilisateur, primary_key=True, on_delete=models.CASCADE)
    
    def __str__(self):
        return f"Admin: {self.id_admin.prenom} {self.id_admin.nom}"