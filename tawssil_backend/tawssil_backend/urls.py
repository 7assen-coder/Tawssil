from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from utilisateurs.serializers import MyTokenObtainPairView, MyTokenRefreshView
from utilisateurs.views import protected_view, register_user, list_users, search_advanced, update_user, delete_user, bulk_delete_users

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/register/', register_user, name='register'),
    path('api/protected/', protected_view, name='protected_view'),
    path('api/token/', MyTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', MyTokenRefreshView.as_view(), name='token_refresh'),
    path('api/list_users/', list_users, name='list_users'),
    path('api/search/', search_advanced, name='search_advanced'),
    path('api/users/<int:id_utilisateur>/update/', update_user, name='update_user'),
    path('api/users/<int:id_utilisateur>/delete/', delete_user, name='delete_user'),
    path('api/users/bulk-delete/', bulk_delete_users, name='bulk_delete_users'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
