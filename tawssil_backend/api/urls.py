from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView

from .views import (
    UtilisateurViewSet, ClientViewSet, LivreurViewSet, ChauffeurViewSet, AdministrateurViewSet,
    ColisViewSet, VoyageViewSet, CommandeViewSet, PaiementViewSet, VehiculeViewSet,
    TrajetViewSet, NotificationViewSet
)

router = DefaultRouter()
router.register('utilisateurs', UtilisateurViewSet)
router.register('clients', ClientViewSet)
router.register('livreurs', LivreurViewSet)
router.register('chauffeurs', ChauffeurViewSet)
router.register('administrateurs', AdministrateurViewSet)
router.register('colis', ColisViewSet)
router.register('voyages', VoyageViewSet)
router.register('commandes', CommandeViewSet)
router.register('paiements', PaiementViewSet)
router.register('vehicules', VehiculeViewSet)
router.register('trajets', TrajetViewSet)
router.register('notifications', NotificationViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]
