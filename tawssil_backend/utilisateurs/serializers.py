from rest_framework import serializers
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.utils import timezone
from django.conf import settings
import jwt
from datetime import datetime, timedelta
from .models import Utilisateur
from rest_framework_simplejwt.tokens import RefreshToken

class UserRegistrationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 'adresse', 'type_utilisateur', 'photo_cart']

    def create(self, validated_data):
        # Set automatic fields
        validated_data['date_joined'] = timezone.now()
        validated_data['is_active'] = True
        
        # Set is_staff based on type_utilisateur
        if validated_data.get('type_utilisateur') == 'Administrateur':
            validated_data['is_staff'] = True
        else:
            validated_data['is_staff'] = False

        # Create the user
        user = Utilisateur.objects.create(**validated_data)
        user.save()
        return user

def create_jwt_token(user):
    """
    إنشاء توكن JWT متوافق مع rest_framework_simplejwt
    """
    # تخصيص RefreshToken.for_user لتتناسب مع نموذج Utilisateur
    refresh = RefreshToken()
    
    # إضافة المعلومات الأساسية المطلوبة من قبل SimpleJWT
    refresh['user_id'] = user.id_utilisateur  # يجب أن تتطابق مع USER_ID_CLAIM في إعدادات SIMPLE_JWT
    
    # إضافة معلومات إضافية عن المستخدم
    refresh['id_utilisateur'] = user.id_utilisateur
    refresh['email'] = user.email
    refresh['nom'] = user.nom
    refresh['prenom'] = user.prenom
    refresh['type_utilisateur'] = user.type_utilisateur
    refresh['is_staff'] = user.is_staff
    
    # إعادة التوكن كنص
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
    email = serializers.EmailField(required=False)
    username = serializers.CharField(required=False)
    mot_de_passe = serializers.CharField(write_only=True, required=True)
    
    def validate(self, attrs):
        email = attrs.get('email')
        username = attrs.get('username')
        password = attrs.get('mot_de_passe')

        if not email and not username:
            raise serializers.ValidationError({
                'error': 'يجب توفير البريد الإلكتروني أو اسم المستخدم'
            })

        if not password:
            raise serializers.ValidationError({
                'error': 'كلمة المرور مطلوبة'
            })

        # البحث عن المستخدم باستخدام البريد الإلكتروني أو اسم المستخدم
        user = None
        if email:
            user = Utilisateur.objects.filter(email=email, is_active=True).first()
        elif username:
            user = Utilisateur.objects.filter(nom=username, is_active=True).first()

        if not user or user.mot_de_passe != password:
            raise serializers.ValidationError({
                'error': 'لا يوجد حساب نشط بهذه البيانات'
            })

        # إنشاء توكن يدويًا
        access_token, refresh_token = create_jwt_token(user)
        
        return {
            'refresh': refresh_token,
            'access': access_token,
            'user': {
                'id_utilisateur': user.id_utilisateur,
                'email': user.email,
                'nom': user.nom,
                'prenom': user.prenom,
                'type_utilisateur': user.type_utilisateur,
                'is_staff': user.is_staff
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

class UserListSerializer(serializers.ModelSerializer):
    """
    سيريلايزر لعرض بيانات المستخدمين بشكل آمن عند استخدامه من قبل المسؤول
    """
    class Meta:
        model = Utilisateur
        fields = [
            'id_utilisateur', 'nom', 'prenom', 'email', 
            'telephone', 'adresse', 'type_utilisateur', 
            'date_joined', 'is_active', 'is_staff'
        ]
        # استبعاد كلمة المرور لأسباب أمنية
        extra_kwargs = {
            'mot_de_passe': {'write_only': True}
        }

class UserUpdateSerializer(serializers.ModelSerializer):
    """
    سيريلايزر لتحديث بيانات المستخدم
    """
    email = serializers.EmailField(required=False)
    mot_de_passe = serializers.CharField(required=False, write_only=True)
    
    class Meta:
        model = Utilisateur
        fields = [
            'nom', 'prenom', 'email', 'mot_de_passe', 
            'telephone', 'adresse', 'photo_cart'
        ]
    
    def update(self, instance, validated_data):
        # تحديث تاريخ آخر تعديل
        validated_data['last_modified'] = timezone.now()
        
        # تحديث البيانات
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        instance.save()
        return instance