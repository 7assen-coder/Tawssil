from django.contrib import admin
from .models import Colis, Voyage, Commande

admin.site.register(Colis)
admin.site.register(Voyage)
admin.site.register(Commande)