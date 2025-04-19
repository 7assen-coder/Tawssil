from django.shortcuts import render
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.shortcuts import get_object_or_404

from .models import (
    Utilisateur, Client, Livreur, Chauffeur, Administrateur,
    Colis, Voyage, Commande, Paiement, Vehicule, Trajet, Notification
)
from .serializers import (
    UtilisateurSerializer, ClientSerializer, ClientCreateSerializer,
    LivreurSerializer, LivreurCreateSerializer, ChauffeurSerializer, 
    ChauffeurCreateSerializer, AdministrateurSerializer, AdministrateurCreateSerializer,
    ColisSerializer, VoyageSerializer, CommandeSerializer, PaiementSerializer,
    VehiculeSerializer, TrajetSerializer, NotificationSerializer
)

# Create your views here.

class UtilisateurViewSet(viewsets.ModelViewSet):
    queryset = Utilisateur.objects.all()
    serializer_class = UtilisateurSerializer
    permission_classes = [IsAuthenticated]
    
    def get_permissions(self):
        if self.action in ['list', 'destroy']:
            return [IsAdminUser()]
        return super().get_permissions()

class ClientViewSet(viewsets.ModelViewSet):
    queryset = Client.objects.all()
    serializer_class = ClientSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ClientCreateSerializer
        return ClientSerializer
    
    def get_permissions(self):
        if self.action == 'create':
            return []
        return super().get_permissions()

