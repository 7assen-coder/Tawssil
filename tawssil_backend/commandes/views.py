from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Commande, LigneCommande, Colis, Voyage
from django.utils import timezone
from datetime import timedelta
from django.db.models import Sum, F, Q
from rest_framework import serializers
from utilisateurs.models import Utilisateur, Client, Fournisseur, Livreur, Chauffeur


# دوال العرض (views) ستضاف لاحقا

@api_view(['GET'])
def active_deliveries_count(request):
    try:
        count = Commande.objects.filter(
            Q(statut__icontains='accept') |
            Q(statut__icontains='prépar') |
            Q(statut__icontains='livraison')
        ).count()
        return Response({'active_deliveries': count})
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def last_month_active_deliveries_count(request):
    now = timezone.now()
    first_day_this_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    last_month_end = first_day_this_month - timedelta(seconds=1)
    last_month_start = last_month_end.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    count = Commande.objects.filter(
        statut='En livraison',
        date_commande__gte=last_month_start,
        date_commande__lte=last_month_end
    ).count()
    return Response({'last_month_active_deliveries': count})

@api_view(['GET'])
def today_revenue(request):
    now = timezone.localtime()
    start_of_day = now.replace(hour=0, minute=0, second=0, microsecond=0)
    commandes = Commande.objects.filter(
        statut='Livrée',
        date_commande__gte=start_of_day,
        date_commande__lte=now
    )
    total_montant = commandes.aggregate(total=Sum('montant_total'))['total'] or 0
    total_frais = commandes.aggregate(total=Sum('frais_livraison'))['total'] or 0
    revenue = float(total_montant) - float(total_frais)
    return Response({'today_revenue': revenue})

@api_view(['GET'])
def yesterday_revenue(request):
    yesterday = timezone.now().date() - timedelta(days=1)
    total = Commande.objects.filter(
        statut='Livrée',
        date_commande__date=yesterday
    ).aggregate(
        revenue=Sum(F('montant_total') - F('frais_livraison'))
    )['revenue'] or 0
    return Response({'yesterday_revenue': float(total)})

class CommandeRecentSerializer(serializers.ModelSerializer):
    chauffeur_username = serializers.SerializerMethodField()
    client_username = serializers.SerializerMethodField()
    class Meta:
        model = Commande
        fields = ['id_commande', 'chauffeur_username', 'client_username', 'date_commande', 'adresse_livraison', 'montant_total', 'statut']
    def get_chauffeur_username(self, obj):
        return obj.chauffeur.utilisateur.username if obj.chauffeur and obj.chauffeur.utilisateur else None
    def get_client_username(self, obj):
        return obj.client.utilisateur.username if obj.client and obj.client.utilisateur else None

@api_view(['GET'])
def recent_chauffeur_demandes(request):
    commandes = Commande.objects.filter(chauffeur__isnull=False).order_by('-date_commande')[:10]
    serializer = CommandeRecentSerializer(commandes, many=True)
    return Response(serializer.data)

class CommandeRecentLivreurSerializer(serializers.ModelSerializer):
    livreur_username = serializers.SerializerMethodField()
    client_username = serializers.SerializerMethodField()
    class Meta:
        model = Commande
        fields = ['id_commande', 'livreur_username', 'client_username', 'date_commande', 'adresse_livraison', 'montant_total', 'statut']
    def get_livreur_username(self, obj):
        return obj.livreur.utilisateur.username if obj.livreur and obj.livreur.utilisateur else None
    def get_client_username(self, obj):
        return obj.client.utilisateur.username if obj.client and obj.client.utilisateur else None

@api_view(['GET'])
def recent_livreur_livraisons(request):
    commandes = Commande.objects.filter(livreur__isnull=False).order_by('-date_commande')[:10]
    serializer = CommandeRecentLivreurSerializer(commandes, many=True)
    return Response(serializer.data)

class VoyageRecentSerializer(serializers.ModelSerializer):
    voyageur_username = serializers.SerializerMethodField()
    class Meta:
        model = Voyage
        fields = ['id_voyage', 'voyageur_username', 'destination', 'tarif_transport', 'poids_disponible', 'date_depart']
    def get_voyageur_username(self, obj):
        return obj.voyageur.utilisateur.username if obj.voyageur and obj.voyageur.utilisateur else None

@api_view(['GET'])
def recent_voyages(request):
    voyages = Voyage.objects.order_by('-date_depart')[:10]
    serializer = VoyageRecentSerializer(voyages, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def commandes_stats(request):
    total_commandes = Commande.objects.count()
    total_clients = Utilisateur.objects.filter(type_utilisateur='Client').count()
    moyenne = (total_commandes / total_clients) if total_clients > 0 else 0
    return Response({
        'total_commandes': total_commandes,
        'total_clients': total_clients,
        'moyenne': round(moyenne, 2)
    })

class CommandeFullSerializer(serializers.ModelSerializer):
    client_username = serializers.SerializerMethodField()
    fournisseur_nom = serializers.SerializerMethodField()
    livreur_username = serializers.SerializerMethodField()
    chauffeur_username = serializers.SerializerMethodField()
    class Meta:
        model = Commande
        fields = [
            'id_commande', 'client_username', 'fournisseur_nom', 'livreur_username', 'chauffeur_username',
            'date_commande', 'adresse_livraison', 'montant_total', 'frais_livraison',
            'statut', 'instructions_speciales', 'date_livraison_estimee', 'date_livraison_reelle'
        ]
    def get_client_username(self, obj):
        return obj.client.utilisateur.username if obj.client and obj.client.utilisateur else ''
    def get_fournisseur_nom(self, obj):
        return obj.fournisseur.nom_commerce if obj.fournisseur else ''
    def get_livreur_username(self, obj):
        return obj.livreur.utilisateur.username if obj.livreur and obj.livreur.utilisateur else ''
    def get_chauffeur_username(self, obj):
        return obj.chauffeur.utilisateur.username if obj.chauffeur and obj.chauffeur.utilisateur else ''

@api_view(['GET'])
def commandes_list(request):
    commandes = Commande.objects.all().order_by('-date_commande')
    serializer = CommandeFullSerializer(commandes, many=True)
    return Response(serializer.data)

class VoyageFullSerializer(serializers.ModelSerializer):
    voyageur_username = serializers.SerializerMethodField()
    nombre_personnes = serializers.SerializerMethodField()
    class Meta:
        model = Voyage
        fields = [
            'id_voyage', 'voyageur_username', 'destination', 'date_depart', 'date_arrivee',
            'nombre_personnes', 'tarif_transport', 'statut'
        ]
    def get_voyageur_username(self, obj):
        return obj.voyageur.utilisateur.username if obj.voyageur and obj.voyageur.utilisateur else ''
    def get_nombre_personnes(self, obj):
        return obj.poids_disponible

@api_view(['GET'])
def voyages_list(request):
    voyages = Voyage.objects.all().order_by('-date_depart')
    serializer = VoyageFullSerializer(voyages, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def commandes_by_provider(request, provider_id):
    try:
        fournisseur = Fournisseur.objects.get(id=provider_id)
        commandes = Commande.objects.filter(fournisseur=fournisseur).order_by('-date_commande')
        serializer = CommandeFullSerializer(commandes, many=True)
        return Response({'orders': serializer.data})
    except Fournisseur.DoesNotExist:
        return Response({'orders': []}, status=404)
