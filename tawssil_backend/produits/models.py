from django.db import models
from utilisateurs.models import Fournisseur

class Produit(models.Model):
    """نموذج المنتج المقدم من المزود"""
    fournisseur = models.ForeignKey(Fournisseur, on_delete=models.CASCADE, related_name='produits')
    nom = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    prix = models.DecimalField(max_digits=10, decimal_places=2)
    categorie = models.CharField(max_length=100, null=True, blank=True)
    disponible = models.BooleanField(default=True)
    image = models.ImageField(upload_to='produits/images', null=True, blank=True)
    
    def __str__(self):
        return f"{self.nom} - {self.prix} DZD"