class LivreurViewSet(viewsets.ModelViewSet):
    queryset = Livreur.objects.all()
    serializer_class = LivreurSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return LivreurCreateSerializer
        return LivreurSerializer
    
    def get_permissions(self):
        if self.action == 'create':
            return []
        return super().get_permissions()
    
    @action(detail=True, methods=['patch'])
    def status_disponibilite(self, request, pk=None):
        livreur = self.get_object()
        disponibilite = request.data.get('disponibilite')
        
        if disponibilite is None:
            return Response({"error": "Le paramètre 'disponibilite' est requis"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        livreur.disponibilite = disponibilite
        livreur.save()
        return Response({"status": "disponibilité mise à jour", "disponibilite": disponibilite})

class ChauffeurViewSet(viewsets.ModelViewSet):
    queryset = Chauffeur.objects.all()
    serializer_class = ChauffeurSerializer
    permission_classes = [IsAuthenticated]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return ChauffeurCreateSerializer
        return ChauffeurSerializer
    
    def get_permissions(self):
        if self.action == 'create':
            return []
        return super().get_permissions()
    
    @action(detail=True, methods=['patch'])
    def status_disponibilite(self, request, pk=None):
        chauffeur = self.get_object()
        disponibilite = request.data.get('disponibilite')
        
        if disponibilite is None:
            return Response({"error": "Le paramètre 'disponibilite' est requis"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        chauffeur.disponibilite = disponibilite
        chauffeur.save()
        return Response({"status": "disponibilité mise à jour", "disponibilite": disponibilite})
    
    @action(detail=True, methods=['patch'])
    def update_note(self, request, pk=None):
        chauffeur = self.get_object()
        note = request.data.get('note')
        
        if note is None:
            return Response({"error": "Le paramètre 'note' est requis"}, 
                            status=status.HTTP_400_BAD_REQUEST)
            
        try:
            note = float(note)
            if note < 0 or note > 5:
                return Response({"error": "La note doit être entre 0 et 5"}, 
                                status=status.HTTP_400_BAD_REQUEST)
        except ValueError:
            return Response({"error": "La note doit être un nombre"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        chauffeur.note_moyenne = note
        chauffeur.save()
        return Response({"status": "note mise à jour", "note_moyenne": note})

class AdministrateurViewSet(viewsets.ModelViewSet):
    queryset = Administrateur.objects.all()
    serializer_class = AdministrateurSerializer
    permission_classes = [IsAdminUser]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return AdministrateurCreateSerializer
        return AdministrateurSerializer

class ColisViewSet(viewsets.ModelViewSet):
    queryset = Colis.objects.all()
    serializer_class = ColisSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'client_profile'):
            # Filtre pour voir seulement les colis du client
            return Colis.objects.filter(expediteur=user.client_profile)
        elif user.is_staff:
            # Les administrateurs peuvent voir tous les colis
            return Colis.objects.all()
        return Colis.objects.none()
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        colis = self.get_object()
        statut = request.data.get('statut')
        
        if statut not in ['En attente', 'En Transit', 'Livre']:
            return Response({"error": "Statut invalide"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        colis.statut = statut
        colis.save()
        return Response({"status": "statut mis à jour", "statut": statut})

class VoyageViewSet(viewsets.ModelViewSet):
    queryset = Voyage.objects.all()
    serializer_class = VoyageSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'client_profile'):
            # Filtre pour voir seulement les voyages du client
            return Voyage.objects.filter(voyageur=user.client_profile)
        elif user.is_staff:
            # Les administrateurs peuvent voir tous les voyages
            return Voyage.objects.all()
        return Voyage.objects.none()

class CommandeViewSet(viewsets.ModelViewSet):
    queryset = Commande.objects.all()
    serializer_class = CommandeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'client_profile'):
            # Filtre pour voir seulement les commandes du client
            return Commande.objects.filter(client=user.client_profile)
        elif hasattr(user, 'livreur_profile'):
            # Filtre pour voir seulement les commandes du livreur
            return Commande.objects.filter(livreur=user.livreur_profile)
        elif user.is_staff:
            # Les administrateurs peuvent voir toutes les commandes
            return Commande.objects.all()
        return Commande.objects.none()
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        commande = self.get_object()
        statut = request.data.get('statut')
        
        if statut not in ['En attente', 'Acceptee', 'En cours', 'Terminee', 'Annulee']:
            return Response({"error": "Statut invalide"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        commande.statut = statut
        commande.save()
        return Response({"status": "statut mis à jour", "statut": statut})

class PaiementViewSet(viewsets.ModelViewSet):
    queryset = Paiement.objects.all()
    serializer_class = PaiementSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'client_profile'):
            # Filtre pour voir seulement les paiements liés aux commandes du client
            return Paiement.objects.filter(commande__client=user.client_profile)
        elif hasattr(user, 'livreur_profile'):
            # Filtre pour voir seulement les paiements liés aux commandes du livreur
            return Paiement.objects.filter(commande__livreur=user.livreur_profile)
        elif user.is_staff:
            # Les administrateurs peuvent voir tous les paiements
            return Paiement.objects.all()
        return Paiement.objects.none()
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        paiement = self.get_object()
        statut = request.data.get('statut')
        
        if statut not in ['En Attente', 'Confirme', 'Echoue']:
            return Response({"error": "Statut invalide"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        paiement.statut = statut
        paiement.save()
        return Response({"status": "statut mis à jour", "statut": statut})

class VehiculeViewSet(viewsets.ModelViewSet):
    queryset = Vehicule.objects.all()
    serializer_class = VehiculeSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'chauffeur_profile'):
            # Filtre pour voir seulement les véhicules du chauffeur
            return Vehicule.objects.filter(chauffeur=user.chauffeur_profile)
        elif user.is_staff:
            # Les administrateurs peuvent voir tous les véhicules
            return Vehicule.objects.all()
        return Vehicule.objects.none()
    
    @action(detail=True, methods=['patch'])
    def update_disponibilite(self, request, pk=None):
        vehicule = self.get_object()
        disponible = request.data.get('disponible')
        
        if disponible is None:
            return Response({"error": "Le paramètre 'disponible' est requis"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        vehicule.disponible = disponible
        vehicule.save()
        return Response({"status": "disponibilité mise à jour", "disponible": disponible})

class TrajetViewSet(viewsets.ModelViewSet):
    queryset = Trajet.objects.all()
    serializer_class = TrajetSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'client_profile'):
            # Filtre pour voir seulement les trajets du client
            return Trajet.objects.filter(client=user.client_profile)
        elif hasattr(user, 'chauffeur_profile'):
            # Filtre pour voir seulement les trajets du chauffeur
            return Trajet.objects.filter(chauffeur=user.chauffeur_profile)
        elif user.is_staff:
            # Les administrateurs peuvent voir tous les trajets
            return Trajet.objects.all()
        return Trajet.objects.none()
    
    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        trajet = self.get_object()
        statut = request.data.get('statut')
        
        if statut not in ['En attente', 'En cours', 'Termine']:
            return Response({"error": "Statut invalide"}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        trajet.statut = statut
        trajet.save()
        return Response({"status": "statut mis à jour", "statut": statut})

class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        # Chaque utilisateur ne voit que ses propres notifications
        return Notification.objects.filter(utilisateur=user.id_utilisateur)
    
    @action(detail=True, methods=['patch'])
    def mark_as_read(self, request, pk=None):
        notification = self.get_object()
        notification.statut = 'Lu'
        notification.save()
        return Response({"status": "notification marquée comme lue"})
    
    @action(detail=False, methods=['patch'])
    def mark_all_as_read(self, request):
        # Marque toutes les notifications de l'utilisateur comme lues
        notifications = self.get_queryset().filter(statut='Non Lu')
        notifications.update(statut='Lu')
        return Response({"status": f"{notifications.count()} notifications marquées comme lues"})
