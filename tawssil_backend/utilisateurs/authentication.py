from rest_framework import exceptions
from .models import Utilisateur
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.conf import settings

def custom_user_authentication_rule(user):
    """
    قاعدة مخصصة للتحقق من المستخدم في SimpleJWT
    """
    # إذا كان المستخدم هو رمز عددي (id_utilisateur)، نقوم بالبحث عن المستخدم المناسب
    if isinstance(user, int):
        try:
            user = Utilisateur.objects.get(id_utilisateur=user)
        except Utilisateur.DoesNotExist:
            raise exceptions.AuthenticationFailed('لا يوجد مستخدم نشط بهذا المعرف')
    
    # نتحقق من وجود المستخدم وأنه نشط
    if user is not None and user.is_active:
        return True
    return False

class CustomJWTAuthentication(JWTAuthentication):
    def get_user(self, validated_token):
        """
        تجاوز لطريقة الحصول على المستخدم للاستخدام مع نموذج Utilisateur
        """
        try:
            user_id = validated_token[settings.SIMPLE_JWT['USER_ID_CLAIM']]
        except KeyError:
            raise exceptions.AuthenticationFailed('التوكن لا يحتوي على معرف المستخدم')

        try:
            user = Utilisateur.objects.get(id_utilisateur=user_id)
        except Utilisateur.DoesNotExist:
            raise exceptions.AuthenticationFailed('لا يوجد مستخدم نشط بهذا المعرف')

        if not user.is_active:
            raise exceptions.AuthenticationFailed('هذا المستخدم غير نشط')

        return user 