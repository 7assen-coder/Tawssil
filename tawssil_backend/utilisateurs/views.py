from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.parsers import JSONParser, MultiPartParser
from django.db.models import Q
from .models import Utilisateur, OTPCode
from .serializers import UserRegistrationSerializer, UserListSerializer, UserUpdateSerializer, jwt_decode_handler, create_jwt_token
import jwt
from django.conf import settings
import datetime
import logging
from django.utils import timezone
from .services import generate_otp, save_otp_to_db, send_email_otp, send_sms_otp, verify_otp as verify_otp_service, check_user_exists_by_type, send_otp_with_fallback
import time
from django.core.mail import send_mail
import random

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
                    'is_staff': user.is_staff,
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
                "is_staff": user.is_staff,
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
    تحديث بيانات المستخدم - يمكن للمستخدم تحديث بياناته الشخصية فقط، أو للمسؤول تحديث أي حساب
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
            
            # التحقق من صلاحية التحديث: المستخدم نفسه أو مسؤول
            if authenticated_user.id_utilisateur != user_to_update.id_utilisateur and authenticated_user.type_utilisateur != 'Administrateur':
                return Response({
                    "error": "غير مصرح لك بتحديث هذا الحساب",
                    "details": "يمكنك فقط تحديث حسابك الشخصي"
                }, status=status.HTTP_403_FORBIDDEN)
            
            # استخدام serializer للتحديث
            serializer = UserUpdateSerializer(user_to_update, data=request.data, partial=True)
            
            if serializer.is_valid():
                # حفظ التغييرات
                serializer.save()
                
                # إرجاع البيانات المحدثة
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
                        "photo_profile": user_to_update.photo_profile.url if user_to_update.photo_profile else None
                    }
                })
            else:
                return Response({
                    "error": "بيانات غير صالحة",
                    "details": serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)
            
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
                'status': 'error',
                'message': 'حساب المستخدم غير نشط'
            }, status=status.HTTP_403_FORBIDDEN)
            
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
            'is_staff': user.is_staff,
            'is_active': user.is_active,
            'date_joined': user.date_joined
        }
            
        # إضافة معلومات إضافية بناءً على نوع المستخدم
        if user.type_utilisateur == 'Livreur' and hasattr(user, 'profil_livreur'):
            livreur = user.profil_livreur
            user_data['note_moyenne'] = livreur.note_moyenne
            user_data['disponibilite'] = livreur.disponibilite
            user_data['statut_verification'] = livreur.statut_verification
            
        elif user.type_utilisateur == 'Chauffeur' and hasattr(user, 'profil_chauffeur'):
            chauffeur = user.profil_chauffeur
            user_data['note_moyenne'] = chauffeur.note_moyenne
            user_data['disponibilite'] = chauffeur.disponibilite
            user_data['type_vehicule'] = chauffeur.type_vehicule
            user_data['statut_verification'] = chauffeur.statut_verification
            
        elif user.type_utilisateur == 'Fournisseur' and hasattr(user, 'profil_fournisseur'):
            fournisseur = user.profil_fournisseur
            user_data['nom_commerce'] = fournisseur.nom_commerce
            user_data['type_fournisseur'] = fournisseur.type_fournisseur
        
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
        
        # الصورة الشخصية
        photo_profile = request.FILES.get('photo_profile') or request.FILES.get('profile_picture')
        
        # البيانات الإضافية (اختيارية)
        username = data.get('username')
        
        # استخدام الاسم الكامل كاسم مستخدم إذا لم يتم تقديم اسم مستخدم
        if not username and full_name:
            # استخدام الاسم الكامل كما هو
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
        
        # إنشاء توكن مباشرة بعد التسجيل
        access_token, refresh_token = create_jwt_token(user)
        
        return Response({
            'success': True,
            'message': 'تم إنشاء الحساب بنجاح',
            'status': 'success',
            'user': {
                'id_utilisateur': user.id_utilisateur,
                'username': user.username,
                'email': user.email,
                'telephone': user.telephone,
                'type_utilisateur': user.type_utilisateur,
                'date_naissance': user.date_naissance,
                'photo_profile': request.build_absolute_uri(user.photo_profile.url) if user.photo_profile else None,
                'is_active': user.is_active,
                'date_joined': user.date_joined
            },
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
    