from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from utilisateurs.serializers import MyTokenObtainPairView, MyTokenRefreshView
from utilisateurs.views import (
    protected_view, register_user, list_users, search_advanced, 
    update_user, delete_user, bulk_delete_users, login_user, 
    check_user_exists, send_otp_email, send_otp_sms, verify_otp,
    reset_password, reactivate_otp,
    register_otp_email, register_otp_sms, complete_registration
)

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # مسارات المستخدمين
    path('api/register/', register_user, name='register'),
    path('api/login/', login_user, name='login'),
    path('api/check-user-exists/', check_user_exists, name='check_user_exists'),
    path('api/protected/', protected_view, name='protected_view'),
    path('api/token/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', MyTokenRefreshView.as_view(), name='token_refresh'),
    path('api/list_users/', list_users, name='list_users'),
    path('api/search/', search_advanced, name='search_advanced'),
    path('api/users/<int:id_utilisateur>/update/', update_user, name='update_user'),
    path('api/users/<int:id_utilisateur>/delete/', delete_user, name='delete_user'),
    path('api/users/bulk-delete/', bulk_delete_users, name='bulk_delete_users'),
    
    # مسارات OTP وإعادة تعيين كلمة المرور
    path('api/send-otp-email/', send_otp_email, name='send_otp_email'),
    path('api/send-otp-sms/', send_otp_sms, name='send_otp_sms'),
    path('api/verify-otp/', verify_otp, name='verify_otp'),
    path('api/reset-password/', reset_password, name='reset_password'),
    path('api/reactivate-otp/', reactivate_otp, name='reactivate_otp'),
    path('api/complete-registration/', complete_registration, name='complete_registration'),
    
    # تضمين مسارات التطبيقات الأخرى
    path('api/commandes/', include('commandes.urls')),
    path('api/produits/', include('produits.urls')),
    path('api/evaluations/', include('evaluations.urls')),
    path('api/messaging/', include('messaging.urls')),
    path('api/paiements/', include('paiements.urls')),
    path('api/vehicules/', include('vehicules.urls')),
    
    # واجهات OTP الجديدة للمستخدمين الجدد في مرحلة التسجيل
    path('api/register-otp-email/', register_otp_email, name='register_otp_email'),
    path('api/register-otp-sms/', register_otp_sms, name='register_otp_sms'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
