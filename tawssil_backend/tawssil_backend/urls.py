from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from utilisateurs.serializers import MyTokenObtainPairView, MyTokenRefreshView
from utilisateurs.views import (
    protected_view, register_user, list_users, search_advanced, 
    update_user, delete_user, bulk_delete_users, login_view, login_user ,
    check_user_exists, send_otp_email, send_otp_sms, verify_otp,
    reset_password, reactivate_otp,
    register_otp_email, register_otp_sms, complete_registration,
    create_driver, list_drivers, pending_drivers_count,
    providers_stats,
    users_stats,
    update_driver_status,
    update_driver_verification_status,
    clients_table_stats,
    create_provider,
    update_provider,
    verify_provider,
    delete_provider,
    liste_administrateurs,
    create_admin,
    check_admin_exists,
    update_admin,
    delete_admin,
    validate_token,
    clients_and_drivers,
    list_all_otp_codes,
    get_user_location,
    update_user_location,
)
from commandes.views import (
    active_deliveries_count, 
    last_month_active_deliveries_count,
    livreur_commandes_count,
    chauffeur_voyages_count
)

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # مسارات المستخدمين
    path('api/register/', register_user, name='register'),
    path('api/login/', login_user, name='login'),
    path('api/login/', login_view, name='login'),
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
    path('api/create-driver/', create_driver, name='create_driver'),
    path('api/list-drivers/', list_drivers, name='list_drivers'),
    path('api/pending-drivers-count/', pending_drivers_count, name='pending_drivers_count'),
    path('api/commandes/active-deliveries-count/', active_deliveries_count, name='active_deliveries_count'),
    path('api/commandes/last-month-active-deliveries-count/', last_month_active_deliveries_count, name='last_month_active_deliveries_count'),
    path('api/providers-stats/', providers_stats, name='providers_stats'),
    path('api/users-stats/', users_stats, name='users_stats'),
    path('api/drivers/<int:driver_id>/update-status/', update_driver_status, name='update_driver_status'),
    path('api/drivers/<int:driver_id>/update-verification/', update_driver_verification_status, name='update_driver_verification_status'),
    path('api/clients-table-stats/', clients_table_stats, name='clients_table_stats'),
    path('api/create-provider/', create_provider, name='create_provider'),
    path('api/providers/<int:provider_id>/update/', update_provider, name='update_provider'),
    path('api/providers/<int:provider_id>/verify/', verify_provider, name='verify_provider'),
    path('api/providers/<int:provider_id>/delete/', delete_provider, name='delete_provider'),
    path('api/administrateurs/', liste_administrateurs, name='liste_administrateurs'),
    path('api/create-admin/', create_admin, name='create_admin'),
    path('api/check-admin-exists/', check_admin_exists, name='check_admin_exists'),
    path('api/administrateurs/<int:admin_id>/update/', update_admin, name='update_admin'),
    path('api/administrateurs/<int:admin_id>/delete/', delete_admin, name='delete_admin'),
    path('api/validate-token/', validate_token, name='validate_token'),
    path('api/utilisateurs/clients-drivers/', clients_and_drivers, name='clients_and_drivers'),
    path('api/otp-codes/', list_all_otp_codes, name='list_all_otp_codes'),
    
    # مسارات جديدة لعدد التوصيلات والرحلات
    path('api/commandes/livreur/<int:livreur_id>/count/', livreur_commandes_count, name='livreur_commandes_count'),
    path('api/commandes/voyages/chauffeur/<int:chauffeur_id>/count/', chauffeur_voyages_count, name='chauffeur_voyages_count'),
    path('api/users/<int:user_id>/location/', get_user_location, name='get_user_location'),
    path('api/users/<int:user_id>/update-location/', update_user_location, name='update_user_location'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
