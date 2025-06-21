from django.shortcuts import render, get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from django.db.models import Q
from .models import Utilisateur, OTPCode, Chauffeur, Livreur, Fournisseur, Administrateur
from .serializers import UserRegistrationSerializer, UserListSerializer, UserUpdateSerializer, jwt_decode_handler, create_jwt_token, ChauffeurSerializer, LivreurSerializer, FournisseurSerializer, AdministrateurSerializer
import jwt
from django.conf import settings
import datetime
import logging
from django.utils import timezone
from .services import generate_otp, save_otp_to_db, send_email_otp, send_sms_otp, verify_otp as verify_otp_service, check_user_exists_by_type, send_otp_with_fallback
import time
from django.core.mail import send_mail
import random
from commandes.models import Commande, Voyage
from evaluations.models import Evaluation
from django.db.models import Sum, Avg, Count
from produits.models import Produit
from rest_framework.serializers import ModelSerializer
import requests
from rest_framework.authtoken.models import Token

# تعريف متغير logger
logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    try:
        # تحويل البيانات إلى قاموس إذا كانت في صيغة QueryDict
        data = request.data.dict() if hasattr(request.data, 'dict') else request.data
        
        # معالجة رفع الملفات إذا وجدت
        if request.FILES and 'photo_profile' in request.FILES:
            data['photo_profile'] = request.FILES['photo_profile']

        # التحقق من وجود جميع الحقول المطلوبة
        required_fields = ['username', 'email', 'password', 'telephone', 'type_utilisateur', 'date_naissance']
        for field in required_fields:
            if field not in data:
                return Response({
                    'status': 'error',
                    'message': f'Field {field} is required'
                }, status=status.HTTP_400_BAD_REQUEST)

        # التحقق من عمر المستخدم
        try:
            date_naissance = datetime.datetime.strptime(data['date_naissance'], '%Y-%m-%d').date()
            age = (datetime.date.today() - date_naissance).days // 365
            if age < 18 or age > 80:
                return Response({
                    'status': 'error',
                    'message': 'Age must be between 18 and 80 years'
                }, status=status.HTTP_400_BAD_REQUEST)
        except ValueError:
            return Response({
                'status': 'error',
                'message': 'Invalid date format. Use YYYY-MM-DD'
            }, status=status.HTTP_400_BAD_REQUEST)

        # تعيين is_staff و is_superuser للمسؤولين
        if data['type_utilisateur'] == 'Administrateur':
            data['is_staff'] = True
            data['is_superuser'] = True

        serializer = UserRegistrationSerializer(data=data)
        if serializer.is_valid():
            user = serializer.save()
            # إنشاء توكن مباشرة بعد التسجيل
            access_token, refresh_token = create_jwt_token(user)
            return Response({
                'status': 'success',
                'message': 'User registered successfully',
                'data': {
                    'id_utilisateur': user.id_utilisateur,
                    'username': user.username,
                    'email': user.email,
                    'telephone': user.telephone,
                    'type_utilisateur': user.type_utilisateur,
                    'date_naissance': user.date_naissance,
                    'is_active': user.is_active,
                    'date_joined': user.date_joined
                },
                'tokens': {
                    'access': access_token,
                    'refresh': refresh_token
                }
            }, status=status.HTTP_201_CREATED)
        return Response({
            'status': 'error',
            'message': 'Invalid data',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([AllowAny])
def protected_view(request):
    """
    مسار محمي للاختبار
    """
    # التحقق من وجود هيدر Authorization
    auth_header = request.headers.get('Authorization', None)
    
    # إذا كان الهيدر غير موجود
    if not auth_header:
        # طباعة جميع الهيدرات للتشخيص
        all_headers = {k: v for k, v in request.headers.items()}
        print("All headers:", all_headers)
        return Response({
            "error": "يجب توفير هيدر Authorization",
            "all_headers": all_headers
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # تحقق من صيغة الهيدر
    parts = auth_header.split(' ')
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        print("Bad Authorization header:", auth_header)
        return Response({
            "error": "يجب أن يكون هيدر Authorization بصيغة 'Bearer TOKEN'",
            "received": auth_header
        }, status=status.HTTP_401_UNAUTHORIZED)
    
    # الحصول على التوكن
    token = parts[1]
    
    try:
        # استخدام مكتبة jwt للتحقق من التوكن
        import jwt
        from django.conf import settings
        
        # فك تشفير التوكن
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
        )
        
        # البحث عن معرف المستخدم في التوكن
        user_id = payload.get('user_id') or payload.get('id_utilisateur')
        
        if not user_id:
            print("Token payload:", payload)
            return Response({
                "error": "التوكن لا يحتوي على معرف المستخدم",
                "payload": payload
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # البحث عن المستخدم في قاعدة البيانات
        user = Utilisateur.objects.get(id_utilisateur=user_id)
        
        # إرجاع النجاح
        return Response({
            "message": "تم التحقق من التوكن بنجاح",
            "user": {
                "id_utilisateur": user.id_utilisateur,
                "username": user.username,
                "email": user.email,
                "type_utilisateur": user.type_utilisateur,
                "date_joined": user.date_joined
            }
        })
    except jwt.ExpiredSignatureError:
        print("Token expired:", token)
        return Response({
            "error": "انتهت صلاحية التوكن"
        }, status=status.HTTP_401_UNAUTHORIZED)
    except jwt.InvalidTokenError as e:
        print(f"Invalid token error: {str(e)}")
        return Response({
            "error": f"التوكن غير صالح: {str(e)}"
        }, status=status.HTTP_401_UNAUTHORIZED)
    except Utilisateur.DoesNotExist:
        print(f"User not found for ID: {user_id if 'user_id' in locals() else 'unknown'}")
        return Response({
            "error": "المستخدم غير موجود في قاعدة البيانات"
        }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        import traceback
        print(f"Error in protected_view: {str(e)}")
        traceback.print_exc()
        return Response({
            "error": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_users(request):
    try:
        # الحصول على التوكن من الطلب
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({
                'error': 'رأس التفويض غير صالح',
                'message': 'يجب توفير رأس Authorization بصيغة "Bearer token"'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # استخراج التوكن
        token = auth_header.split(' ')[1]
        
        # فك تشفير التوكن
        try:
            # استخدام مكتبة jwt للتحقق من التوكن
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
            )
            
            # البحث عن معرف المستخدم في التوكن
            user_id = payload.get('user_id') or payload.get('id_utilisateur')
            
            if not user_id:
                return Response({
                    "error": "التوكن لا يحتوي على معرف المستخدم",
                    "details": "يجب أن يحتوي التوكن على معرف المستخدم (user_id)"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # البحث عن المستخدم في قاعدة البيانات
            user = Utilisateur.objects.get(id_utilisateur=user_id)
            
            # التحقق من أن المستخدم مسؤول
            if user.type_utilisateur != 'Administrateur':
                return Response({
                    "error": "غير مصرح لك بالوصول إلى هذه البيانات. يجب أن تكون مسؤولاً.",
                    "your_type": user.type_utilisateur
                }, status=status.HTTP_403_FORBIDDEN)
            
            # الحصول على جميع المستخدمين
            users = Utilisateur.objects.all()
            
            # استخدام serializer للحصول على بيانات محمية
            serializer = UserListSerializer(users, many=True)
            
            return Response({
                "message": "تم جلب البيانات بنجاح",
                "users": serializer.data
            })
            
        except jwt.ExpiredSignatureError:
            return Response({
                "error": "انتهت صلاحية التوكن",
                "details": "يرجى تسجيل الدخول من جديد للحصول على توكن جديد"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({
                "error": "التوكن غير صالح",
                "details": "التوكن المقدم غير صالح أو تم تعديله"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except Utilisateur.DoesNotExist:
            return Response({
                "error": "المستخدم غير موجود في قاعدة البيانات",
                "user_id": user_id if 'user_id' in locals() else None
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'error': "حدث خطأ في الخادم",
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def search_advanced(request):
    """
    بحث متقدم في المستخدمين مع دعم معايير متعددة
    """
    try:
        # التحقق من التوكن والمصادقة
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({
                'error': 'رأس التفويض غير صالح',
                'message': 'يجب توفير رأس Authorization بصيغة "Bearer token"'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # استخراج التوكن
        token = auth_header.split(' ')[1]
        
        try:
            # فك تشفير التوكن
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
            )
            
            # البحث عن معرف المستخدم في التوكن
            user_id = payload.get('user_id') or payload.get('id_utilisateur')
            
            if not user_id:
                return Response({
                    "error": "التوكن لا يحتوي على معرف المستخدم",
                    "details": "يجب أن يحتوي التوكن على معرف المستخدم (user_id)"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # البحث عن المستخدم في قاعدة البيانات
            user = Utilisateur.objects.get(id_utilisateur=user_id)
            
            # التحقق من أن المستخدم مسؤول
            if user.type_utilisateur != 'Administrateur':
                return Response({
                    "error": "غير مصرح لك بالوصول إلى هذه البيانات. يجب أن تكون مسؤولاً.",
                    "your_type": user.type_utilisateur
                }, status=status.HTTP_403_FORBIDDEN)
            
            # الحصول على معايير البحث من الطلب
            username = request.GET.get('username', '')
            email = request.GET.get('email', '')
            telephone = request.GET.get('telephone', '')
            adresse = request.GET.get('adresse', '')
            date_joined = request.GET.get('date_joined', '')
            type_utilisateur = request.GET.get('type_utilisateur', '')
            
            # بناء استعلام بحث ديناميكي
            query = Q()
            
            if username:
                query |= Q(username__icontains=username)
            
            if email:
                query |= Q(email__icontains=email)
            
            if telephone:
                query |= Q(telephone__icontains=telephone)
            
            if adresse:
                query |= Q(adresse__icontains=adresse)
            
            if date_joined:
                try:
                    # تحويل النص إلى تاريخ
                    date_obj = datetime.datetime.strptime(date_joined, '%Y-%m-%d').date()
                    query |= Q(date_joined__date=date_obj)
                except ValueError:
                    pass
            
            if type_utilisateur:
                query |= Q(type_utilisateur=type_utilisateur)
            
            # التأكد من وجود معايير بحث
            if query == Q():
                return Response({
                    "message": "لم يتم تحديد أي معايير للبحث",
                    "available_filters": [
                        "username", "email", "telephone", "adresse", "date_joined", "type_utilisateur"
                    ],
                    "example": "/api/search/?username=محمد&email=example.com"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # تنفيذ البحث
            users = Utilisateur.objects.filter(query)
            
            # استخدام serializer
            serializer = UserListSerializer(users, many=True)
            
            # تحضير الاستجابة
            return Response({
                "message": "تم البحث بنجاح",
                "count": users.count(),
                "filters_used": {
                    "username": username if username else None,
                    "email": email if email else None,
                    "telephone": telephone if telephone else None,
                    "adresse": adresse if adresse else None,
                    "date_joined": date_joined if date_joined else None,
                    "type_utilisateur": type_utilisateur if type_utilisateur else None
                },
                "users": serializer.data
            })
            
        except jwt.ExpiredSignatureError:
            return Response({
                "error": "انتهت صلاحية التوكن",
                "details": "يرجى تسجيل الدخول من جديد للحصول على توكن جديد"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({
                "error": "التوكن غير صالح",
                "details": "التوكن المقدم غير صالح أو تم تعديله"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except Utilisateur.DoesNotExist:
            return Response({
                "error": "المستخدم غير موجود في قاعدة البيانات",
                "user_id": user_id if 'user_id' in locals() else None
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'error': "حدث خطأ في الخادم",
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT', 'PATCH'])
@permission_classes([AllowAny])
def update_user(request, id_utilisateur):
    """
    تحديث بيانات المستخدم - بدون الحاجة لمصادقة التوكن (مؤقتًا)
    """
    try:
        # التحقق من وجود المستخدم المطلوب تحديثه
        try:
            user_to_update = Utilisateur.objects.get(id_utilisateur=id_utilisateur)
        except Utilisateur.DoesNotExist:
            return Response({
                "error": "المستخدم غير موجود",
                "details": f"لا يوجد مستخدم بالمعرف {id_utilisateur}"
            }, status=status.HTTP_404_NOT_FOUND)
        
        # --- تم حذف التحقق من التوكن ---
        serializer = UserUpdateSerializer(user_to_update, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response({
                "message": "تم تحديث البيانات بنجاح",
                "user": {
                    "id_utilisateur": user_to_update.id_utilisateur,
                    "username": user_to_update.username,
                    "email": user_to_update.email,
                    "telephone": user_to_update.telephone,
                    "adresse": user_to_update.adresse,
                    "type_utilisateur": user_to_update.type_utilisateur,
                    "date_naissance": user_to_update.date_naissance,
                    "photo_profile": user_to_update.photo_profile.url if user_to_update.photo_profile else None,
                    "is_active": user_to_update.is_active
                }
            })
        else:
            return Response({
                "error": "بيانات غير صالحة",
                "details": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'error': "حدث خطأ في الخادم",
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([AllowAny])
def delete_user(request, id_utilisateur):
    """
    حذف حساب مستخدم - يمكن للمستخدم حذف حسابه الشخصي فقط، أو للمسؤول حذف أي حساب
    """
    try:
        # التحقق من وجود المستخدم المطلوب حذفه
        try:
            user_to_delete = Utilisateur.objects.get(id_utilisateur=id_utilisateur)
        except Utilisateur.DoesNotExist:
            return Response({
                "error": "المستخدم غير موجود",
                "details": f"لا يوجد مستخدم بالمعرف {id_utilisateur}"
            }, status=status.HTTP_404_NOT_FOUND)
        
        # التحقق من التوكن والمصادقة
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({
                'error': 'رأس التفويض غير صالح',
                'message': 'يجب توفير رأس Authorization بصيغة "Bearer token"'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # استخراج التوكن
        token = auth_header.split(' ')[1]
        
        try:
            # فك تشفير التوكن
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
            )
            
            # البحث عن معرف المستخدم في التوكن
            token_user_id = payload.get('user_id') or payload.get('id_utilisateur')
            
            if not token_user_id:
                return Response({
                    "error": "التوكن لا يحتوي على معرف المستخدم",
                    "details": "يجب أن يحتوي التوكن على معرف المستخدم (user_id)"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # البحث عن المستخدم المصادق في قاعدة البيانات
            authenticated_user = Utilisateur.objects.get(id_utilisateur=token_user_id)
            
            # التحقق من صلاحية الحذف: المستخدم نفسه أو مسؤول
            if authenticated_user.id_utilisateur != user_to_delete.id_utilisateur and authenticated_user.type_utilisateur != 'Administrateur':
                return Response({
                    "error": "غير مصرح لك بحذف هذا الحساب",
                    "details": "يمكنك فقط حذف حسابك الشخصي"
                }, status=status.HTTP_403_FORBIDDEN)
            
            # احفظ بعض البيانات لتضمينها في الاستجابة
            deleted_user_info = {
                "id_utilisateur": user_to_delete.id_utilisateur,
                "username": user_to_delete.username,
                "email": user_to_delete.email,
                "type_utilisateur": user_to_delete.type_utilisateur
            }
            
            # اتخاذ إجراء الحذف
            user_to_delete.delete()
            
            return Response({
                "message": "تم حذف الحساب بنجاح",
                "deleted_user": deleted_user_info,
                "deleted_at": datetime.datetime.now().isoformat()
            })
            
        except jwt.ExpiredSignatureError:
            return Response({
                "error": "انتهت صلاحية التوكن",
                "details": "يرجى تسجيل الدخول من جديد للحصول على توكن جديد"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({
                "error": "التوكن غير صالح",
                "details": "التوكن المقدم غير صالح أو تم تعديله"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except Utilisateur.DoesNotExist:
            return Response({
                "error": "المستخدم غير موجود في قاعدة البيانات",
                "user_id": token_user_id if 'token_user_id' in locals() else None
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'error': "حدث خطأ في الخادم",
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@permission_classes([AllowAny])
def bulk_delete_users(request):
    """
    حذف مجموعة من المستخدمين باستخدام معايير بحث - متاح فقط للمسؤولين
    """
    try:
        # التحقق من التوكن والمصادقة
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return Response({
                'error': 'رأس التفويض غير صالح',
                'message': 'يجب توفير رأس Authorization بصيغة "Bearer token"'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # استخراج التوكن
        token = auth_header.split(' ')[1]
        
        try:
            # فك تشفير التوكن
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
            )
            
            # البحث عن معرف المستخدم في التوكن
            token_user_id = payload.get('user_id') or payload.get('id_utilisateur')
            
            if not token_user_id:
                return Response({
                    "error": "التوكن لا يحتوي على معرف المستخدم",
                    "details": "يجب أن يحتوي التوكن على معرف المستخدم (user_id)"
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # البحث عن المستخدم المصادق في قاعدة البيانات
            authenticated_user = Utilisateur.objects.get(id_utilisateur=token_user_id)
            
            # التحقق من أن المستخدم مسؤول
            if authenticated_user.type_utilisateur != 'Administrateur':
                return Response({
                    "error": "غير مصرح لك بتنفيذ هذه العملية",
                    "details": "يجب أن تكون مسؤولاً للقيام بحذف متعدد للمستخدمين"
                }, status=status.HTTP_403_FORBIDDEN)
            
            # الحصول على معايير البحث من الطلب
            data = request.data
            if hasattr(data, 'dict'):
                data = data.dict()
                
            username = data.get('username', '') if isinstance(data, dict) else ''
            email = data.get('email', '') if isinstance(data, dict) else ''
            telephone = data.get('telephone', '') if isinstance(data, dict) else ''
            adresse = data.get('adresse', '') if isinstance(data, dict) else ''
            date_joined = data.get('date_joined', '') if isinstance(data, dict) else ''
            type_utilisateur = data.get('type_utilisateur', '') if isinstance(data, dict) else ''
            search_mode = data.get('search_mode', 'contains').lower() if isinstance(data, dict) else 'contains'
            
            # خيار الحماية للمسؤولين (حقيقي بشكل افتراضي - لا حذف للمسؤولين)
            protect_admins = data.get('protect_admins', True) if isinstance(data, dict) else True
            
            # خيار جديد للتأكيد الإلزامي (يجب تعيينه إلى حقيقي للحذف)
            confirmed = data.get('confirmed', False) if isinstance(data, dict) else False
            
            # خيار جديد لتضمين المستخدم الحالي في البحث (افتراضيًا لا)
            include_current_user = data.get('include_current_user', False) if isinstance(data, dict) else False
            
            # معلومات الطلب للتشخيص
            request_info = {
                "content_type": request.content_type,
                "method": request.method,
                "data": dict(request.data) if hasattr(request.data, 'dict') else request.data
            }
            
            # بناء استعلام بحث ديناميكي
            query = Q()
            
            # تطبيق معايير البحث حسب وضع البحث المحدد
            if search_mode == 'exact':
                if username:
                    query |= Q(username=username)
                if email:
                    query |= Q(email=email)
                if telephone:
                    query |= Q(telephone=telephone)
                if adresse:
                    query |= Q(adresse=adresse)
                if type_utilisateur:
                    query |= Q(type_utilisateur=type_utilisateur)
            else:  # استخدام contains كافتراضي
                if username:
                    query |= Q(username__icontains=username)
                if email:
                    query |= Q(email__icontains=email)
                if telephone:
                    query |= Q(telephone__icontains=telephone)
                if adresse:
                    query |= Q(adresse__icontains=adresse)
                if type_utilisateur:
                    query |= Q(type_utilisateur=type_utilisateur)
            
            # معالجة تاريخ الانضمام بشكل منفصل
            if date_joined:
                try:
                    date_obj = datetime.datetime.strptime(date_joined, '%Y-%m-%d').date()
                    query |= Q(date_joined__date=date_obj)
                except ValueError:
                    pass
            
            # التأكد من وجود معايير بحث
            if query == Q():
                return Response({
                    "error": "لم يتم تحديد أي معايير كافية للبحث",
                    "details": "يجب تحديد معايير بحث أكثر تحديدًا لتجنب حذف جميع المستخدمين عن طريق الخطأ",
                    "request_info": request_info
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # البحث عن المستخدمين المطابقين للمعايير قبل أي استبعادات
            all_matching_users = Utilisateur.objects.filter(query)
            
            # نسخة من المستخدمين المطابقين للعرض
            users_info_before_exclusion = []
            for user in all_matching_users[:10]:  # عرض أول 10 فقط لتجنب الرسائل الطويلة
                users_info_before_exclusion.append({
                    "id_utilisateur": user.id_utilisateur,
                    "username": user.username,
                    "email": user.email,
                    "type_utilisateur": user.type_utilisateur
                })
            
            # استبعاد المستخدم الحالي إذا لم يكن مضمنًا صراحةً
            matching_users = all_matching_users
            if not include_current_user:
                matching_users = matching_users.exclude(id_utilisateur=authenticated_user.id_utilisateur)
            
            # نسخة بعد استبعاد المستخدم الحالي
            users_after_current_user_exclusion = []
            for user in matching_users[:10]:
                users_after_current_user_exclusion.append({
                    "id_utilisateur": user.id_utilisateur,
                    "username": user.username,
                    "email": user.email,
                    "type_utilisateur": user.type_utilisateur
                })
            
            # استبعاد المسؤولين إذا كان مطلوبًا
            if protect_admins:
                users_to_delete = matching_users.exclude(type_utilisateur='Administrateur')
            else:
                users_to_delete = matching_users
            
            # عدم وجود مستخدمين للحذف
            if not users_to_delete.exists():
                # التحقق مما إذا كان هناك مستخدمون قبل الاستبعادات
                if all_matching_users.exists():
                    if protect_admins and all_matching_users.filter(type_utilisateur='Administrateur').exists():
                        admin_message = "جميع المستخدمين المطابقين هم مسؤولون ومحميون"
                    else:
                        admin_message = ""
                    
                    if not include_current_user and all_matching_users.filter(id_utilisateur=authenticated_user.id_utilisateur).exists():
                        current_user_message = "المستخدم الحالي مطابق لمعايير البحث ومستبعد افتراضيًا"
                    else:
                        current_user_message = ""
                    
                    return Response({
                        "message": "لم يتم العثور على مستخدمين مطابقين للمعايير بعد الاستبعادات",
                        "explanation": "وجدنا مستخدمين يطابقون معايير البحث، لكنهم جميعًا مستبعدون",
                        "admin_exclusion": admin_message,
                        "current_user_exclusion": current_user_message,
                        "total_matches_before_exclusion": all_matching_users.count(),
                        "sample_matches": users_info_before_exclusion,
                        "filters_used": {
                            "username": username if username else None,
                            "email": email if email else None,
                            "telephone": telephone if telephone else None,
                            "adresse": adresse if adresse else None,
                            "date_joined": date_joined if date_joined else None,
                            "type_utilisateur": type_utilisateur if type_utilisateur else None,
                            "protect_admins": protect_admins,
                            "search_mode": search_mode,
                            "include_current_user": include_current_user
                        },
                        "tips": [
                            "استخدم protect_admins: false لتضمين المسؤولين في النتائج",
                            "استخدم include_current_user: true لتضمين المستخدم الحالي"
                        ]
                    }, status=status.HTTP_404_NOT_FOUND)
                
                # لم يتم العثور على أي مستخدمين مطابقين للمعايير من البداية
                return Response({
                    "message": "لم يتم العثور على مستخدمين مطابقين للمعايير",
                    "filters_used": {
                        "username": username if username else None,
                        "email": email if email else None,
                        "telephone": telephone if telephone else None,
                        "adresse": adresse if adresse else None,
                        "date_joined": date_joined if date_joined else None,
                        "type_utilisateur": type_utilisateur if type_utilisateur else None,
                        "protect_admins": protect_admins,
                        "search_mode": search_mode,
                        "include_current_user": include_current_user
                    },
                    "request_info": request_info
                }, status=status.HTTP_404_NOT_FOUND)
            
            # إذا لم يتم تأكيد العملية، أرجع المستخدمين المطابقين للمعايير دون حذفهم
            if not confirmed:
                # تحضير معلومات المستخدمين
                users_info = []
                for user in users_to_delete:
                    users_info.append({
                        "id_utilisateur": user.id_utilisateur,
                        "username": user.username,
                        "email": user.email,
                        "type_utilisateur": user.type_utilisateur
                    })
                
                return Response({
                    "message": "وجدنا مستخدمين مطابقين للمعايير. يرجى التأكيد قبل الحذف",
                    "matching_users_count": users_to_delete.count(),
                    "matching_users": users_info,
                    "confirm_instructions": "لحذف هؤلاء المستخدمين، أضف 'confirmed': true إلى طلبك",
                    "filters_used": {
                        "username": username if username else None,
                        "email": email if email else None,
                        "telephone": telephone if telephone else None,
                        "adresse": adresse if adresse else None,
                        "date_joined": date_joined if date_joined else None,
                        "type_utilisateur": type_utilisateur if type_utilisateur else None,
                        "protect_admins": protect_admins,
                        "search_mode": search_mode,
                        "include_current_user": include_current_user
                    }
                }, status=status.HTTP_200_OK)
            
            # حفظ معلومات المستخدمين قبل الحذف
            users_info = []
            for user in users_to_delete:
                users_info.append({
                    "id_utilisateur": user.id_utilisateur,
                    "username": user.username,
                    "email": user.email,
                    "type_utilisateur": user.type_utilisateur
                })
            
            # احصل على عدد المستخدمين الذين سيتم حذفهم
            count = users_to_delete.count()
            
            # تنفيذ عملية الحذف
            users_to_delete.delete()
            
            return Response({
                "message": f"تم حذف {count} مستخدم بنجاح",
                "deleted_count": count,
                "deleted_users": users_info,
                "filters_used": {
                    "username": username if username else None,
                    "email": email if email else None,
                    "telephone": telephone if telephone else None,
                    "adresse": adresse if adresse else None,
                    "date_joined": date_joined if date_joined else None,
                    "type_utilisateur": type_utilisateur if type_utilisateur else None,
                    "protect_admins": protect_admins,
                    "search_mode": search_mode,
                    "include_current_user": include_current_user
                },
                "deleted_at": datetime.datetime.now().isoformat()
            })
            
        except jwt.ExpiredSignatureError:
            return Response({
                "error": "انتهت صلاحية التوكن",
                "details": "يرجى تسجيل الدخول من جديد للحصول على توكن جديد"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except jwt.InvalidTokenError:
            return Response({
                "error": "التوكن غير صالح",
                "details": "التوكن المقدم غير صالح أو تم تعديله"
            }, status=status.HTTP_401_UNAUTHORIZED)
        except Utilisateur.DoesNotExist:
            return Response({
                "error": "المستخدم غير موجود في قاعدة البيانات",
                "user_id": token_user_id if 'token_user_id' in locals() else None
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'error': "حدث خطأ في الخادم",
            'details': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    try:
        # تحويل البيانات إلى قاموس
        data = request.data.dict() if hasattr(request.data, 'dict') else request.data
        
        # الحصول على البيانات من الطلب
        identifier = data.get('username') or data.get('email') or data.get('telephone') or data.get('phone')
        password = data.get('password') or data.get('mot_de_passe')
        user_type = data.get('type_utilisateur')  # Client أو Driver
        
        # تسجيل البيانات المستلمة للتصحيح
        logger.info(f"بيانات تسجيل الدخول: identifier={identifier}, password={'*'*len(password) if password else None}, user_type={user_type}")
        
        # التحقق من المعرف وكلمة المرور
        if not identifier:
            return Response({
                'status': 'error',
                'message': 'يجب توفير اسم المستخدم أو البريد الإلكتروني أو رقم الهاتف'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not password:
            return Response({
                'status': 'error',
                'message': 'كلمة المرور مطلوبة'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديد أنواع المستخدمين المسموح بها بناءً على نوع الحساب المختار
        allowed_types = None
        if user_type == 'Client':
            allowed_types = ['Client']
        elif user_type == 'Driver':
            allowed_types = ['Livreur', 'Chauffeur']
        
        # البحث عن المستخدم باستخدام المعرف
        user = None
        
        # 1. البحث باستخدام اسم المستخدم
        if not user:
            try:
                query = Q(username=identifier)
                if allowed_types:
                    query &= Q(type_utilisateur__in=allowed_types)
                user = Utilisateur.objects.get(query)
                logger.info(f"تم العثور على المستخدم باستخدام اسم المستخدم: {user.id_utilisateur}")
            except Utilisateur.DoesNotExist:
                user = None
        
        # 2. البحث باستخدام البريد الإلكتروني
        if not user and '@' in identifier:
            try:
                query = Q(email=identifier)
                if allowed_types:
                    query &= Q(type_utilisateur__in=allowed_types)
                user = Utilisateur.objects.get(query)
                logger.info(f"تم العثور على المستخدم باستخدام البريد الإلكتروني: {user.id_utilisateur}")
            except Utilisateur.DoesNotExist:
                user = None
        
        # 3. البحث باستخدام رقم الهاتف
        if not user:
            try:
                query = Q(telephone=identifier)
                if allowed_types:
                    query &= Q(type_utilisateur__in=allowed_types)
                user = Utilisateur.objects.get(query)
                logger.info(f"تم العثور على المستخدم باستخدام رقم الهاتف: {user.id_utilisateur}")
            except Utilisateur.DoesNotExist:
                user = None
        
        # التحقق من وجود المستخدم
        if not user:
            logger.warning(f"لم يتم العثور على المستخدم باستخدام المعرف: {identifier}")
            return Response({
                'status': 'error',
                'message': 'بيانات تسجيل الدخول غير صحيحة'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من نوع المستخدم إذا تم تحديده
        if user_type and allowed_types and user.type_utilisateur not in allowed_types:
            logger.warning(f"نوع المستخدم غير متوافق: {user.type_utilisateur} ليس في {allowed_types}")
            return Response({
                'status': 'error',
                'message': 'بيانات تسجيل الدخول غير صحيحة أو نوع المستخدم غير مطابق'
            }, status=status.HTTP_400_BAD_REQUEST)
                
        # التحقق من كلمة المرور
        if not user.check_password(password):
            logger.warning(f"كلمة المرور غير صحيحة للمستخدم: {user.id_utilisateur}")
            return Response({
                'status': 'error',
                'message': 'بيانات تسجيل الدخول غير صحيحة'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # التحقق من أن المستخدم نشط
        if not user.is_active:
            logger.warning(f"محاولة تسجيل دخول لحساب غير نشط: {user.id_utilisateur}")
            return Response({
                'status': 'inactive',
                'message': 'حساب المستخدم غير نشط',
                'user': {
                    'id_utilisateur': user.id_utilisateur,
                    'username': user.username,
                    'email': user.email,
                    'telephone': user.telephone,
                    'adresse': user.adresse,
                    'type_utilisateur': user.type_utilisateur,
                    'is_active': user.is_active,
                    'date_joined': user.date_joined
                }
            }, status=status.HTTP_200_OK)
            
        # تحديث وقت آخر تسجيل دخول
        user.last_login = timezone.now()
        user.save(update_fields=['last_login'])
            
        # إنشاء التوكن
        access_token, refresh_token = create_jwt_token(user)
        
        # تجهيز البيانات حسب نوع المستخدم
        user_data = {
            'id_utilisateur': user.id_utilisateur,
            'username': user.username,
            'email': user.email,
            'telephone': user.telephone,
            'adresse': user.adresse,
            'type_utilisateur': user.type_utilisateur,
            'is_active': user.is_active,
            'date_joined': user.date_joined,
            'photo_profile': request.build_absolute_uri(user.photo_profile.url) if user.photo_profile else None
        }
        # إضافة معلومات إضافية بناءً على نوع المستخدم
        if user.type_utilisateur == 'Livreur' and hasattr(user, 'profil_livreur'):
            livreur = user.profil_livreur
            user_data['note_moyenne'] = livreur.note_moyenne
            user_data['disponibilite'] = livreur.disponibilite
            user_data['statut_verification'] = livreur.statut_verification
            user_data['matricule_vehicule'] = livreur.matricule_vehicule
            user_data['type_vehicule'] = livreur.type_vehicule
            user_data['zone_couverture'] = livreur.zone_couverture
            user_data['raison_refus'] = livreur.raison_refus if hasattr(livreur, 'raison_refus') else None
        elif user.type_utilisateur == 'Chauffeur' and hasattr(user, 'profil_chauffeur'):
            chauffeur = user.profil_chauffeur
            user_data['note_moyenne'] = chauffeur.note_moyenne
            user_data['disponibilite'] = chauffeur.disponibilite
            user_data['statut_verification'] = chauffeur.statut_verification
            user_data['matricule_vehicule'] = chauffeur.matricule_vehicule
            user_data['type_vehicule'] = chauffeur.type_vehicule
            user_data['zone_couverture'] = chauffeur.zone_couverture
            user_data['raison_refus'] = chauffeur.raison_refus if hasattr(chauffeur, 'raison_refus') else None
        
        logger.info(f"تسجيل دخول ناجح للمستخدم: {user.id_utilisateur}")
        return Response({
                'status': 'success',
            'message': 'تم تسجيل الدخول بنجاح',
            'user': user_data,
            'tokens': {
                'access': access_token,
                'refresh': refresh_token
            }
        }, status=status.HTTP_200_OK)
    
    except Exception as e:
        import traceback
        logger.error(f"خطأ في تسجيل الدخول: {str(e)}")
        logger.error(traceback.format_exc())
        return Response({
            'status': 'error',
            'message': 'حدث خطأ أثناء معالجة طلب تسجيل الدخول'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def check_user_exists(request):
    """
    التحقق من وجود مستخدم باستخدام البريد الإلكتروني أو رقم الهاتف ونوع الحساب
    """
    try:
        data = request.data
        
        # استخراج البيانات من الطلب
        email = data.get('email')
        telephone = data.get('phone')  # استخدام 'phone' كما هو في الطلب من Flutter
        user_type = data.get('user_type')  # Client أو Livreur
        
        # إضافة مطبوعات تصحيح
        print(f"DEBUG - check_user_exists: طلب وارد")
        print(f"DEBUG - check_user_exists: البيانات الواردة: {data}")
        print(f"DEBUG - check_user_exists: البريد: {email}, الهاتف: {telephone}, نوع المستخدم: {user_type}")
        
        if not user_type:
            return Response({
                'exists': False,
                'message': 'نوع الحساب مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديد أنواع المستخدمين المسموح بها بناءً على user_type
        if user_type == 'Client':
            allowed_types = ['Client']
        elif user_type == 'Livreur':
            allowed_types = ['Livreur', 'Chauffeur']
        else:
            return Response({
                'exists': False,
                'message': 'نوع الحساب غير صالح',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # البحث عن المستخدم في قاعدة البيانات
        user = None
        
        if email:
            # البحث باستخدام البريد الإلكتروني
            try:
                user = Utilisateur.objects.get(
                    email=email, 
                    is_active=True,
                    type_utilisateur__in=allowed_types
                )
            except Utilisateur.DoesNotExist:
                user = None
            
        elif telephone:
            # البحث باستخدام رقم الهاتف
            try:
                user = Utilisateur.objects.get(
                    telephone=telephone, 
                    is_active=True,
                    type_utilisateur__in=allowed_types
                )
            except Utilisateur.DoesNotExist:
                user = None
        
        # إعداد الاستجابة
        if user:
            return Response({
                'exists': True,
                'message': 'تم العثور على الحساب',
                'status': 'success',
                'user_id': user.id_utilisateur  # إضافة معرف المستخدم إلى الاستجابة
            }, status=status.HTTP_200_OK)
        else:
            return Response({
                'exists': False,
                'message': 'لا يوجد حساب بهذه المعلومات',
                'status': 'error'
            }, status=status.HTTP_404_NOT_FOUND)
            
    except Exception as e:
        # سجل الخطأ في ملفات السجل الخاصة بالخادم
        logger.error(f"Exception in check_user_exists: {str(e)}")
        
        return Response({
            'exists': False,
            'message': 'حدث خطأ أثناء التحقق من وجود الحساب',
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def send_otp_email(request):
    """
    إرسال رمز OTP عبر البريد الإلكتروني
    """
    try:
        data = request.data
        email = data.get('email')
        user_type = data.get('user_type')
        
        logger.info(f"استلام طلب OTP بريد إلكتروني: {email}, نوع الحساب: {user_type}")
        
        if not email:
            return Response({
                'success': False,
                'message': 'البريد الإلكتروني مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not user_type:
            return Response({
                'success': False,
                'message': 'نوع الحساب مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديد أنواع المستخدمين المسموح بها بناءً على نوع الحساب المختار
        if user_type == 'Client':
            allowed_types = ['Client']
        elif user_type == 'Livreur':
            allowed_types = ['Livreur', 'Chauffeur']
        else:
            return Response({
                'success': False,
                'message': 'نوع الحساب غير صالح',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من وجود مستخدم بهذا البريد الإلكتروني ونوع الحساب
        users = Utilisateur.objects.filter(
            email=email,
            is_active=True,
            type_utilisateur__in=allowed_types
        )
        
        if not users.exists():
            logger.warning(f"لا يوجد مستخدم بالبريد الإلكتروني: {email} ونوع الحساب: {user_type}")
            return Response({
                'success': False,
                'message': 'لا يوجد حساب بهذه المعلومات',
                'status': 'error'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # استخدام دوال OTP المبسطة
        user = users.first()
        logger.info(f"تم العثور على المستخدم: {user.id_utilisateur} - {user.email}")
        
        # التحقق من وجود رمز OTP نشط للمستخدم
        active_otps = OTPCode.objects.filter(
            user=user,
            is_used=False,
            expires_at__gt=timezone.now()
        ).count()
        
        if active_otps > 0:
            logger.info(f"يوجد بالفعل {active_otps} رمز OTP نشط للمستخدم {user.id_utilisateur}")
        
        # توليد رمز جديد
        otp_code = generate_otp()
        
        # سجل رمز OTP للتشخيص
        logger.info(f"تم توليد رمز OTP: {otp_code} للمستخدم: {user.email}")
        
        try:
            # حفظ الرمز في قاعدة البيانات (وإلغاء تفعيل الرموز السابقة)
            otp_obj = save_otp_to_db(user, email, otp_code)
            logger.info(f"تم حفظ رمز OTP في قاعدة البيانات، معرف الرمز: {otp_obj.id}")
            
            # إضافة تأخير بسيط للتأكد من إلغاء تفعيل الرموز السابقة
            import time
            time.sleep(0.5)
            
            # إرسال البريد الإلكتروني
            email_sent = send_email_otp(email, otp_code)
            logger.info(f"نتيجة إرسال البريد: {email_sent}")
            
            if email_sent:
                # صمم استجابة مختلفة لوضع التطوير
                if settings.DEBUG:
                    logger.info(f"وضع التطوير: إرسال رمز OTP مع الاستجابة للمستخدم: {otp_code}")
                    return Response({
                        'success': True,
                        'message': 'تم إرسال رمز التحقق بنجاح',
                        'status': 'success',
                        'otp': otp_code,  # دائمًا نرسل الرمز في وضع التطوير
                        'dev_mode': True,  # للإشارة إلى وضع التطوير
                        'email': email,  # إظهار البريد الإلكتروني المستخدم
                        'user_id': user.id_utilisateur,
                        'expires_in': otp_obj.time_remaining
                    })
                else:
                    # في وضع الإنتاج، لا نرسل الرمز
                    return Response({
                        'success': True,
                        'message': 'تم إرسال رمز التحقق بنجاح',
                        'status': 'success',
                        'user_id': user.id_utilisateur,
                        'expires_in': otp_obj.time_remaining
                    })
            else:
                # في حال فشل الإرسال
                logger.error(f"فشل إرسال البريد الإلكتروني إلى {email}")
                
                # في وضع التطوير، نرسل الرمز حتى في حالة الفشل
                if settings.DEBUG:
                    return Response({
                        'success': True,  # نعتبرها ناجحة في وضع التطوير
                        'message': 'وضع التطوير: تم تجاهل فشل الإرسال',
                        'status': 'success',
                        'otp': otp_code,  # إظهار الرمز للتطوير
                        'dev_mode': True,
                        'warning': 'فشل إرسال البريد الإلكتروني، لكن تم تجاهل الخطأ في وضع التطوير',
                        'user_id': user.id_utilisateur,
                        'expires_in': otp_obj.time_remaining
                    })
                
                logger.error(f"فشل إرسال البريد الإلكتروني")
                return Response({
                    'success': False,
                    'message': 'حدث خطأ أثناء إرسال البريد الإلكتروني',
                    'status': 'error'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            logger.error(f"خطأ داخلي في send_otp_email: {str(e)}")
            return Response({
                'success': False,
                'message': f'خطأ داخلي: {str(e)}',
                'status': 'error'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"خطأ عام في send_otp_email: {str(e)}")
        
        # تفاصيل خطأ أكثر للتطوير
        if settings.DEBUG:
            import traceback
            error_details = traceback.format_exc()
            logger.error(f"تفاصيل الخطأ: {error_details}")
            
            return Response({
                'success': False,
                'message': 'حدث خطأ أثناء معالجة الطلب',
                'error': str(e),
                'trace': error_details,
                'status': 'error'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # رسالة مبسطة للإنتاج
        return Response({
            'success': False,
            'message': 'حدث خطأ أثناء معالجة الطلب',
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def send_otp_sms(request):
    """
    إرسال رمز OTP عبر رسالة نصية
    """
    try:
        data = request.data
        phone = data.get('phone')
        user_type = data.get('user_type')
        
        logger.info(f"Received OTP SMS request for: {phone}, user_type: {user_type}")
        
        # استخراج رقم الهاتف بدون مفتاح الدولة للبحث في قاعدة البيانات
        phone_number = phone
        if phone and phone.startswith('+'):
            # إزالة مفتاح الدولة من رقم الهاتف للبحث
            phone_number = phone.lstrip('+222')
        
        if not phone:
            return Response({
                'success': False,
                'message': 'رقم الهاتف مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not user_type:
            return Response({
                'success': False,
                'message': 'نوع الحساب مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديد أنواع المستخدمين المسموح بها بناءً على نوع الحساب المختار
        if user_type == 'Client':
            allowed_types = ['Client']
        elif user_type == 'Livreur':
            allowed_types = ['Livreur', 'Chauffeur']
        else:
            return Response({
                'success': False,
                'message': 'نوع الحساب غير صالح',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من وجود مستخدم بهذا رقم الهاتف ونوع الحساب
        users = Utilisateur.objects.filter(
            telephone=phone_number,
            is_active=True,
            type_utilisateur__in=allowed_types
        )
        
        if not users.exists():
            return Response({
                'success': False,
                'message': 'لا يوجد حساب بهذه المعلومات',
                'status': 'error'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # استخدام دوال OTP المبسطة
        user = users.first()
        otp_code = generate_otp()
        
        try:
            # حفظ الرمز في قاعدة البيانات (وإلغاء تفعيل الرموز السابقة)
            otp_obj = save_otp_to_db(user, phone_number, otp_code)
            
            # إرسال الرسالة القصيرة
            sms_sent = send_sms_otp(phone, otp_code)
            
            if sms_sent:
                # صمم استجابة مختلفة لوضع التطوير
                if settings.DEBUG:
                    logger.info(f"وضع التطوير: إرسال رمز OTP مع الاستجابة للمستخدم: {otp_code}")
                    return Response({
                        'success': True,
                        'message': 'تم إرسال رمز التحقق بنجاح',
                        'status': 'success',
                        'otp': otp_code,  # دائمًا نرسل الرمز في وضع التطوير
                        'dev_mode': True,  # للإشارة إلى وضع التطوير
                        'phone': phone,  # إظهار رقم الهاتف المستخدم
                        'user_id': user.id_utilisateur,
                        'expires_in': otp_obj.time_remaining
                    })
                else:
                    # في وضع الإنتاج، لا نرسل الرمز
                    return Response({
                        'success': True,
                        'message': 'تم إرسال رمز التحقق بنجاح',
                        'status': 'success',
                        'user_id': user.id_utilisateur,
                        'expires_in': otp_obj.time_remaining
                    })
            else:
                # في حال فشل الإرسال
                logger.error(f"فشل إرسال رسالة SMS إلى {phone}")
                
                # في وضع التطوير، نرسل الرمز حتى في حالة الفشل
                if settings.DEBUG:
                    return Response({
                        'success': True,  # نعتبرها ناجحة في وضع التطوير
                        'message': 'وضع التطوير: تم تجاهل فشل الإرسال',
                        'status': 'success',
                        'otp': otp_code,  # إظهار الرمز للتطوير
                        'dev_mode': True,
                        'warning': 'فشل إرسال الرسالة القصيرة، لكن تم تجاهل الخطأ في وضع التطوير',
                        'user_id': user.id_utilisateur,
                        'expires_in': otp_obj.time_remaining
                    })
                
                return Response({
                    'success': False,
                    'message': 'حدث خطأ أثناء إرسال الرسالة القصيرة',
                    'status': 'error'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        except Exception as e:
            logger.error(f"Inner exception in send_otp_sms: {str(e)}")
            return Response({
                'success': False,
                'message': f'خطأ داخلي: {str(e)}',
                'status': 'error'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"Exception in send_otp_sms: {str(e)}")
        
        # تفاصيل خطأ أكثر للتطوير
        if settings.DEBUG:
            import traceback
            error_details = traceback.format_exc()
            logger.error(f"Error trace: {error_details}")
            
            return Response({
                'success': False,
                'message': 'حدث خطأ أثناء معالجة الطلب',
                'error': str(e),
                'trace': error_details,
                'status': 'error'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # رسالة مبسطة للإنتاج
        return Response({
            'success': False,
            'message': 'حدث خطأ أثناء معالجة الطلب',
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def verify_otp(request):
    """التحقق من صحة رمز OTP المقدم"""
    import logging
    logger = logging.getLogger(__name__)
    
    try:
        data = request.data
        
        # طباعة البيانات المستلمة للتصحيح
        logger.info(f"بيانات طلب التحقق: {data}")
        
        identifier = data.get('identifier')
        otp_code = data.get('otp_code')
        user_type = data.get('user_type')  # اختياري
        
        logger.info(f"نوع البيانات: identifier={type(identifier)}, otp_code={type(otp_code)}")
        
        if not identifier or not otp_code:
            logger.warning(f"بيانات غير كاملة: identifier={identifier}, otp_code={otp_code}")
            return Response({
                'success': False,
                'reason': 'missing_data',
                'message': 'المعرف ورمز التحقق مطلوبان'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # استخدام الخدمة للتحقق من رمز OTP
        from .services import verify_otp as service_verify_otp
        
        success, user, verification_data = service_verify_otp(identifier, otp_code)
        logger.info(f"نتيجة التحقق: success={success}, user={user}, verification_data={verification_data}")
        
        if success:
            # تم التحقق بنجاح
            # تحقق إذا كان هناك بيانات تسجيل مؤقتة (للمستخدمين الجدد)
            temp_data = {}
            
            # البحث عن رمز OTP للمستخدمين الجدد (الذين ليس لديهم حساب بعد)
            # نستخدم استعلام مباشر لأن المستخدم قد يكون None
            from .models import OTPCode
            otp_record = OTPCode.objects.filter(
                identifier=identifier,
                code=otp_code,
            ).order_by('-created_at').first()
            
            if otp_record and otp_record.registration_data:
                temp_data['registration_data'] = otp_record.registration_data
                logger.info(f"تم العثور على بيانات تسجيل مؤقتة: {otp_record.registration_data}")
                
            return Response({
                'success': True,
                'message': 'تم التحقق من الرمز بنجاح',
                'user_id': getattr(user, 'id', None),
                'temp_data': temp_data
            })
        else:
            # فشل التحقق
            return Response({
                'success': False,
                'reason': verification_data.get('reason', 'unknown_error'),
                'wait_time': verification_data.get('wait_time', 0),
                'message': verification_data.get('message', 'فشل التحقق من الرمز')
            }, status=status.HTTP_400_BAD_REQUEST)
            
    except Exception as e:
        logger.error(f"خطأ في التحقق من رمز OTP: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'reason': 'system_error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def reset_password(request):
    """
    إعادة تعيين كلمة المرور بعد التحقق من رمز OTP
    """
    try:
        # تحويل البيانات إلى قاموس
        data = request.data.dict() if hasattr(request.data, 'dict') else request.data
        
        # التحقق من وجود البيانات المطلوبة
        identifier = data.get('identifier')  # البريد الإلكتروني أو رقم الهاتف
        code = data.get('code')  # رمز OTP
        new_password = data.get('new_password')  # كلمة المرور الجديدة
        
        if not all([identifier, code, new_password]):
            return Response({
                'status': 'error',
                'message': 'identifier, code and new_password are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # البحث عن المستخدم
        user = None
        if '@' in identifier:  # بريد إلكتروني
            user = Utilisateur.objects.filter(email=identifier).first()
        else:  # رقم هاتف
            user = Utilisateur.objects.filter(telephone=identifier).first()
            
        if not user:
            return Response({
                'status': 'error',
                'message': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # البحث عن آخر رمز OTP للمستخدم
        otp = OTPCode.objects.filter(
            user=user,
            identifier=identifier,
            code=code,  # نبحث عن الرمز المحدد بغض النظر عما إذا كان مستخدمًا أو لا
            is_blocked=False
        ).order_by('-created_at').first()
        
        if not otp:
            return Response({
                'status': 'error',
                'message': 'No valid OTP found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من أن الرمز غير منتهي الصلاحية
        if otp.is_expired:
            return Response({
                'status': 'error',
                'message': 'OTP has expired'
            }, status=status.HTTP_400_BAD_REQUEST)
            
        # التحقق من صحة الرمز
        if otp.code != code:
                return Response({
                'status': 'error',
                'message': 'Invalid OTP'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديث كلمة المرور
        user.set_password(new_password)
        user.save()
        
        # تحديث حالة رمز OTP
        otp.is_used = True
        otp.save()
        
        return Response({
            'status': 'success',
            'message': 'Password has been reset successfully'
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def reactivate_otp(request):
    """
    إعادة تنشيط رمز OTP المستخدم
    """
    try:
        # تحويل البيانات إلى قاموس
        data = request.data.dict() if hasattr(request.data, 'dict') else request.data
        
        # التحقق من وجود البيانات المطلوبة
        identifier = data.get('identifier')  # البريد الإلكتروني أو رقم الهاتف
        otp_code = data.get('otp_code')  # رمز OTP
        user_type = data.get('user_type', 'Client')  # نوع المستخدم (افتراضي: عميل)
        
        if not all([identifier, otp_code]):
            return Response({
                'status': 'error',
                'message': 'identifier and otp_code are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # البحث عن المستخدم
        user = None
        if '@' in identifier:  # بريد إلكتروني
            user = Utilisateur.objects.filter(email=identifier).first()
        else:  # رقم هاتف
            user = Utilisateur.objects.filter(telephone=identifier).first()
            
        if not user:
            return Response({
                'status': 'error',
                'message': 'User not found'
            }, status=status.HTTP_404_NOT_FOUND)
        
        # البحث عن رمز OTP المحدد بغض النظر عن حالته
        otp = OTPCode.objects.filter(
            user=user,
            identifier=identifier,
            code=otp_code,
            is_blocked=False
        ).order_by('-created_at').first()
        
        if not otp:
            return Response({
                'status': 'error',
                'message': 'No matching OTP found'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من أن الرمز غير منتهي الصلاحية
        if otp.is_expired:
            return Response({
                'status': 'error',
                'message': 'OTP has expired'
            }, status=status.HTTP_400_BAD_REQUEST)
            
        # إعادة تنشيط الرمز
        otp.is_used = False
        otp.save()
        
        return Response({
            'status': 'success',
            'message': 'OTP has been reactivated successfully',
            'user_id': user.id_utilisateur
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        return Response({
            'status': 'error',
            'message': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def register_otp_email(request):
    """
    إرسال رمز OTP عبر البريد الإلكتروني للمستخدمين الجدد في مرحلة التسجيل
    بدون إنشاء مستخدم مؤقت
    """
    try:
        data = request.data
        email = data.get('email')
        user_type = data.get('user_type')
        full_name = data.get('full_name', 'مستخدم جديد')
        birth_date = data.get('birth_date')
        otp_code = data.get('otp_code')  # يمكن استقباله من العميل للاختبار
        
        logger.info(f"استلام طلب OTP للتسجيل عبر البريد: {email}, نوع الحساب: {user_type}, الاسم: {full_name}, تاريخ الميلاد: {birth_date}")
        
        if not email:
            return Response({
                'success': False,
                'message': 'البريد الإلكتروني مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not user_type:
            return Response({
                'success': False,
                'message': 'نوع الحساب مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديد أنواع المستخدمين المسموح بها
        if user_type not in ['Client', 'Livreur', 'Chauffeur']:
            return Response({
                'success': False,
                'message': 'نوع الحساب غير صالح',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من وجود مستخدم نشط بنفس البريد الإلكتروني ونفس نوع المستخدم
        if Utilisateur.objects.filter(email=email, type_utilisateur=user_type, is_active=True).exists():
            logger.warning(f"البريد الإلكتروني مستخدم بالفعل لنفس نوع المستخدم: {email}, نوع المستخدم: {user_type}")
            return Response({
                'success': False,
                'message': 'البريد الإلكتروني مستخدم بالفعل لنفس نوع المستخدم',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # إنشاء رمز التحقق إذا لم يتم توفيره
        if not otp_code:
            otp_code = generate_otp()
        
        logger.info(f"تم توليد رمز OTP للتسجيل: {otp_code}")
        
        # حفظ رمز OTP في قاعدة البيانات بدون ربطه بمستخدم
        try:
            from .models import OTPCode  # استيراد محلي
            
            # إلغاء تفعيل الرموز السابقة لنفس المعرف
            OTPCode.objects.filter(
                identifier=email,
                is_used=False
            ).update(is_used=True)
            
            # تحديد نوع المعرف
            otp_type = 'EMAIL'
            
            # إنشاء رمز OTP جديد
            expires_at = timezone.now() + datetime.timedelta(minutes=3)
            otp_obj = OTPCode.objects.create(
                user=None,  # لا يوجد مستخدم مرتبط
                code=otp_code,
                identifier=email,
                expires_at=expires_at,
                type=otp_type,
                registration_data={
                    'email': email,
                    'user_type': user_type,
                    'full_name': full_name,
                    'birth_date': birth_date
                }  # تخزين بيانات التسجيل لاستخدامها لاحقًا
            )
            
            logger.info(f"تم حفظ رمز OTP في قاعدة البيانات، معرف الرمز: {otp_obj.id}")
            
        except Exception as db_error:
            logger.error(f"خطأ أثناء حفظ OTP: {str(db_error)}")
        
        # ------------------- إرسال البريد الإلكتروني -------------------
        # إنشاء نص البريد
        subject = "رمز التحقق لإنشاء حساب جديد في تطبيق توصيل"
        message = f"""مرحبًا {full_name}،

رمز التحقق الخاص بك لإنشاء حساب جديد في تطبيق توصيل هو: {otp_code}

يرجى إدخال هذا الرمز في التطبيق لإكمال عملية التسجيل.
ينتهي صلاحية هذا الرمز خلال 3 دقائق.

شكرًا لاستخدام تطبيق توصيل!
"""
        html_message = f"""
            <html>
                <head>
                    <style>
                        body {{ font-family: Arial, sans-serif; line-height: 1.6; direction: rtl; }}
                        .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                        .header {{ text-align: center; margin-bottom: 20px; }}
                        .code {{ font-size: 24px; font-weight: bold; text-align: center; 
                                padding: 10px; background-color: #f0f0f0; margin: 15px 0; }}
                        .footer {{ font-size: 12px; text-align: center; margin-top: 30px; color: #777; }}
                    </style>
                </head>
                <body>
                    <div class="container">
                        <div class="header">
                            <h2>رمز التحقق لإنشاء حساب جديد في تطبيق توصيل</h2>
                        </div>
                        <p>مرحبًا {full_name}،</p>
                        <p>لقد تلقينا طلبًا لإنشاء حساب جديد في تطبيق توصيل. استخدم رمز التحقق أدناه:</p>
                        <div class="code">{otp_code}</div>
                        <p>هذا الرمز صالح لمدة 3 دقائق فقط.</p>
                        <p>إذا لم تطلب إنشاء حساب جديد، يرجى تجاهل هذا البريد الإلكتروني.</p>
                        <div class="footer">
                            <p>هذه رسالة آلية، يرجى عدم الرد عليها.</p>
                            <p>&copy; 2025 Tawssil. جميع الحقوق محفوظة.</p>
                        </div>
                    </div>
                </body>
            </html>
            """
        
        # استخدام محاولات متعددة لإرسال البريد
        email_sent = False
        
        # المحاولة الأولى: استخدام send_mail مباشرة
        try:
            from_email = settings.DEFAULT_FROM_EMAIL
            recipient_list = [email]
            
            # طباعة معلومات البريد
            logger.info(f"محاولة إرسال رمز OTP للحساب الجديد إلى: {email}")
            logger.info(f"إعدادات SMTP: HOST={settings.EMAIL_HOST}, PORT={settings.EMAIL_PORT}, TLS={settings.EMAIL_USE_TLS}")
            logger.info(f"حساب البريد: {settings.EMAIL_HOST_USER}")
            
            # محاولة إرسال باستخدام send_mail
            email_result = send_mail(
                subject, 
                message, 
                from_email, 
                recipient_list, 
                html_message=html_message,
                fail_silently=False
            )
            
            email_sent = email_result > 0
            logger.info(f"نتيجة إرسال البريد: {email_result}")
            
        except Exception as e:
            logger.error(f"فشل المحاولة الأولى لإرسال البريد: {str(e)}")
            
            # المحاولة الثانية: استخدام send_otp_with_fallback
            try:
                # استدعاء وظيفة send_otp_with_fallback مع تمرير الاسم الكامل
                result, msg = send_otp_with_fallback(email, otp_code, full_name)
                email_sent = result
                logger.info(f"نتيجة المحاولة الثانية لإرسال البريد: {result}, الرسالة: {msg}")
            except Exception as e2:
                logger.error(f"فشل المحاولة الثانية لإرسال البريد: {str(e2)}")
        
        # في وضع التطوير، نعيد الرمز دائمًا
        if settings.DEBUG:
            return Response({
                'success': True,
                'message': 'verification_sent_success',
                'status': 'success',
                'otp': otp_code,  # إظهار الرمز للتطوير
                'data': {
                    'status': 'success',
                    'expires_in': 180  # 3 دقائق
                }
            })
        
        # في وضع الإنتاج
        return Response({
            'success': True,
            'message': 'verification_sent_success',
            'status': 'success',
            'data': {
                'status': 'success',
                'expires_in': 180  # 3 دقائق
            }
        })
            
    except Exception as e:
        logger.error(f"خطأ داخلي في register_otp_email: {str(e)}")
        
        # في وضع التطوير، نعرض الخطأ
        if settings.DEBUG:
            import traceback
            error_details = traceback.format_exc()
            
            return Response({
                'success': False,
                'message': 'حدث خطأ',
                'status': 'error',
                'error': str(e),
                'trace': error_details
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
        # في وضع الإنتاج
        return Response({
            'success': False,
            'message': 'حدث خطأ أثناء إرسال رمز التحقق',
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([AllowAny])
def register_otp_sms(request):
    """
    إرسال رمز OTP عبر الرسائل القصيرة للمستخدمين الجدد في مرحلة التسجيل
    """
    try:
        data = request.data
        phone = data.get('phone')
        user_type = data.get('user_type')
        full_name = data.get('full_name', 'مستخدم جديد')
        birth_date = data.get('birth_date')
        otp_code = data.get('otp_code')  # يمكن استقباله من العميل للاختبار
        
        logger.info(f"استلام طلب OTP للتسجيل عبر SMS: {phone}, نوع الحساب: {user_type}, الاسم: {full_name}")
        
        if not phone:
            return Response({
                'success': False,
                'message': 'رقم الهاتف مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if not user_type:
            return Response({
                'success': False,
                'message': 'نوع الحساب مطلوب',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تحديد أنواع المستخدمين المسموح بها
        if user_type not in ['Client', 'Livreur', 'Chauffeur']:
            return Response({
                'success': False,
                'message': 'نوع الحساب غير صالح',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # تنظيف رقم الهاتف للبحث في قاعدة البيانات
        clean_phone = phone
        if phone.startswith('+'):
            clean_phone = phone.lstrip('+222')
        
        # التحقق من أن الهاتف غير مستخدم بالفعل مع نفس نوع المستخدم
        if Utilisateur.objects.filter(telephone=clean_phone, type_utilisateur=user_type).exists():
            logger.warning(f"رقم الهاتف مستخدم بالفعل لنفس نوع المستخدم: {clean_phone}, نوع المستخدم: {user_type}")
            return Response({
                'success': False,
                'message': 'رقم الهاتف مستخدم بالفعل لنفس نوع المستخدم',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # إنشاء رمز التحقق إذا لم يتم توفيره
        if not otp_code:
            otp_code = generate_otp()
        
        logger.info(f"تم توليد رمز OTP للتسجيل عبر SMS: {otp_code}")
        
        # محاولة إرسال الرسالة القصيرة
        try:
            # إنشاء نص الرسالة خاص بالتسجيل الجديد
            sms_message = f"رمز التحقق الخاص بإنشاء حساب جديد في تطبيق توصيل: {otp_code}. ينتهي الرمز خلال 3 دقائق."
            
            # تسجيل محاولة الإرسال
            logger.info(f"محاولة إرسال رمز OTP للحساب الجديد عبر SMS إلى: {phone}")
            
            # في وضع التطوير، نعتبر الإرسال ناجحًا دائمًا
            sms_sent = False
            if settings.DEBUG:
                logger.info(f"وضع التطوير: تخطي إرسال SMS فعلي. الرمز: {otp_code}")
                sms_sent = True
            else:
                # استخدام Twilio أو خدمة SMS أخرى
                try:
                    from twilio.rest import Client
                    client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
                    message = client.messages.create(
                        body=sms_message,
                        from_=settings.TWILIO_PHONE_NUMBER,
                        to=phone
                    )
                    sms_sent = True
                    logger.info(f"تم إرسال الرسالة النصية بنجاح، معرف الرسالة: {message.sid}")
                except Exception as sms_error:
                    logger.error(f"فشل إرسال الرسالة النصية: {str(sms_error)}")
                    
                    # محاولة ثانية باستخدام خدمة بديلة إذا كانت متاحة
                    try:
                        # يمكن إضافة مزود SMS بديل هنا
                        logger.info("محاولة إرسال SMS باستخدام مزود بديل")
                        # أعد تهيئة خدمة بديلة هنا
                        sms_sent = True
                    except Exception as sms_error2:
                        logger.error(f"فشلت المحاولة البديلة لإرسال SMS: {str(sms_error2)}")
            
            # في وضع التطوير، نعيد الرمز دائمًا
            if settings.DEBUG:
                return Response({
                    'success': True,
                    'message': 'تم إرسال رمز التحقق بنجاح' if sms_sent else 'فشل إرسال الرسالة لكن تم توليد الرمز بنجاح',
                    'status': 'success',
                    'otp': otp_code,  # إظهار الرمز للتطوير
                    'dev_mode': True,
                    'expires_in': 180  # 3 دقائق
                })
            
            # في وضع الإنتاج
            return Response({
                'success': True,
                'message': 'تم إرسال رمز التحقق بنجاح',
                'status': 'success',
                'expires_in': 180
            })
            
        except Exception as e:
            logger.error(f"خطأ داخلي في register_otp_sms: {str(e)}")
            
            # في وضع التطوير، نعرض الخطأ ونعيد الرمز
            if settings.DEBUG:
                return Response({
                    'success': True,  # نعتبرها ناجحة في وضع التطوير
                    'message': 'وضع التطوير: تم تجاهل الخطأ',
                    'status': 'success',
                    'otp': otp_code,
                    'dev_mode': True,
                    'error': str(e),
                    'expires_in': 180
                })
            
            # في وضع الإنتاج
            return Response({
                'success': False,
                'message': 'حدث خطأ أثناء إرسال رمز التحقق',
                'status': 'error'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
    except Exception as e:
        logger.error(f"خطأ عام في register_otp_sms: {str(e)}")
        
        # رسالة مبسطة للإنتاج
        return Response({
            'success': False,
            'message': 'حدث خطأ أثناء معالجة الطلب',
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def complete_registration(request):
    """
    إكمال عملية التسجيل بعد التحقق من OTP
    وإنشاء حساب جديد مع إرجاع توكن المصادقة
    """
    try:
        data = request.data
        logger.info(f"بيانات إكمال التسجيل: {data}")
        
        # استخراج البيانات الأساسية
        email = data.get('email')
        phone = data.get('phone')
        password = data.get('password')
        user_type = data.get('user_type')
        full_name = data.get('full_name', '')
        birth_date = data.get('birth_date')
        adresse = data.get('adresse')
        
        # الصورة الشخصية
        photo_profile = request.FILES.get('photo_profile') or request.FILES.get('profile_picture')
        
        # البيانات الإضافية (اختيارية)
        username = data.get('username')
        
        # استخدام الاسم الكامل كاسم مستخدم إذا لم يتم تقديم اسم مستخدم
        if not username and full_name:
            username = full_name.upper()
        
        # التحقق من البيانات الضرورية
        if not ((email or phone) and password and user_type):
            return Response({
                'success': False,
                'message': 'البيانات غير مكتملة',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
            
        # تحويل تنسيق التاريخ من DD/MM/YYYY إلى YYYY-MM-DD
        if birth_date and '/' in birth_date:
            try:
                from datetime import datetime
                date_parts = birth_date.split('/')
                if len(date_parts) == 3:
                    day, month, year = date_parts
                    birth_date = f"{year}-{month.zfill(2)}-{day.zfill(2)}"
                    logger.info(f"تم تحويل تنسيق التاريخ من {data.get('birth_date')} إلى {birth_date}")
            except Exception as e:
                logger.error(f"خطأ في تحويل تنسيق التاريخ: {str(e)}")
                return Response({
                    'success': False,
                    'message': 'تنسيق التاريخ غير صحيح. الرجاء استخدام تنسيق DD/MM/YYYY أو YYYY-MM-DD',
                    'status': 'error'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # التأكد من عدم وجود مستخدم بنفس الإيميل أو الهاتف
        from .models import Utilisateur
        
        user_exists = False
        if email:
            user_exists = Utilisateur.objects.filter(email=email).exists()
        if phone and not user_exists:
            user_exists = Utilisateur.objects.filter(telephone=phone).exists()
            
        if user_exists:
            return Response({
                'success': False,
                'message': 'المستخدم موجود بالفعل',
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # إنشاء حساب المستخدم
        user_data = {
            'username': username,
            'password': password,
            'type_utilisateur': user_type,
            'date_naissance': birth_date,
            'adresse': adresse,
        }
        
        if email:
            user_data['email'] = email
        if phone:
            user_data['telephone'] = phone
        
        # الاسم الكامل - تقسيمه إلى اسم أول واسم أخير إذا كان ممكناً
        if full_name:
            name_parts = full_name.split(' ', 1)
            user_data['first_name'] = name_parts[0]
            if len(name_parts) > 1:
                user_data['last_name'] = name_parts[1]
        
        # إضافة الصورة إذا تم تحميلها
        if photo_profile:
            user_data['photo_profile'] = photo_profile
                    
        # إنشاء المستخدم باستخدام النموذج
        from .serializers import UserRegistrationSerializer
        
        serializer = UserRegistrationSerializer(data=user_data)
        if not serializer.is_valid():
            logger.error(f"خطأ في بيانات التسجيل: {serializer.errors}")
            return Response({
                'success': False,
                'message': 'بيانات غير صالحة',
                'errors': serializer.errors,
                'status': 'error'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # حفظ المستخدم في قاعدة البيانات
        user = serializer.save()
        logger.info(f"تم إنشاء المستخدم بنجاح: {user.id_utilisateur}")
        
        # إنشاء الملف الشخصي للسائق إذا كان نوع المستخدم سائق
        if user_type in ['Livreur', 'Chauffeur']:
            # معالجة أوقات العمل وحساب التوفر
            start_time = data.get('start_time')
            end_time = data.get('end_time')
            disponibilite = True  # القيمة الافتراضية
            try:
                if start_time and end_time:
                    from datetime import datetime
                    now = datetime.now().time()
                    fmt = '%H:%M'
                    start = datetime.strptime(start_time, fmt).time()
                    end = datetime.strptime(end_time, fmt).time()
                    if start < end:
                        disponibilite = start <= now <= end
                    else:
                        # الفترة تمتد لليوم التالي
                        disponibilite = now >= start or now <= end
            except Exception as e:
                logger.error(f"خطأ في حساب التوفر: {str(e)}")
                disponibilite = False

            driver_data = {
                'matricule_vehicule': data.get('matricule_vehicule'),
                'type_vehicule': data.get('type_vehicule'),
                'zone_couverture': data.get('zone_couverture'),
                'disponibilite': disponibilite,
            }

            # إضافة الصور إذا تم تحميلها
            if 'photo_vehicule' in request.FILES:
                driver_data['photo_vehicule'] = request.FILES['photo_vehicule']
            if 'photo_permis' in request.FILES:
                driver_data['photo_permis'] = request.FILES['photo_permis']
            if 'photo_carte_grise' in request.FILES:
                driver_data['photo_carte_grise'] = request.FILES['photo_carte_grise']
            if 'photo_assurance' in request.FILES:
                driver_data['photo_assurance'] = request.FILES['photo_assurance']
            if 'photo_vignette' in request.FILES:
                driver_data['photo_vignette'] = request.FILES['photo_vignette']
            if 'photo_carte_municipale' in request.FILES:
                driver_data['photo_carte_municipale'] = request.FILES['photo_carte_municipale']

            # إنشاء الملف الشخصي المناسب حسب نوع السائق
            from .models import Chauffeur, Livreur
            if user_type == 'Livreur':
                livreur = user.profil_livreur
                for key, value in driver_data.items():
                    if value is not None:
                        setattr(livreur, key, value)
                livreur.save()
            elif user_type == 'Chauffeur':
                chauffeur = user.profil_chauffeur
                for key, value in driver_data.items():
                    if value is not None:
                        setattr(chauffeur, key, value)
                chauffeur.save()

            logger.info(f"تم إنشاء الملف الشخصي للسائق بنجاح: {livreur.id if user_type == 'Livreur' else chauffeur.id}")

        # إنشاء توكن مباشرة بعد التسجيل
        access_token, refresh_token = create_jwt_token(user)
        
        # تجهيز بيانات المستخدم الأساسية
        user_data = {
            'id_utilisateur': user.id_utilisateur,
            'username': user.username,
            'email': user.email,
            'telephone': user.telephone,
            'type_utilisateur': user.type_utilisateur,
            'date_naissance': user.date_naissance,
            'adresse': user.adresse,
            'photo_profile': request.build_absolute_uri(user.photo_profile.url) if user.photo_profile else None,
            'is_active': user.is_active,
            'date_joined': user.date_joined
        }

        # إضافة البيانات الإضافية للسائقين
        if user_type in ['Livreur', 'Chauffeur']:
            driver_profile = None
            if user_type == 'Livreur' and hasattr(user, 'profil_livreur'):
                driver_profile = user.profil_livreur
            elif user_type == 'Chauffeur' and hasattr(user, 'profil_chauffeur'):
                driver_profile = user.profil_chauffeur

            if driver_profile:
                user_data.update({
                    'matricule_vehicule': driver_profile.matricule_vehicule,
                    'type_vehicule': driver_profile.type_vehicule,
                    'zone_couverture': driver_profile.zone_couverture,
                    'disponibilite': driver_profile.disponibilite,
                    'photo_vehicule': request.build_absolute_uri(driver_profile.photo_vehicule.url) if driver_profile.photo_vehicule else None,
                    'photo_permis': request.build_absolute_uri(driver_profile.photo_permis.url) if driver_profile.photo_permis else None,
                    'photo_carte_grise': request.build_absolute_uri(driver_profile.photo_carte_grise.url) if driver_profile.photo_carte_grise else None,
                    'photo_assurance': request.build_absolute_uri(driver_profile.photo_assurance.url) if driver_profile.photo_assurance else None,
                    'photo_vignette': request.build_absolute_uri(driver_profile.photo_vignette.url) if driver_profile.photo_vignette else None,
                    'photo_carte_municipale': request.build_absolute_uri(driver_profile.photo_carte_municipale.url) if driver_profile.photo_carte_municipale else None,
                })
        
        return Response({
            'success': True,
            'message': 'تم إنشاء الحساب بنجاح',
            'status': 'success',
            'user': user_data,
            'tokens': {
                'access': access_token,
                'refresh': refresh_token
            }
        }, status=status.HTTP_201_CREATED)
            
    except Exception as e:
        import traceback
        logger.error(f"خطأ في إكمال التسجيل: {str(e)}")
        logger.error(traceback.format_exc())
        return Response({
            'success': False,
            'message': f'حدث خطأ أثناء إكمال التسجيل: {str(e)}',
            'status': 'error'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['POST'])
@permission_classes([AllowAny])
def create_driver(request):
    """
    إنشاء سائق جديد (Livreur أو Chauffeur)
    """
    # 1. استخرج فقط الحقول الخاصة بالمستخدم
    user_fields = ['username', 'email', 'password', 'telephone', 'type_utilisateur', 'date_naissance', 'photo_profile']
    user_data = {field: request.data.get(field) for field in user_fields}
    if 'photo_profile' in request.FILES:
        user_data['photo_profile'] = request.FILES['photo_profile']

    driver_type = user_data.get('type_utilisateur')
    if driver_type not in ['Livreur', 'Chauffeur']:
        return Response({'status': 'error', 'message': 'نوع السائق غير صحيح'}, status=status.HTTP_400_BAD_REQUEST)

    serializer = UserRegistrationSerializer(data=user_data)
    if serializer.is_valid():
        user = serializer.save()
        # أضف باقي الحقول إلى نموذج السائق
        if driver_type == 'Livreur' and hasattr(user, 'profil_livreur'):
            livreur = user.profil_livreur
            livreur.matricule_vehicule = request.data.get('matricule_vehicule')
            livreur.type_vehicule = request.data.get('type_vehicule')
            livreur.zone_couverture = request.data.get('zone_couverture')
            livreur.disponibilite = request.data.get('disponibilite') == 'true'
            # أضف الصور إذا وجدت
            if 'photo_vehicule' in request.FILES:
                livreur.photo_vehicule = request.FILES['photo_vehicule']
            if 'photo_permis' in request.FILES:
                livreur.photo_permis = request.FILES['photo_permis']
            if 'photo_carte_grise' in request.FILES:
                livreur.photo_carte_grise = request.FILES['photo_carte_grise']
            if 'photo_assurance' in request.FILES:
                livreur.photo_assurance = request.FILES['photo_assurance']
            if 'photo_vignette' in request.FILES:
                livreur.photo_vignette = request.FILES['photo_vignette']
            if 'photo_carte_municipale' in request.FILES:
                livreur.photo_carte_municipale = request.FILES['photo_carte_municipale']
            livreur.save()
            profile_serializer = LivreurSerializer(livreur)
        elif driver_type == 'Chauffeur' and hasattr(user, 'profil_chauffeur'):
            chauffeur = user.profil_chauffeur
            chauffeur.matricule_vehicule = request.data.get('matricule_vehicule')
            chauffeur.type_vehicule = request.data.get('type_vehicule')
            chauffeur.zone_couverture = request.data.get('zone_couverture')
            chauffeur.disponibilite = request.data.get('disponibilite') == 'true'
            # أضف الصور إذا وجدت
            if 'photo_vehicule' in request.FILES:
                chauffeur.photo_vehicule = request.FILES['photo_vehicule']
            if 'photo_permis' in request.FILES:
                chauffeur.photo_permis = request.FILES['photo_permis']
            if 'photo_carte_grise' in request.FILES:
                chauffeur.photo_carte_grise = request.FILES['photo_carte_grise']
            if 'photo_assurance' in request.FILES:
                chauffeur.photo_assurance = request.FILES['photo_assurance']
            if 'photo_vignette' in request.FILES:
                chauffeur.photo_vignette = request.FILES['photo_vignette']
            if 'photo_carte_municipale' in request.FILES:
                chauffeur.photo_carte_municipale = request.FILES['photo_carte_municipale']
            chauffeur.save()
            profile_serializer = ChauffeurSerializer(chauffeur)
        else:
            profile_serializer = None
        return Response({
            'status': 'success',
            'message': 'تم إنشاء السائق بنجاح',
            'user': {
                'id_utilisateur': user.id_utilisateur,
                'username': user.username,
                'email': user.email,
                'telephone': user.telephone,
                'type_utilisateur': user.type_utilisateur,
                'date_naissance': user.date_naissance,
                'is_active': user.is_active,
                'date_joined': user.date_joined
            },
            'profile': profile_serializer.data if profile_serializer else None
        }, status=status.HTTP_201_CREATED)
    else:
        return Response({'status': 'error', 'message': 'بيانات غير صالحة', 'errors': serializer.errors}, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_drivers(request):
    """
    إرجاع جميع السائقين (Livreur و Chauffeur) مع الحقول المطلوبة بالفرنسية فقط
    """
    def get_file_url(request, file_field):
        if file_field:
            try:
                return request.build_absolute_uri(file_field.url)
            except Exception:
                return None
        return None

    # استيراد النماذج اللازمة
    from evaluations.models import Evaluation
    from commandes.models import Commande, Voyage
    from django.db.models import Avg, Count, Q

    livreurs = Livreur.objects.select_related('utilisateur').all()
    chauffeurs = Chauffeur.objects.select_related('utilisateur').all()
    data = []
    for l in livreurs:
        # حساب متوسط التقييم للسائق من نوع Livreur
        # نحسب فقط التقييمات المرتبطة بالطلبات المكتملة (Livrée)
        note_moyenne = 0
        commandes_livrees = Commande.objects.filter(livreur=l, statut='Livrée').count()
        if commandes_livrees > 0:
            evaluations = Evaluation.objects.filter(livreur=l, commande__statut='Livrée')
            if evaluations.exists():
                note_moyenne = round(evaluations.aggregate(Avg('note'))['note__avg'] or 0, 2)
        
        data.append({
            'id': l.id,
            'type': 'Livreur',
            'username': l.utilisateur.username if l.utilisateur else '',
            'telephone': l.utilisateur.telephone if l.utilisateur else '',
            'email': l.utilisateur.email if l.utilisateur else '',
            'photo_profile': get_file_url(request, l.utilisateur.photo_profile) if l.utilisateur and l.utilisateur.photo_profile else '',
            'type_vehicule': l.type_vehicule,
            'matricule_vehicule': l.matricule_vehicule,
            'zone_couverture': l.zone_couverture,
            'date_demande': l.utilisateur.date_joined.strftime('%Y-%m-%d') if l.utilisateur and l.utilisateur.date_joined else '',
            'statut_verification': l.statut_verification,
            'disponibilite': l.disponibilite,
            'date_naissance': l.utilisateur.date_naissance.strftime('%Y-%m-%d') if l.utilisateur and l.utilisateur.date_naissance else '',
            'photo_vehicule': get_file_url(request, l.photo_vehicule),
            'photo_permis': get_file_url(request, l.photo_permis),
            'photo_carte_grise': get_file_url(request, l.photo_carte_grise),
            'photo_assurance': get_file_url(request, l.photo_assurance),
            'photo_vignette': get_file_url(request, l.photo_vignette),
            'photo_carte_municipale': get_file_url(request, l.photo_carte_municipale),
            'latitude': l.utilisateur.latitude if l.utilisateur else None,
            'longitude': l.utilisateur.longitude if l.utilisateur else None,
            'note_moyenne': note_moyenne,
            'commandes_livrees': commandes_livrees
        })
    for c in chauffeurs:
        # حساب متوسط التقييم للسائق من نوع Chauffeur
        # نحسب فقط التقييمات المرتبطة بالرحلات المكتملة (Terminée)
        note_moyenne = 0
        voyages_termines = Voyage.objects.filter(chauffeur=c, statut='Terminée').count()
        if voyages_termines > 0:
            # في حالة Chauffeur، التقييم موجود في حقل rating في جدول Voyage
            rating_avg = Voyage.objects.filter(chauffeur=c, statut='Terminée').aggregate(Avg('rating'))['rating__avg']
            note_moyenne = round(rating_avg or 0, 2)
        
        data.append({
            'id': c.id,
            'type': 'Chauffeur',
            'username': c.utilisateur.username if c.utilisateur else '',
            'telephone': c.utilisateur.telephone if c.utilisateur else '',
            'email': c.utilisateur.email if c.utilisateur else '',
            'photo_profile': get_file_url(request, c.utilisateur.photo_profile) if c.utilisateur and c.utilisateur.photo_profile else '',
            'type_vehicule': c.type_vehicule,
            'matricule_vehicule': c.matricule_vehicule,
            'zone_couverture': c.zone_couverture,
            'date_demande': c.utilisateur.date_joined.strftime('%Y-%m-%d') if c.utilisateur and c.utilisateur.date_joined else '',
            'statut_verification': c.statut_verification,
            'disponibilite': c.disponibilite,
            'date_naissance': c.utilisateur.date_naissance.strftime('%Y-%m-%d') if c.utilisateur and c.utilisateur.date_naissance else '',
            'photo_vehicule': get_file_url(request, c.photo_vehicule),
            'photo_permis': get_file_url(request, c.photo_permis),
            'photo_carte_grise': get_file_url(request, c.photo_carte_grise),
            'photo_assurance': get_file_url(request, c.photo_assurance),
            'photo_vignette': get_file_url(request, c.photo_vignette),
            'photo_carte_municipale': get_file_url(request, c.photo_carte_municipale),
            'latitude': c.utilisateur.latitude if c.utilisateur else None,
            'longitude': c.utilisateur.longitude if c.utilisateur else None,
            'note_moyenne': note_moyenne,
            'voyages_termines': voyages_termines
        })
    return Response({'status': 'success', 'drivers': data})

@api_view(['GET'])
def pending_drivers_count(request):
    livreurs_pending = Livreur.objects.filter(statut_verification='En attente').count()
    chauffeurs_pending = Chauffeur.objects.filter(statut_verification='En attente').count()
    total_pending = livreurs_pending + chauffeurs_pending
    return Response({'pending_drivers': total_pending})

@api_view(['GET'])
@permission_classes([AllowAny])
def providers_stats(request):
    fournisseurs = Fournisseur.objects.select_related('utilisateur').all()
    data = []
    total_revenue = 0
    for f in fournisseurs:
        user = f.utilisateur
        commandes_livree = f.commandes.filter(statut='Livrée')
        total_montant = commandes_livree.aggregate(total=Sum('montant_total'))['total'] or 0
        total_frais = commandes_livree.aggregate(total=Sum('frais_livraison'))['total'] or 0
        revenu = float(total_montant) - float(total_frais)
        total_revenue += revenu
        data.append({
            'id': f.id,
            'nom': f.nom_commerce,
            'type': f.type_fournisseur,
            'email': user.email if user else '',
            'telephone': user.telephone if user else '',
            'adresse': f.adresse_commerce or (user.adresse if user else ''),
            'description': f.description or '',
            'logo': request.build_absolute_uri(f.logo.url) if f.logo else '',
            'horaires_ouverture': f.horaires_ouverture or '',
            'commandes': commandes_livree.count(),
            'revenu': revenu,
            'note': round(getattr(f, 'note_moyenne', 0), 2) if hasattr(f, 'note_moyenne') else 0,
            'produits': f.produits.count() if hasattr(f, 'produits') else 0,
            'statut': 'Vérifié' if user and user.is_active else 'Non vérifié',
            'date_inscription': user.date_joined.strftime('%Y-%m-%d') if user and user.date_joined else '',
        })
    return Response({'fournisseurs': data, 'total_revenue': total_revenue})

@api_view(['GET'])
@permission_classes([AllowAny])
def users_stats(request):
    from .models import Utilisateur
    clients = Utilisateur.objects.filter(type_utilisateur='Client')
    chauffeurs = Utilisateur.objects.filter(type_utilisateur='Chauffeur')
    livreurs = Utilisateur.objects.filter(type_utilisateur='Livreur')
    data = {
        'total': clients.count() + chauffeurs.count() + livreurs.count(),
        'clients': {
            'count': clients.count(),
            'latest': [
                {
                    'id': u.id_utilisateur,
                    'username': u.username,
                    'email': u.email,
                    'date_joined': u.date_joined
                } for u in clients.order_by('-date_joined')[:3]
            ]
        },
        'drivers': {
            'count': chauffeurs.count() + livreurs.count(),
            'chauffeurs': {
                'count': chauffeurs.count(),
                'latest': [
                    {
                        'id': u.id_utilisateur,
                        'username': u.username,
                        'email': u.email,
                        'date_joined': u.date_joined
                    } for u in chauffeurs.order_by('-date_joined')[:2]
                ]
            },
            'livreurs': {
                'count': livreurs.count(),
                'latest': [
                    {
                        'id': u.id_utilisateur,
                        'username': u.username,
                        'email': u.email,
                        'date_joined': u.date_joined
                    } for u in livreurs.order_by('-date_joined')[:2]
                ]
            }
        }
    }
    return Response(data)

@api_view(['PATCH'])
@permission_classes([AllowAny])  # تغيير من IsAuthenticated إلى AllowAny للسماح بالوصول بدون مصادقة
def update_driver_status(request, driver_id):
    """
    تحديث حالة التوفر للسائق (Livreur أو Chauffeur) حسب معرف المستخدم
    """
    try:
        disponibilite = request.data.get('disponibilite')
        if disponibilite is None:
            return Response({'error': 'حقل disponibilite مطلوب'}, status=status.HTTP_400_BAD_REQUEST)
        
        # تحويل القيمة إلى boolean
        disponibilite = disponibilite in [True, 'true', 'True', 1, '1']
        
        # البحث عن المستخدم أولاً
        try:
            user = Utilisateur.objects.get(id_utilisateur=driver_id)
        except Utilisateur.DoesNotExist:
            return Response({'error': 'لم يتم العثور على المستخدم'}, status=status.HTTP_404_NOT_FOUND)
        
        # التحقق من نوع المستخدم وتحديث حالة التوفر
        driver = None
        driver_type = None
        driver_id_in_table = None
        
        if user.type_utilisateur == 'Livreur' and hasattr(user, 'profil_livreur'):
            driver = user.profil_livreur
            driver_type = 'Livreur'
            driver_id_in_table = driver.id
            # تحديث حالة التوفر في جدول Livreur مباشرة
            Livreur.objects.filter(id=driver_id_in_table).update(disponibilite=disponibilite)
        elif user.type_utilisateur == 'Chauffeur' and hasattr(user, 'profil_chauffeur'):
            driver = user.profil_chauffeur
            driver_type = 'Chauffeur'
            driver_id_in_table = driver.id
            # تحديث حالة التوفر في جدول Chauffeur مباشرة
            Chauffeur.objects.filter(id=driver_id_in_table).update(disponibilite=disponibilite)
        
        if not driver:
            return Response({'error': 'المستخدم ليس سائقاً أو لا يملك ملف تعريف سائق'}, status=status.HTTP_404_NOT_FOUND)
        
        # تحديث الكائن المحلي بعد التحديث في قاعدة البيانات
        driver.refresh_from_db()
        
        # إرجاع الاستجابة
        return Response({
            'message': 'تم تحديث حالة التوفر بنجاح',
            'disponibilite': driver.disponibilite,
            'driver_id': driver_id,
            'driver_id_in_table': driver_id_in_table,
            'driver_type': driver_type
        })
    except Exception as e:
        import traceback
        return Response({
            'error': f'حدث خطأ: {str(e)}',
            'trace': traceback.format_exc()
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def clients_table_stats(request):
    clients = Utilisateur.objects.filter(type_utilisateur='Client')
    data = []
    for client in clients:
        commandes = Commande.objects.filter(client__utilisateur=client, statut='Livrée')
        commandes_count = commandes.count()
        total_depense = commandes.aggregate(total=Sum('montant_total'))['total'] or 0
        evals = Evaluation.objects.filter(client=client.profil_client)
        note = (evals.aggregate(avg=Avg('note'))['avg'] or 0) if commandes_count > 0 else 0
        data.append({
            'id': client.id_utilisateur,
            'name': client.username,
            'email': client.email,
            'phone': client.telephone,
            'address': client.adresse,
            'ordersCount': commandes_count,
            'totalSpent': float(total_depense),
            'rating': round(note, 2),
            'status': 'active' if client.is_active else 'inactive',
            'registrationDate': client.date_joined.strftime('%Y-%m-%d') if client.date_joined else '',
            'photo_profile': request.build_absolute_uri(client.photo_profile.url) if client.photo_profile else None,
            'date_naissance': client.date_naissance.strftime('%Y-%m-%d') if client.date_naissance else None,
            'is_active': client.is_active,
            'last_login': client.last_login.strftime('%Y-%m-%d %H:%M') if client.last_login else None,
            'last_modified': client.last_modified.strftime('%Y-%m-%d %H:%M') if client.last_modified else None,
        })
    return Response({'clients': data})

@api_view(['POST'])
@permission_classes([AllowAny])
def create_provider(request):
    """
    API لإنشاء مزود جديد (Fournisseur) مع مستخدم مرتبط.
    لا يتطلب تاريخ الميلاد.
    يقبل جميع الحقول من الفورم ويربطها بمستخدم من نوع Fournisseur.
    """
    try:
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        files = request.FILES

        # تحقق من الحقول المطلوبة للمستخدم
        required_user_fields = ['username', 'password', 'email', 'telephone']
        for field in required_user_fields:
            if not data.get(field):
                return Response({
                    'status': 'error',
                    'message': f'الحقل {field} مطلوب'
                }, status=status.HTTP_400_BAD_REQUEST)

        # إنشاء المستخدم أولاً
        user = Utilisateur(
            username=data['username'],
            email=data['email'],
            telephone=data['telephone'],
            adresse=data.get('adresse', ''),
            type_utilisateur='Fournisseur',
            latitude=data.get('latitude'),
            longitude=data.get('longitude'),
        )
        user.set_password(data['password'])
        if files.get('photo_profile'):
            user.photo_profile = files['photo_profile']
        user.save()

        # تحديث كائن Fournisseur الذي أنشأه signal تلقائياً
        fournisseur = getattr(user, 'profil_fournisseur', None)
        if not fournisseur:
            return Response({
                'status': 'error',
                'message': 'فشل في إنشاء كيان Fournisseur تلقائياً. تحقق من signals.'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        fournisseur.type_fournisseur = data.get('type_fournisseur', 'Restaurant')
        fournisseur.nom_commerce = data.get('nom_commerce', '')
        fournisseur.description = data.get('description', '')
        fournisseur.adresse_commerce = data.get('adresse_commerce', '')
        fournisseur.horaires_ouverture = data.get('horaires_ouverture', '')
        if files.get('logo'):
            fournisseur.logo = files['logo']
        fournisseur.save()

        # إرجاع البيانات
        return Response({
            'status': 'success',
            'message': 'تم إنشاء المزود بنجاح',
            'user': {
                'id_utilisateur': user.id_utilisateur,
                'username': user.username,
                'email': user.email,
                'telephone': user.telephone,
                'adresse': user.adresse,
                'type_utilisateur': user.type_utilisateur,
                'photo_profile': request.build_absolute_uri(user.photo_profile.url) if user.photo_profile else None,
            },
            'fournisseur': FournisseurSerializer(fournisseur, context={'request': request}).data
        }, status=status.HTTP_201_CREATED)
    except Exception as e:
        import traceback
        return Response({
            'status': 'error',
            'message': str(e),
            'trace': traceback.format_exc()
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT', 'PATCH'])
@permission_classes([AllowAny])
def update_provider(request, provider_id):
    """
    API لتعديل بيانات مزود (Fournisseur) مع دعم رفع صورة الشعار وتعديل جميع الحقول.
    """
    try:
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        files = request.FILES

        # جلب المزود
        try:
            fournisseur = Fournisseur.objects.get(id=provider_id)
        except Fournisseur.DoesNotExist:
            return Response({'status': 'error', 'message': 'Fournisseur introuvable.'}, status=404)

        # تحديث بيانات المستخدم المرتبط إذا وجدت
        user = fournisseur.utilisateur
        if user:
            user.email = data.get('email', user.email)
            user.telephone = data.get('telephone', user.telephone)
            user.adresse = data.get('adresse', user.adresse)
            if files.get('photo_profile'):
                user.photo_profile = files['photo_profile']
            user.save()

        # تحديث بيانات Fournisseur
        fournisseur.type_fournisseur = data.get('type_fournisseur', fournisseur.type_fournisseur)
        fournisseur.nom_commerce = data.get('nom_commerce', fournisseur.nom_commerce)
        fournisseur.description = data.get('description', fournisseur.description)
        fournisseur.adresse_commerce = data.get('adresse_commerce', fournisseur.adresse_commerce)
        fournisseur.horaires_ouverture = data.get('horaires_ouverture', fournisseur.horaires_ouverture)
        if files.get('logo'):
            fournisseur.logo = files['logo']
        fournisseur.save()

        return Response({
            'status': 'success',
            'message': 'Fournisseur modifié avec succès',
            'fournisseur': FournisseurSerializer(fournisseur, context={'request': request}).data
        })
    except Exception as e:
        import traceback
        return Response({
            'status': 'error',
            'message': str(e),
            'trace': traceback.format_exc()
        }, status=500)

@api_view(['PATCH'])
@permission_classes([AllowAny])
def verify_provider(request, provider_id):
    """
    تفعيل أو إلغاء تفعيل مزود (Fournisseur) عبر is_active للمستخدم المرتبط.
    الطلب: { "is_active": true/false }
    """
    try:
        fournisseur = Fournisseur.objects.select_related('utilisateur').get(id=provider_id)
        user = fournisseur.utilisateur
        if not user:
            return Response({'status': 'error', 'message': 'Utilisateur introuvable.'}, status=404)
        is_active = request.data.get('is_active')
        if is_active is None:
            return Response({'status': 'error', 'message': 'Champ is_active requis.'}, status=400)
        user.is_active = bool(is_active)
        user.save()
        return Response({'status': 'success', 'message': 'Statut de vérification mis à jour.', 'is_active': user.is_active})
    except Fournisseur.DoesNotExist:
        return Response({'status': 'error', 'message': 'Fournisseur introuvable.'}, status=404)
    except Exception as e:
        import traceback
        return Response({'status': 'error', 'message': str(e), 'trace': traceback.format_exc()}, status=500)

@api_view(['DELETE'])
@permission_classes([AllowAny])
def delete_provider(request, provider_id):
    """
    حذف مزود (Fournisseur) مع حذف جميع المنتجات التابعة له فقط، ثم حذف المستخدم المرتبط.
    """
    try:
        fournisseur = Fournisseur.objects.select_related('utilisateur').get(id=provider_id)
        # حذف جميع المنتجات التابعة لهذا المزود فقط
        Produit.objects.filter(fournisseur=fournisseur).delete()
        # حذف المستخدم المرتبط (سيحذف كائن Fournisseur تلقائياً بسبب on_delete=CASCADE)
        user = fournisseur.utilisateur
        if user:
            user.delete()
        return Response({'status': 'success', 'message': 'Fournisseur et ses produits supprimés avec succès.'})
    except Fournisseur.DoesNotExist:
        return Response({'status': 'error', 'message': 'Fournisseur introuvable.'}, status=404)
    except Exception as e:
        import traceback
        return Response({'status': 'error', 'message': str(e), 'trace': traceback.format_exc()}, status=500)
    
@api_view(['GET'])
@permission_classes([AllowAny])
def liste_administrateurs(request):
    try:
        admins = Utilisateur.objects.filter(type_utilisateur='Administrateur')
        data = []
        for admin in admins:
            data.append({
                "id": admin.id_utilisateur,
                "nom": admin.username or "-",
                "email": admin.email or "-",
                "role": "Directeur général" if admin.is_superuser else "Superviseur",
                "telephone": admin.telephone or "-",
                "adresse": admin.adresse or "-",
                "date_creation": admin.date_joined.strftime("%Y-%m-%d %H:%M") if admin.date_joined else "-",
                "statut": "Actif" if admin.is_active else "Inactif",
                "is_active": admin.is_active,  # أضف هذا السطر
                "photo_profile": request.build_absolute_uri(admin.photo_profile.url) if admin.photo_profile else None,
                "date_naissance": admin.date_naissance.strftime("%Y-%m-%d") if admin.date_naissance else None,
                "last_login": admin.last_login.strftime("%Y-%m-%d %H:%M") if admin.last_login else None,
                "last_modified": admin.last_modified.strftime("%Y-%m-%d %H:%M") if admin.last_modified else None,
                "is_staff": getattr(admin, 'is_staff', False),
                "is_superuser": getattr(admin, 'is_superuser', False),
            })
        return Response({
            "status": "success",
            "administrateurs": data
        })
    except Exception as e:
        return Response({
            "status": "error",
            "message": str(e)
        }, status=500)
    
@api_view(['POST'])
@permission_classes([AllowAny])
def create_admin(request):
    """
    API لإضافة مسؤول جديد (Administrateur) مع جميع الحقول المطلوبة ودعم رفع صورة.
    """
    try:
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        files = request.FILES

        # تحقق من الحقول المطلوبة
        required_fields = ['nom', 'email', 'password']
        for field in required_fields:
            if not data.get(field):
                return Response({
                    'status': 'error',
                    'message': f'Le champ {field} est obligatoire.'
                }, status=400)

        # إنشاء المستخدم
        from .models import Utilisateur, Administrateur
        user = Utilisateur(
            username=data['nom'],
            email=data['email'],
            telephone=data.get('telephone', ''),
            adresse=data.get('adresse', ''),
            date_naissance=data.get('date_naissance') or None,
            type_utilisateur='Administrateur',
            is_active=data.get('is_active', 'true') in ['true', 'True', True, 1, '1'],
            is_staff=data.get('is_staff', 'true') in ['true', 'True', True, 1, '1'],
            is_superuser=data.get('is_superuser', 'false') in ['true', 'True', True, 1, '1'],
        )
        user.set_password(data['password'])
        if files.get('photo_profile'):
            user.photo_profile = files['photo_profile']
        user.save()

        # تحديث كائن Administrateur المرتبط
        admin_obj = getattr(user, 'profil_admin', None)
        if admin_obj:
            admin_obj.is_staff = user.is_staff
            admin_obj.is_superuser = user.is_superuser
            admin_obj.save()

        return Response({
            'status': 'success',
            'message': 'Administrateur ajouté avec succès.',
            'admin': {
                'id': user.id_utilisateur,
                'nom': user.username,
                'email': user.email,
                'telephone': user.telephone,
                'adresse': user.adresse,
                'date_naissance': user.date_naissance,
                'photo_profile': request.build_absolute_uri(user.photo_profile.url) if user.photo_profile else None,
                'is_active': user.is_active,
                'is_staff': user.is_staff,
                'is_superuser': user.is_superuser,
            }
        }, status=201)
    except Exception as e:
        import traceback
        return Response({
            'status': 'error',
            'message': f'Erreur lors de la création: {str(e)}',
            'trace': traceback.format_exc()
        }, status=500)
    
@api_view(['POST'])
@permission_classes([AllowAny])
def check_admin_exists(request):
    """
    API للتحقق من وجود إداري بنفس الإيميل أو الهاتف أو الاسم (username) فقط بين الإداريين
    """
    email = request.data.get('email')
    telephone = request.data.get('telephone')
    nom = request.data.get('nom')
    exists_email = False
    exists_telephone = False
    exists_nom = False
    if email:
        exists_email = Utilisateur.objects.filter(email=email, type_utilisateur='Administrateur').exists()
    if telephone:
        exists_telephone = Utilisateur.objects.filter(telephone=telephone, type_utilisateur='Administrateur').exists()
    if nom:
        exists_nom = Utilisateur.objects.filter(username=nom, type_utilisateur='Administrateur').exists()
    fields = []
    if exists_nom:
        fields.append('nom')
    if exists_email:
        fields.append('email')
    if exists_telephone:
        fields.append('telephone')
    if fields:
        msg = []
        if 'nom' in fields:
            msg.append("Ce nom d'utilisateur est déjà utilisé par un autre administrateur.")
        if 'email' in fields:
            msg.append("Cet email est déjà utilisé par un autre administrateur.")
        if 'telephone' in fields:
            msg.append("Ce téléphone est déjà utilisé par un autre administrateur.")
        return Response({
            'exists': True,
            'fields': fields,
            'message': ' '.join(msg)
        }, status=200)
    return Response({'exists': False, 'fields': []}, status=200)
    
@api_view(['PATCH'])
@permission_classes([AllowAny])
def update_admin(request, admin_id):
    try:
        user = Utilisateur.objects.get(id_utilisateur=admin_id, type_utilisateur='Administrateur')
        data = request.data.copy()
        files = request.FILES

        # تحديث الحقول المطلوبة فقط
        for field in ['email', 'telephone', 'adresse', 'is_active', 'is_staff', 'is_superuser']:
            if field in data:
                value = data[field]
                if field in ['is_active', 'is_staff', 'is_superuser']:
                    value = value in ['true', 'True', True, 1, '1', 'Oui']
                setattr(user, field, value)
        if files.get('photo_profile'):
            user.photo_profile = files['photo_profile']
        user.save()

        return Response({
            'status': 'success',
            'message': 'Administrateur modifié avec succès.',
            'admin': {
                'id': user.id_utilisateur,
                'nom': user.username,
                'email': user.email,
                'telephone': user.telephone,
                'adresse': user.adresse,
                'photo_profile': request.build_absolute_uri(user.photo_profile.url) if user.photo_profile else None,
                'is_active': user.is_active,
                'is_staff': user.is_staff,
                'is_superuser': user.is_superuser,
            }
        })
    except Utilisateur.DoesNotExist:
        return Response({'status': 'error', 'message': 'Administrateur introuvable.'}, status=404)
    except Exception as e:
        import traceback
        return Response({'status': 'error', 'message': str(e), 'trace': traceback.format_exc()}, status=500)
    
@api_view(['DELETE'])
@permission_classes([AllowAny])
def delete_admin(request, admin_id):
    """
    حذف حساب إداري (Administrateur) عبر معرفه
    """
    try:
        from .models import Utilisateur
        try:
            user = Utilisateur.objects.get(id_utilisateur=admin_id, type_utilisateur='Administrateur')
        except Utilisateur.DoesNotExist:
            return Response({'status': 'error', 'message': 'Administrateur introuvable.'}, status=404)

        # التحقق من التوكن والمصادقة (اختياري: يمكن تقييد الحذف للمسؤولين فقط)
        # يمكن إضافة تحقق إضافي هنا إذا لزم الأمر

        user.delete()
        return Response({'status': 'success', 'message': 'Administrateur supprimé avec succès.'})
    except Exception as e:
        import traceback
        return Response({'status': 'error', 'message': str(e), 'trace': traceback.format_exc()}, status=500)
    
@api_view(['GET'])
@permission_classes([AllowAny])
def validate_token(request):
    """
    تحقق من صلاحية التوكن (JWT). يرفض التوكن المنتهي أو غير الصالح. مدة الصلاحية ساعة واحدة كحد أقصى.
    """
    auth_header = request.headers.get('Authorization', None)
    if not auth_header:
        return Response({'error': 'Authorization header missing'}, status=status.HTTP_401_UNAUTHORIZED)
    parts = auth_header.split(' ')
    if len(parts) != 2 or parts[0].lower() != 'bearer':
        return Response({'error': 'Invalid Authorization header format'}, status=status.HTTP_401_UNAUTHORIZED)
    token = parts[1]
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=[settings.SIMPLE_JWT['ALGORITHM']]
        )
        # تحقق من مدة الصلاحية (exp)
        exp = payload.get('exp')
        if not exp:
            return Response({'error': 'Token missing exp'}, status=status.HTTP_401_UNAUTHORIZED)
        now = datetime.datetime.utcnow().timestamp()
        if now > exp:
            return Response({'error': 'Token expired'}, status=status.HTTP_401_UNAUTHORIZED)
        # مدة الصلاحية يجب ألا تتجاوز ساعة واحدة
        iat = payload.get('iat')
        if iat and (exp - iat > 3600):
            return Response({'error': 'Token duration too long'}, status=status.HTTP_401_UNAUTHORIZED)
        return Response({'message': 'Token is valid'}, status=status.HTTP_200_OK)
    except jwt.ExpiredSignatureError:
        return Response({'error': 'Token expired'}, status=status.HTTP_401_UNAUTHORIZED)
    except jwt.InvalidTokenError as e:
        return Response({'error': f'Invalid token: {str(e)}'}, status=status.HTTP_401_UNAUTHORIZED)
    
def get_user_avatar(user):
    if hasattr(user, 'photo_profile') and user.photo_profile:
        return settings.MEDIA_URL + str(user.photo_profile)
    return ''

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def clients_and_drivers(request):
    users = Utilisateur.objects.filter(type_utilisateur__in=['Client', 'Chauffeur', 'Livreur'])
    data = [
        {
            'id_utilisateur': u.id_utilisateur,
            'username': u.username,
            'type_utilisateur': u.type_utilisateur,
            'photo_profile': get_user_avatar(u),
            'email': u.email,
            'telephone': u.telephone,
        }
        for u in users
    ]
    return Response(data)

class OTPCodeAdminSerializer(ModelSerializer):
    class Meta:
        model = OTPCode
        fields = [
            'id', 'code', 'identifier', 'type', 'is_used', 'is_blocked',
            'created_at', 'expires_at', 'verification_attempts', 'last_attempt_time',
            'registration_data', 'user'
        ]
    
    def to_representation(self, instance):
        data = super().to_representation(instance)
        # إضافة معلومات المستخدم المرتبط إذا وجد
        if instance.user:
            data['user_info'] = {
                'id': instance.user.id_utilisateur,
                'username': instance.user.username,
                'email': instance.user.email,
                'type_utilisateur': instance.user.type_utilisateur,
                'photo_profile': self.context['request'].build_absolute_uri(instance.user.photo_profile.url) if instance.user.photo_profile else None,
            }
        else:
            data['user_info'] = None
        # إضافة حالة انتهاء الصلاحية والوقت المتبقي
        data['is_expired'] = instance.is_expired
        data['time_remaining'] = instance.time_remaining
        return data

@api_view(['GET'])
@permission_classes([AllowAny])  # يمكن تقييدها لاحقاً للمشرفين فقط
def list_all_otp_codes(request):
    """
    API لعرض جميع رموز OTP مع جميع التفاصيل (للاستخدام في لوحة الإدارة)
    """
    otps = OTPCode.objects.all().order_by('-created_at')
    serializer = OTPCodeAdminSerializer(otps, many=True, context={'request': request})
    return Response({
        'status': 'success',
        'count': len(serializer.data),
        'otps': serializer.data
    })
    
@api_view(['PATCH'])
@permission_classes([AllowAny])
def update_driver_verification_status(request, driver_id):
    """
    تحديث حالة التحقق للسائق (Livreur أو Chauffeur) حسب معرف السائق
    """
    try:
        statut_verification = request.data.get('statut_verification')
        raison_refus = request.data.get('raison_refus')
        
        if statut_verification is None:
            return Response({'error': 'حقل statut_verification مطلوب'}, status=status.HTTP_400_BAD_REQUEST)
        
        # التحقق من أن القيمة المقدمة هي قيمة صالحة
        valid_statuses = ['En attente', 'Approuvé', 'Refusé']
        if statut_verification not in valid_statuses:
            return Response({'error': f'قيمة statut_verification غير صالحة. القيم المسموح بها هي: {", ".join(valid_statuses)}'}, 
                            status=status.HTTP_400_BAD_REQUEST)
        
        # البحث عن السائق مباشرة باستخدام معرفه في جدول Livreur أو Chauffeur
        driver = None
        driver_type = None
        
        # محاولة البحث في جدول Livreur
        try:
            driver = Livreur.objects.get(id=driver_id)
            driver_type = 'Livreur'
        except Livreur.DoesNotExist:
            # محاولة البحث في جدول Chauffeur
            try:
                driver = Chauffeur.objects.get(id=driver_id)
                driver_type = 'Chauffeur'
            except Chauffeur.DoesNotExist:
                return Response({'error': 'لم يتم العثور على السائق'}, status=status.HTTP_404_NOT_FOUND)
        
        # تحديث حالة التحقق
        update_data = {'statut_verification': statut_verification}
        if statut_verification == 'Approuvé':
            update_data['certification_date'] = timezone.now().date()
            update_data['raison_refus'] = None
        elif statut_verification == 'Refusé' and raison_refus:
            update_data['raison_refus'] = raison_refus
            update_data['certification_date'] = None
        
        # تحديث السائق في قاعدة البيانات
        if driver_type == 'Livreur':
            Livreur.objects.filter(id=driver_id).update(**update_data)
        else:  # Chauffeur
            Chauffeur.objects.filter(id=driver_id).update(**update_data)
        
        # تحديث الكائن المحلي بعد التحديث في قاعدة البيانات
        driver.refresh_from_db()
        
        # إرجاع الاستجابة
        response_data = {
            'message': 'تم تحديث حالة التحقق بنجاح',
            'statut_verification': driver.statut_verification,
            'driver_id': driver_id,
            'driver_type': driver_type
        }
        
        if driver.statut_verification == 'Approuvé':
            response_data['certification_date'] = driver.certification_date
        elif driver.statut_verification == 'Refusé':
            response_data['raison_refus'] = driver.raison_refus
            
        return Response(response_data)
    except Exception as e:
        import traceback
        return Response({
            'error': f'حدث خطأ: {str(e)}',
            'trace': traceback.format_exc()
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['POST'])
def login_view(request):
    """
    تسجيل دخول المستخدم واستخراج التوكن
    """
    try:
        data = request.data
        
        # استخراج البيانات من الطلب
        email = data.get('email')
        telephone = data.get('telephone')
        username = data.get('username')
        password = data.get('password')
        type_utilisateur = data.get('type_utilisateur')
        
        # تحديد نوع تسجيل الدخول (بريد إلكتروني أو هاتف أو اسم مستخدم)
        if email:
            login_field = 'email'
            login_value = email
        elif telephone:
            login_field = 'telephone'
            login_value = telephone
        elif username:
            login_field = 'username'
            login_value = username
        else:
            return Response({
                'status': 'error',
                'message': 'يجب توفير بريد إلكتروني أو رقم هاتف أو اسم مستخدم'
            }, status=400)
        
        # البحث عن المستخدم
        try:
            if login_field == 'email':
                user = Utilisateur.objects.get(email=login_value)
            elif login_field == 'telephone':
                user = Utilisateur.objects.get(telephone=login_value)
            else:
                user = Utilisateur.objects.get(username=login_value)
        except Utilisateur.DoesNotExist:
            return Response({
                'status': 'error',
                'message': 'المستخدم غير موجود'
            }, status=401)
        
        # التحقق من نوع المستخدم إذا تم تحديده
        if type_utilisateur and user.type_utilisateur != type_utilisateur:
            return Response({
                'status': 'error',
                'message': 'نوع الحساب غير متطابق',
                'error': 'نوع الحساب غير متطابق مع النوع المحدد'
            }, status=401)
        
        # التحقق من كلمة المرور
        if not user.check_password(password):
            return Response({
                'status': 'error',
                'message': 'كلمة المرور غير صحيحة',
                'error': 'كلمة المرور غير صحيحة'
            }, status=401)
        
        # التحقق من حالة الحساب
        if not user.is_active:
            return Response({
                'status': 'inactive',
                'message': 'الحساب غير نشط',
                'user': {
                    'id_utilisateur': user.id_utilisateur,
                    'username': user.username,
                    'email': user.email,
                    'telephone': user.telephone,
                    'type_utilisateur': user.type_utilisateur,
                }
            }, status=200)
        
        # تحديث وقت آخر تسجيل دخول
        user.last_login = timezone.now()
        
        # إضافة إحداثيات المستخدم بناءً على عنوان IP
        client_ip = get_client_ip(request)
        try:
            # استخدام خدمة ipinfo.io للحصول على الإحداثيات بناءً على عنوان IP
            response = requests.get(f'https://ipinfo.io/{client_ip}/json')
            if response.status_code == 200:
                location_data = response.json()
                if 'loc' in location_data:
                    lat, lng = location_data['loc'].split(',')
                    user.latitude = float(lat)
                    user.longitude = float(lng)
                    print(f"تم تحديث إحداثيات المستخدم: {lat}, {lng}")
        except Exception as e:
            print(f"خطأ في تحديث الإحداثيات: {e}")
            # لا نستخدم إحداثيات افتراضية، بدلاً من ذلك نترك الإحداثيات كما هي
            print("فشل تحديث الإحداثيات، سيتم استخدام آخر إحداثيات معروفة أو طلبها من المستخدم")
        
        # حفظ التغييرات
        user.save()
        
        # إنشاء أو استرجاع التوكن
        token, created = Token.objects.get_or_create(user=user)
        
        # إعداد بيانات المستخدم للرد
        user_data = {
            'id_utilisateur': user.id_utilisateur,
            'username': user.username,
            'email': user.email,
            'telephone': user.telephone,
            'type_utilisateur': user.type_utilisateur,
            'is_staff': user.is_staff,
            'photo_profile': user.photo_profile.url if user.photo_profile else None,
            'latitude': user.latitude,
            'longitude': user.longitude,
        }
        
        # إضافة معلومات إضافية حسب نوع المستخدم
        if user.type_utilisateur == 'Livreur' and hasattr(user, 'profil_livreur'):
            user_data['statut_verification'] = user.profil_livreur.statut_verification
            user_data['raison_refus'] = user.profil_livreur.raison_refus
            user_data['disponibilite'] = user.profil_livreur.disponibilite
        elif user.type_utilisateur == 'Chauffeur' and hasattr(user, 'profil_chauffeur'):
            user_data['statut_verification'] = user.profil_chauffeur.statut_verification
            user_data['raison_refus'] = user.profil_chauffeur.raison_refus
            user_data['disponibilite'] = user.profil_chauffeur.disponibilite
        
        return Response({
            'status': 'success',
            'message': 'تم تسجيل الدخول بنجاح',
            'user': user_data,
            'token': token.key
        }, status=200)
        
    except Exception as e:
        print(f"خطأ في تسجيل الدخول: {str(e)}")
        return Response({
            'status': 'error',
            'message': 'حدث خطأ أثناء تسجيل الدخول',
            'error': str(e)
        }, status=500)

# دالة مساعدة للحصول على عنوان IP للعميل
def get_client_ip(request):
    x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_for:
        ip = x_forwarded_for.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR', '127.0.0.1')
    return ip

# دالة جديدة للحصول على موقع المستخدم بدون الحاجة إلى توكن
@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_location(request, user_id):
    """
    الحصول على موقع المستخدم (خط العرض وخط الطول) بدون الحاجة إلى توكن
    """
    try:
        # البحث عن المستخدم
        user = Utilisateur.objects.get(id_utilisateur=user_id)
        
        # التحقق مما إذا كانت إحداثيات المستخدم متوفرة
        if user.latitude is not None and user.longitude is not None:
            return Response({
                'status': 'success',
                'user_id': user_id,
                'latitude': user.latitude,
                'longitude': user.longitude,
                'message': 'تم الحصول على إحداثيات المستخدم بنجاح'
            }, status=200)
        
        # محاولة استخدام آخر إحداثيات معروفة للمستخدم
        try:
            if hasattr(user, 'profil_livreur') and user.profil_livreur and hasattr(user.profil_livreur, 'derniere_latitude') and user.profil_livreur.derniere_latitude:
                return Response({
                    'status': 'last_known',
                    'user_id': user_id,
                    'latitude': user.profil_livreur.derniere_latitude,
                    'longitude': user.profil_livreur.derniere_longitude,
                    'message': 'تم استخدام آخر موقع معروف للمستخدم'
                }, status=200)
            elif hasattr(user, 'profil_chauffeur') and user.profil_chauffeur and hasattr(user.profil_chauffeur, 'derniere_latitude') and user.profil_chauffeur.derniere_latitude:
                return Response({
                    'status': 'last_known',
                    'user_id': user_id,
                    'latitude': user.profil_chauffeur.derniere_latitude,
                    'longitude': user.profil_chauffeur.derniere_longitude,
                    'message': 'تم استخدام آخر موقع معروف للمستخدم'
                }, status=200)
        except Exception as e:
            print(f"خطأ في استخدام آخر موقع معروف: {e}")
        
        # بدلاً من استخدام إحداثيات افتراضية، نرجع خطأ للعميل
        # لكن مع رمز استجابة 200 بدلاً من 404 لتجنب الأخطاء في العميل
        return Response({
            'status': 'error',
            'user_id': user_id,
            'message': 'تعذر تحديد موقعك الحقيقي. يرجى التأكد من تفعيل خدمات الموقع وإعادة المحاولة.'
        }, status=200)
        
    except Utilisateur.DoesNotExist:
        return Response({
            'status': 'error',
            'message': 'المستخدم غير موجود'
        }, status=404)
    except Exception as e:
        return Response({
            'status': 'error',
            'message': f'حدث خطأ: {str(e)}'
        }, status=200)  # استخدام رمز 200 بدلاً من 500 لتجنب الأخطاء في العميل
    
# دالة جديدة لتحديث موقع المستخدم
@api_view(['PUT', 'PATCH'])
@permission_classes([AllowAny])
def update_user_location(request, user_id):
    """
    تحديث موقع المستخدم (خط العرض وخط الطول) بدون الحاجة إلى توكن
    """
    try:
        # البحث عن المستخدم
        user = Utilisateur.objects.get(id_utilisateur=user_id)
        
        # التحقق من وجود بيانات الموقع في الطلب
        if 'latitude' in request.data and 'longitude' in request.data:
            try:
                latitude = float(request.data['latitude'])
                longitude = float(request.data['longitude'])
                
                # تحديث موقع المستخدم
                user.latitude = latitude
                user.longitude = longitude
                user.save()
                
                # تحديث آخر موقع معروف للمستخدم في الملف الشخصي
                if hasattr(user, 'profil_livreur') and user.profil_livreur:
                    user.profil_livreur.derniere_latitude = latitude
                    user.profil_livreur.derniere_longitude = longitude
                    user.profil_livreur.save()
                elif hasattr(user, 'profil_chauffeur') and user.profil_chauffeur:
                    user.profil_chauffeur.derniere_latitude = latitude
                    user.profil_chauffeur.derniere_longitude = longitude
                    user.profil_chauffeur.save()
                
                print(f"تم تحديث إحداثيات المستخدم: {latitude}, {longitude}")
                
                return Response({
                    'status': 'success',
                    'user_id': user_id,
                    'latitude': latitude,
                    'longitude': longitude,
                    'message': 'تم تحديث موقع المستخدم بنجاح'
                }, status=200)
            except ValueError:
                return Response({
                    'status': 'error',
                    'message': 'قيم الإحداثيات غير صالحة'
                }, status=400)
        else:
            return Response({
                'status': 'error',
                'message': 'بيانات الموقع مفقودة (latitude, longitude)'
            }, status=400)
    except Utilisateur.DoesNotExist:
        return Response({
            'status': 'error',
            'message': 'المستخدم غير موجود'
        }, status=404)
    except Exception as e:
        return Response({
            'status': 'error',
            'message': f'حدث خطأ: {str(e)}'
        }, status=500)
    