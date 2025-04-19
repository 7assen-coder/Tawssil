from django.contrib import admin
from .models import (
    Utilisateur, Client, Livreur, Chauffeur, Administrateur,
    Colis, Voyage, Commande, Paiement, Vehicule, Trajet, Notification
)

admin.site.register(Utilisateur)
admin.site.register(Client)
admin.site.register(Livreur)
admin.site.register(Chauffeur)
admin.site.register(Administrateur)
admin.site.register(Colis)
admin.site.register(Voyage)
admin.site.register(Commande)
admin.site.register(Paiement)
admin.site.register(Vehicule)
admin.site.register(Trajet)
admin.site.register(Notification)
