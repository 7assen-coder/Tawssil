from django.shortcuts import render
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework.parsers import JSONParser, MultiPartParser
from django.db.models import Q
from .models import Utilisateur
from .serializers import UserRegistrationSerializer, UserListSerializer, UserUpdateSerializer, jwt_decode_handler, create_jwt_token
import jwt
from django.conf import settings
import datetime

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    try:
        # تحويل البيانات إلى قاموس إذا كانت في صيغة QueryDict
        data = request.data.dict() if hasattr(request.data, 'dict') else request.data
        
        # معالجة رفع الملفات إذا وجدت
        if request.FILES and 'photo_cart' in request.FILES:
            data['photo_cart'] = request.FILES['photo_cart']

        # التحقق من وجود جميع الحقول المطلوبة
        required_fields = ['nom', 'prenom', 'email', 'mot_de_passe', 'telephone', 'adresse', 'type_utilisateur']
        for field in required_fields:
            if field not in data:
                return Response({
                    'status': 'error',
                    'message': f'Field {field} is required'
                }, status=status.HTTP_400_BAD_REQUEST)

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
                    'nom': user.nom,
                    'prenom': user.prenom,
                    'email': user.email,
                    'telephone': user.telephone,
                    'adresse': user.adresse,
                    'type_utilisateur': user.type_utilisateur,
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
                "email": user.email,
                "nom": user.nom,
                "prenom": user.prenom,
                "type_utilisateur": user.type_utilisateur
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
            nom = request.GET.get('nom', '')
            prenom = request.GET.get('prenom', '')
            email = request.GET.get('email', '')
            telephone = request.GET.get('telephone', '')
            adresse = request.GET.get('adresse', '')
            date_joined = request.GET.get('date_joined', '')
            type_utilisateur = request.GET.get('type_utilisateur', '')
            
            # بناء استعلام بحث ديناميكي
            query = Q()
            
            if nom:
                query |= Q(nom__icontains=nom)
            
            if prenom:
                query |= Q(prenom__icontains=prenom)
            
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
                        "nom", "prenom", "email", "telephone", "adresse", "date_joined", "type_utilisateur"
                    ],
                    "example": "/api/search/?nom=محمد&email=example.com"
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
                    "nom": nom if nom else None,
                    "prenom": prenom if prenom else None,
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
    تحديث بيانات المستخدم - يمكن للمستخدم تعديل بياناته الشخصية فقط، أو للمسؤول تعديل بيانات أي مستخدم
    """
    try:
        # التحقق من وجود المستخدم المطلوب تحديث بياناته
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
            
            # التحقق من صلاحية التعديل: المستخدم نفسه أو مسؤول
            if authenticated_user.id_utilisateur != user_to_update.id_utilisateur and authenticated_user.type_utilisateur != 'Administrateur':
                return Response({
                    "error": "غير مصرح لك بتعديل بيانات هذا المستخدم",
                    "details": "يمكنك فقط تعديل بياناتك الشخصية"
                }, status=status.HTTP_403_FORBIDDEN)
            
            # تحويل البيانات إلى قاموس إذا كانت في صيغة QueryDict
            data = request.data.dict() if hasattr(request.data, 'dict') else request.data
            
            # معالجة رفع الملفات إذا وجدت
            if request.FILES and 'photo_cart' in request.FILES:
                data['photo_cart'] = request.FILES['photo_cart']
            
            # تعديل بعض الحقول إذا كان المستخدم ليس مسؤولاً
            if authenticated_user.type_utilisateur != 'Administrateur':
                # إذا حاول المستخدم العادي تغيير نوع المستخدم، نمنع ذلك
                if 'type_utilisateur' in data:
                    return Response({
                        "error": "لا يمكنك تغيير نوع المستخدم",
                        "details": "فقط المسؤول يمكنه تغيير نوع المستخدم"
                    }, status=status.HTTP_403_FORBIDDEN)
            
            # استخدام serializer للتحديث
            serializer = UserUpdateSerializer(user_to_update, data=data, partial=True)
            
            if serializer.is_valid():
                user = serializer.save()
                
                # إنشاء توكن جديد إذا كان المستخدم يقوم بتحديث بياناته الشخصية
                if authenticated_user.id_utilisateur == user_to_update.id_utilisateur:
                    access_token, refresh_token = create_jwt_token(user)
                    tokens = {
                        'access': access_token,
                        'refresh': refresh_token
                    }
                else:
                    tokens = None
                
                return Response({
                    "message": "تم تحديث البيانات بنجاح",
                    "updated_at": user.last_modified,
                    "user": {
                        "id_utilisateur": user.id_utilisateur,
                        "nom": user.nom,
                        "prenom": user.prenom,
                        "email": user.email,
                        "telephone": user.telephone,
                        "adresse": user.adresse,
                        "type_utilisateur": user.type_utilisateur,
                        "is_active": user.is_active,
                        "date_joined": user.date_joined,
                        "last_modified": user.last_modified
                    },
                    "tokens": tokens
                })
            
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
                "nom": user_to_delete.nom,
                "prenom": user_to_delete.prenom,
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
                
            nom = data.get('nom', '') if isinstance(data, dict) else ''
            prenom = data.get('prenom', '') if isinstance(data, dict) else ''
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
                if nom:
                    query |= Q(nom=nom)
                if prenom:
                    query |= Q(prenom=prenom)
                if email:
                    query |= Q(email=email)
                if telephone:
                    query |= Q(telephone=telephone)
                if adresse:
                    query |= Q(adresse=adresse)
                if type_utilisateur:
                    query |= Q(type_utilisateur=type_utilisateur)
            else:  # استخدام contains كافتراضي
                if nom:
                    query |= Q(nom__icontains=nom)
                if prenom:
                    query |= Q(prenom__icontains=prenom)
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
                    "nom": user.nom,
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
                    "nom": user.nom,
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
                            "nom": nom if nom else None,
                            "prenom": prenom if prenom else None,
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
                        "nom": nom if nom else None,
                        "prenom": prenom if prenom else None,
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
                        "nom": user.nom,
                        "prenom": user.prenom,
                        "email": user.email,
                        "type_utilisateur": user.type_utilisateur
                    })
                
                return Response({
                    "message": "وجدنا مستخدمين مطابقين للمعايير. يرجى التأكيد قبل الحذف",
                    "matching_users_count": users_to_delete.count(),
                    "matching_users": users_info,
                    "confirm_instructions": "لحذف هؤلاء المستخدمين، أضف 'confirmed': true إلى طلبك",
                    "filters_used": {
                        "nom": nom if nom else None,
                        "prenom": prenom if prenom else None,
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
                    "nom": user.nom,
                    "prenom": user.prenom,
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
                    "nom": nom if nom else None,
                    "prenom": prenom if prenom else None,
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
    