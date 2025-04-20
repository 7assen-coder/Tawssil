from django.contrib import admin
from .models import Utilisateur, Client, Livreur, Chauffeur, Administrateur

admin.site.register(Utilisateur)
admin.site.register(Client)
admin.site.register(Livreur)
admin.site.register(Chauffeur)
admin.site.register(Administrateur)