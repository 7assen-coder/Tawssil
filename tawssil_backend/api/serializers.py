from rest_framework import serializers
from django.contrib.auth.hashers import make_password
from .models import (
    Utilisateur, Client, Livreur, Chauffeur, Administrateur,
    Colis, Voyage, Commande, Paiement, Vehicule, Trajet, Notification
)

class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = '__all__'
        extra_kwargs = {'mot_de_passe': {'write_only': True}}

    def create(self, validated_data):
        # Hachage du mot de passe avant sauvegarde
        validated_data['mot_de_passe'] = make_password(validated_data['mot_de_passe'])
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        # Hachage du mot de passe si modifié
        if 'mot_de_passe' in validated_data:
            validated_data['mot_de_passe'] = make_password(validated_data['mot_de_passe'])
        return super().update(instance, validated_data)

class ClientSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer(source='id_client', read_only=True)
    
    class Meta:
        model = Client
        fields = ['id_client', 'utilisateur']
        
class ClientCreateSerializer(serializers.ModelSerializer):
    nom = serializers.CharField(max_length=100, required=False)
    prenom = serializers.CharField(max_length=100, required=False)
    email = serializers.EmailField(max_length=255)
    mot_de_passe = serializers.CharField(max_length=255, write_only=True)
    telephone = serializers.CharField(max_length=20, required=False)
    adresse = serializers.CharField(required=False)
    photo_cart = serializers.CharField(required=False)
    
    class Meta:
        model = Client
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 'adresse', 'photo_cart']
    
    def create(self, validated_data):
        # Créer d'abord l'utilisateur
        utilisateur_data = {
            'nom': validated_data.pop('nom', None),
            'prenom': validated_data.pop('prenom', None),
            'email': validated_data.pop('email'),
            'mot_de_passe': make_password(validated_data.pop('mot_de_passe')),
            'telephone': validated_data.pop('telephone', None),
            'adresse': validated_data.pop('adresse', None),
            'photo_cart': validated_data.pop('photo_cart', None),
            'type_utilisateur': 'Client'
        }
        utilisateur = Utilisateur.objects.create(**utilisateur_data)
        
        # Puis créer le client
        client = Client.objects.create(id_client=utilisateur)
        return client

class LivreurSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer(source='id_livreur', read_only=True)
    
    class Meta:
        model = Livreur
        fields = ['id_livreur', 'type_transport', 'disponibilite', 'zone_couverture', 'utilisateur']

class LivreurCreateSerializer(serializers.ModelSerializer):
    nom = serializers.CharField(max_length=100, required=False)
    prenom = serializers.CharField(max_length=100, required=False)
    email = serializers.EmailField(max_length=255)
    mot_de_passe = serializers.CharField(max_length=255, write_only=True)
    telephone = serializers.CharField(max_length=20, required=False)
    adresse = serializers.CharField(required=False)
    photo_cart = serializers.CharField(required=False)
    type_transport = serializers.ChoiceField(choices=['Moto', 'Camion'], required=False)
    disponibilite = serializers.BooleanField(required=False)
    zone_couverture = serializers.CharField(required=False)
    
    class Meta:
        model = Livreur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 'adresse', 
                  'photo_cart', 'type_transport', 'disponibilite', 'zone_couverture']
    
    def create(self, validated_data):
        # Extraire les données du livreur
        type_transport = validated_data.pop('type_transport', None)
        disponibilite = validated_data.pop('disponibilite', None)
        zone_couverture = validated_data.pop('zone_couverture', None)
        
        # Créer l'utilisateur
        utilisateur_data = {
            'nom': validated_data.pop('nom', None),
            'prenom': validated_data.pop('prenom', None),
            'email': validated_data.pop('email'),
            'mot_de_passe': make_password(validated_data.pop('mot_de_passe')),
            'telephone': validated_data.pop('telephone', None),
            'adresse': validated_data.pop('adresse', None),
            'photo_cart': validated_data.pop('photo_cart', None),
            'type_utilisateur': 'Livreur'
        }
        utilisateur = Utilisateur.objects.create(**utilisateur_data)
        
        # Créer le livreur
        livreur = Livreur.objects.create(
            id_livreur=utilisateur,
            type_transport=type_transport,
            disponibilite=disponibilite,
            zone_couverture=zone_couverture
        )
        return livreur

class ChauffeurSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer(source='id_chauffeur', read_only=True)
    
    class Meta:
        model = Chauffeur
        fields = ['id_chauffeur', 'note_moyenne', 'disponibilite', 'utilisateur']

