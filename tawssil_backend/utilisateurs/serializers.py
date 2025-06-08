from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.conf import settings
import jwt
from datetime import datetime, timedelta
from .models import Utilisateur, Client, Livreur, Chauffeur, Administrateur, Fournisseur
# استيراد النماذج من تطبيقاتها الجديدة
from produits.models import Produit
from commandes.models import Commande, LigneCommande
from evaluations.models import Evaluation
from messaging.models import Message
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.hashers import make_password
import re

class UserRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = [
            'username', 'email', 'password', 'telephone', 
            'type_utilisateur', 'date_naissance', 'photo_profile'
        ]
        extra_kwargs = {
            'password': {'write_only': True},
            'photo_profile': {'required': False}
        }

    def create(self, validated_data):
        # تعيين صورة افتراضية إذا لم يتم تقديم صورة
        if 'photo_profile' not in validated_data or validated_data['photo_profile'] is None:
            validated_data['photo_profile'] = 'utilisateurs/photos/person-18'
            
        password = validated_data.pop('password', None)
        instance = self.Meta.model(**validated_data)
        if password is not None:
            instance.set_password(password)
        instance.save()
        return instance

def create_jwt_token(user):
    """
    إنشاء توكن JWT متوافق مع rest_framework_simplejwt
    """
    refresh = RefreshToken.for_user(user)
    refresh['id_utilisateur'] = user.id_utilisateur
    refresh['email'] = user.email
    refresh['username'] = user.username
    refresh['type_utilisateur'] = user.type_utilisateur
    return str(refresh.access_token), str(refresh)

def jwt_decode_handler(token):
    """
    دالة مساعدة لفك تشفير JWT token
    """
    try:
        return jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
        )
    except jwt.ExpiredSignatureError:
        raise serializers.ValidationError('Token has expired')
    except jwt.InvalidTokenError:
        raise serializers.ValidationError('Invalid token')

class MyTokenObtainPairSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(write_only=True, required=True)
    
    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')
        if not email:
            raise serializers.ValidationError({
                'error': 'يجب توفير البريد الإلكتروني'
            })
        if not password:
            raise serializers.ValidationError({
                'error': 'كلمة المرور مطلوبة'
            })
        user = Utilisateur.objects.filter(email=email, is_active=True).first()
        if not user or not user.check_password(password):
            raise serializers.ValidationError({
                'error': 'لا يوجد حساب نشط بهذه البيانات'
            })
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])
        access_token, refresh_token = create_jwt_token(user)
        return {
            'refresh': refresh_token,
            'access': access_token,
            'user': {
                'id_utilisateur': user.id_utilisateur,
                'username': user.username,
                'email': user.email,
                'type_utilisateur': user.type_utilisateur
            }
        }