class ChauffeurCreateSerializer(serializers.ModelSerializer):
    nom = serializers.CharField(max_length=100, required=False)
    prenom = serializers.CharField(max_length=100, required=False)
    email = serializers.EmailField(max_length=255)
    mot_de_passe = serializers.CharField(max_length=255, write_only=True)
    telephone = serializers.CharField(max_length=20, required=False)
    adresse = serializers.CharField(required=False)
    photo_cart = serializers.CharField(required=False)
    note_moyenne = serializers.FloatField(required=False)
    disponibilite = serializers.BooleanField(required=False)
    
    class Meta:
        model = Chauffeur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 
                  'adresse', 'photo_cart', 'note_moyenne', 'disponibilite']
    
    def create(self, validated_data):
        # Extraire les données du chauffeur
        note_moyenne = validated_data.pop('note_moyenne', None)
        disponibilite = validated_data.pop('disponibilite', None)
        
        # Créer l'utilisateur
        utilisateur_data = {
            'nom': validated_data.pop('nom', None),
            'prenom': validated_data.pop('prenom', None),
            'email': validated_data.pop('email'),
            'mot_de_passe': make_password(validated_data.pop('mot_de_passe')),
            'telephone': validated_data.pop('telephone', None),
            'adresse': validated_data.pop('adresse', None),
            'photo_cart': validated_data.pop('photo_cart', None),
            'type_utilisateur': 'Chauffeur'
        }
        utilisateur = Utilisateur.objects.create(**utilisateur_data)
        
        # Créer le chauffeur
        chauffeur = Chauffeur.objects.create(
            id_chauffeur=utilisateur,
            note_moyenne=note_moyenne,
            disponibilite=disponibilite
        )
        return chauffeur

class AdministrateurSerializer(serializers.ModelSerializer):
    utilisateur = UtilisateurSerializer(source='id_admin', read_only=True)
    
    class Meta:
        model = Administrateur
        fields = ['id_admin', 'utilisateur']

class AdministrateurCreateSerializer(serializers.ModelSerializer):
    nom = serializers.CharField(max_length=100, required=False)
    prenom = serializers.CharField(max_length=100, required=False)
    email = serializers.EmailField(max_length=255)
    mot_de_passe = serializers.CharField(max_length=255, write_only=True)
    telephone = serializers.CharField(max_length=20, required=False)
    adresse = serializers.CharField(required=False)
    photo_cart = serializers.CharField(required=False)
    
    class Meta:
        model = Administrateur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 'adresse', 'photo_cart']
    
    def create(self, validated_data):
        # Créer l'utilisateur
        utilisateur_data = {
            'nom': validated_data.pop('nom', None),
            'prenom': validated_data.pop('prenom', None),
            'email': validated_data.pop('email'),
            'mot_de_passe': make_password(validated_data.pop('mot_de_passe')),
            'telephone': validated_data.pop('telephone', None),
            'adresse': validated_data.pop('adresse', None),
            'photo_cart': validated_data.pop('photo_cart', None),
            'type_utilisateur': 'Administrateur'
        }
        utilisateur = Utilisateur.objects.create(**utilisateur_data)
        
        # Créer l'administrateur
        admin = Administrateur.objects.create(id_admin=utilisateur)
        return admin

class ColisSerializer(serializers.ModelSerializer):
    expediteur_info = ClientSerializer(source='expediteur', read_only=True)
    destinataire_info = ClientSerializer(source='destinataire', read_only=True)
    
    class Meta:
        model = Colis
        fields = ['id_colis', 'expediteur', 'destinataire', 'poids', 'description', 
                  'dimensions', 'statut', 'montant', 'expediteur_info', 'destinataire_info']

class VoyageSerializer(serializers.ModelSerializer):
    voyageur_info = ClientSerializer(source='voyageur', read_only=True)
    
    class Meta:
        model = Voyage
        fields = ['id_voyage', 'voyageur', 'destination', 'date_depart', 
                  'date_arrivee', 'poids_disponible', 'tarif_transport', 'voyageur_info']

class CommandeSerializer(serializers.ModelSerializer):
    client_info = ClientSerializer(source='client', read_only=True)
    livreur_info = LivreurSerializer(source='livreur', read_only=True)
    
    class Meta:
        model = Commande
        fields = ['id_commande', 'client', 'livreur', 'adresse_depart', 'adresse_arrivee',
                  'methode_paiement', 'montant', 'statut', 'qr_code', 'recu_transaction',
                  'client_info', 'livreur_info']

class PaiementSerializer(serializers.ModelSerializer):
    commande_info = CommandeSerializer(source='commande', read_only=True)
    
    class Meta:
        model = Paiement
        fields = ['id_paiement', 'commande', 'methode', 'statut', 'recu', 'commande_info']

class VehiculeSerializer(serializers.ModelSerializer):
    chauffeur_info = ChauffeurSerializer(source='chauffeur', read_only=True)
    
    class Meta:
        model = Vehicule
        fields = ['id_vehicule', 'chauffeur', 'marque', 'matricule', 'type', 'disponible', 'chauffeur_info']

class TrajetSerializer(serializers.ModelSerializer):
    chauffeur_info = ChauffeurSerializer(source='chauffeur', read_only=True)
    client_info = ClientSerializer(source='client', read_only=True)
    
    class Meta:
        model = Trajet
        fields = ['id_trajet', 'chauffeur', 'client', 'adresse_depart', 
                 'adresse_arrivee', 'prix', 'statut', 'chauffeur_info', 'client_info']

class NotificationSerializer(serializers.ModelSerializer):
    utilisateur_info = UtilisateurSerializer(source='utilisateur', read_only=True)
    
    class Meta:
        model = Notification
        fields = ['id_notification', 'utilisateur', 'message', 'date_envoi', 'statut', 'utilisateur_info']