class MyTokenObtainPairView(APIView):
    """
    طريقة مخصصة للحصول على توكن
    """
    def post(self, request, *args, **kwargs):
        serializer = MyTokenObtainPairSerializer(data=request.data)
        if serializer.is_valid():
            return Response(serializer.validated_data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MyTokenRefreshView(APIView):
    """
    طريقة مخصصة لتحديث التوكن
    """
    def post(self, request, *args, **kwargs):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response({
                'error': 'يجب توفير توكن التحديث'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # فك ترميز الـ refresh token
            decoded_token = jwt_decode_handler(refresh_token)
            
            # التحقق من صحة التوكن
            if decoded_token.get('token_type') != 'refresh':
                return Response({
                    'error': 'توكن غير صالح'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # الحصول على معرف المستخدم
            user_id = decoded_token.get('id_utilisateur') or decoded_token.get('user_id')
            if not user_id:
                return Response({
                    'error': 'توكن غير صالح - لا يحتوي على معرف المستخدم'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # البحث عن المستخدم
            user = Utilisateur.objects.get(id_utilisateur=user_id)
            
            # إنشاء توكن جديد
            access_token, new_refresh_token = create_jwt_token(user)
            
            return Response({
                'access': access_token,
                'refresh': new_refresh_token
            }, status=status.HTTP_200_OK)
            
        except serializers.ValidationError as e:
            return Response({
                'error': str(e)
            }, status=status.HTTP_401_UNAUTHORIZED)
        except Utilisateur.DoesNotExist:
            return Response({
                'error': 'المستخدم غير موجود'
            }, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({
                'error': f'حدث خطأ: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = [
            'id_utilisateur', 'username', 'email', 'telephone', 'adresse',
            'type_utilisateur', 'is_active', 'date_joined',
            'last_login', 'date_naissance', 'photo_profile'
        ]
        read_only_fields = ['id_utilisateur', 'date_joined', 'last_login']

class UserListSerializer(serializers.ModelSerializer):
    """
    سيريلايزر لعرض قائمة المستخدمين
    """
    class Meta:
        model = Utilisateur
        fields = [
            'id_utilisateur', 'username', 'email', 'telephone', 'adresse',
            'type_utilisateur', 'is_active', 'date_joined',
            'last_login', 'date_naissance', 'photo_profile'
        ]

class UserUpdateSerializer(serializers.ModelSerializer):
    """
    سيريلايزر لتحديث بيانات المستخدم
    """
    class Meta:
        model = Utilisateur
        fields = [
            'username', 'email', 'telephone', 'adresse',
            'date_naissance', 'photo_profile', 'is_active'
        ]
        extra_kwargs = {
            'email': {'required': False},
            'telephone': {'required': False},
            'adresse': {'required': False},
            'date_naissance': {'required': False},
            'photo_profile': {'required': False},
            'is_active': {'required': False},
        }

class ClientSerializer(serializers.ModelSerializer):
    utilisateur = UserListSerializer(read_only=True)
    
    class Meta:
        model = Client
        fields = '__all__'

class LivreurSerializer(serializers.ModelSerializer):
    utilisateur = UserListSerializer(read_only=True)
    
    class Meta:
        model = Livreur
        fields = '__all__'

class ChauffeurSerializer(serializers.ModelSerializer):
    utilisateur = UserListSerializer(read_only=True)
    
    class Meta:
        model = Chauffeur
        fields = '__all__'

class FournisseurSerializer(serializers.ModelSerializer):
    utilisateur = UserListSerializer(read_only=True)
    
    class Meta:
        model = Fournisseur
        fields = '__all__'

class AdministrateurSerializer(serializers.ModelSerializer):
    utilisateur = UserListSerializer(read_only=True)
    
    class Meta:
        model = Administrateur
        fields = '__all__'

class ProductSerializer(serializers.ModelSerializer):
    """سيريلايزر للمنتجات"""
    fournisseur_nom = serializers.SerializerMethodField()
    
    class Meta:
        model = Produit
        fields = '__all__'
    
    def get_fournisseur_nom(self, obj):
        return obj.fournisseur.nom_commerce if obj.fournisseur else None

class CommandeSerializer(serializers.ModelSerializer):
    """سيريلايزر للطلبات"""
    client_info = serializers.SerializerMethodField()
    fournisseur_info = serializers.SerializerMethodField()
    livreur_info = serializers.SerializerMethodField()
    chauffeur_info = serializers.SerializerMethodField()
    elements = serializers.SerializerMethodField()
    
    class Meta:
        model = Commande
        fields = '__all__'
    
    def get_client_info(self, obj):
        if obj.client:
            user = obj.client.utilisateur
            return {
                'id': obj.client.id,
                'nom': user.nom,
                'prenom': user.prenom,
                'email': user.email,
                'telephone': user.telephone
            }
        return None
    
    def get_fournisseur_info(self, obj):
        if obj.fournisseur:
            return {
                'id': obj.fournisseur.id,
                'nom_commerce': obj.fournisseur.nom_commerce,
                'type_fournisseur': obj.fournisseur.type_fournisseur,
                'email': obj.fournisseur.utilisateur.email
            }
        return None
    
    def get_livreur_info(self, obj):
        if obj.livreur:
            user = obj.livreur.utilisateur
            return {
                'id': obj.livreur.id,
                'nom': user.nom,
                'prenom': user.prenom,
                'telephone': user.telephone,
                'email': user.email,
                'type_vehicule': obj.livreur.type_vehicule
            }
        return None
    
    def get_chauffeur_info(self, obj):
        if obj.chauffeur:
            user = obj.chauffeur.utilisateur
            return {
                'id': obj.chauffeur.id,
                'nom': user.nom,
                'prenom': user.prenom,
                'telephone': user.telephone,
                'email': user.email,
                'type_vehicule': obj.chauffeur.type_vehicule
            }
        return None
    
    def get_elements(self, obj):
        from .models import LigneCommande
        lignes = LigneCommande.objects.filter(commande=obj)
        elements = []
        for ligne in lignes:
            elements.append({
                'id': ligne.id,
                'produit_id': ligne.produit.id,
                'produit_nom': ligne.produit.nom,
                'quantite': ligne.quantite,
                'prix_unitaire': float(ligne.prix_unitaire),
                'sous_total': float(ligne.sous_total)
            })
        return elements